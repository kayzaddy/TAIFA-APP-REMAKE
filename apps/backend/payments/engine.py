"""Transaction Engine — authoritative orchestrator for all money movements.

Flow: idempotency → validate → (rail) → journal posting → status → response.
Views never post to the ledger. Corrections are compensating journals only.
"""
from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass

from django.conf import settings
from django.db import transaction as db_transaction
from django.db.models import Sum

from . import journal, ledger
from .gateways.base import (
    PaymentAccepted,
    PaymentFailed,
    PaymentOperation,
    PaymentPending,
    PaymentRequest,
    PaymentResult,
)
from .gateways.factory import default_router
from .gateways.registry import PaymentRouter
from .models import (
    IdempotencyKey,
    IdempotencyKeyStatus,
    LedgerEntryKind,
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from .money import Currency, Money
from .state_machine import IllegalStateTransition, assert_transition


class IdempotencyConflict(Exception):
    """Same key replayed with a different payload."""


class InsufficientFunds(Exception):
    pass


class InvalidTransition(Exception):
    """Illegal lifecycle transition for a money transaction."""


class RefundError(Exception):
    """Refund cannot be applied (cap exceeded, wrong state, etc.)."""


@dataclass
class EngineResult:
    transaction: Transaction
    result: PaymentResult | None
    replayed: bool = False


def _hash(payload: dict) -> str:
    return hashlib.sha256(json.dumps(payload, sort_keys=True, default=str).encode()).hexdigest()


class TransactionEngine:
    def __init__(self, router: PaymentRouter | None = None):
        self.router = router or default_router()

    def user_wallet(self, owner: str, currency: Currency):
        return journal.user_wallet(owner, currency)

    def wallet_balance(self, owner: str, currency: Currency) -> Money:
        return ledger.balance_of(self.user_wallet(owner, currency))

    def _locked_wallet_balance(self, owner: str, currency: Currency) -> Money:
        account = self.user_wallet(owner, currency)
        type(account).objects.select_for_update().get(pk=account.pk)
        return ledger.balance_of(account)

    def _transition_to(self, txn: Transaction, target: str) -> None:
        try:
            assert_transition(txn.status, target)
        except IllegalStateTransition as exc:
            raise InvalidTransition(str(exc)) from exc
        txn.status = target

    # --- bootstrap ---
    @db_transaction.atomic
    def open_wallet(self, owner: str, initial: Money) -> Transaction:
        cur = initial.currency
        txn = Transaction.objects.create(
            owner=owner,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=initial.minor_units,
            currency=cur.code,
            counterparty="Opening balance",
            method_kind="wallet",
            idempotency_key=f"open-{owner}-{cur.code}",
        )
        entry = journal.post_opening(txn, owner, initial)
        Transaction.objects.filter(pk=txn.pk).update(ledger_entry=entry)
        txn.refresh_from_db()
        return txn

    # --- idempotency ---
    def _begin(self, key: str, scope: str, request_hash: str) -> tuple[IdempotencyKey, bool]:
        obj, created = IdempotencyKey.objects.get_or_create(
            key=key, defaults={"scope": scope, "request_hash": request_hash}
        )
        if not created and obj.request_hash != request_hash:
            raise IdempotencyConflict(key)
        return obj, created

    def _complete(self, key_obj: IdempotencyKey, txn: Transaction) -> None:
        key_obj.transaction = txn
        key_obj.status = IdempotencyKeyStatus.COMPLETED
        key_obj.response_body = {"transaction_id": str(txn.id), "status": txn.status}
        key_obj.save()

    def _owner_of(self, txn: Transaction) -> str:
        return txn.owner or "amani"

    # --- top-up ---
    def initiate_topup(
        self, *, owner: str, amount: Money, msisdn: str, operator: str = "mpesa",
        idempotency_key: str, note: str = "",
    ) -> EngineResult:
        request_hash = _hash({"op": "topup", "owner": owner, "amt": amount.minor_units,
                              "cur": amount.currency.code, "msisdn": msisdn})
        key_obj, created = self._begin(idempotency_key, "topup", request_hash)
        if not created and key_obj.transaction:
            return EngineResult(key_obj.transaction, None, replayed=True)

        txn = Transaction.objects.create(
            owner=owner,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.PROCESSING,
            direction=TransactionDirection.CREDIT,
            amount_minor=amount.minor_units,
            currency=amount.currency.code,
            counterparty=f"Top-up via {operator}",
            method_kind="mobile_money",
            method_ref=msisdn,
            operator=operator,
            idempotency_key=idempotency_key,
            note=note,
        )
        request = PaymentRequest(
            idempotency_key=idempotency_key, reference=str(txn.id), amount=amount,
            operation=PaymentOperation.CHARGE, method_kind="mobile_money", method_ref=msisdn,
            operator=operator, narrative=note or "TAIFA top-up",
        )
        gateway = self.router.resolve(request)
        result = gateway.charge(request)
        self._apply_initial(txn, result)
        self._complete(key_obj, txn)
        return EngineResult(txn, result)

    # --- transfer ---
    def initiate_transfer(
        self, *, owner: str, amount: Money, method_kind: str, method_ref: str, operator: str = "",
        counterparty: str, idempotency_key: str, note: str = "",
    ) -> EngineResult:
        request_hash = _hash({"op": "transfer", "owner": owner, "amt": amount.minor_units,
                              "cur": amount.currency.code, "ref": method_ref})
        key_obj, created = self._begin(idempotency_key, "transfer", request_hash)
        if not created and key_obj.transaction:
            return EngineResult(key_obj.transaction, None, replayed=True)

        fee = Money.zero(amount.currency)
        total = amount + fee

        with db_transaction.atomic():
            balance = self._locked_wallet_balance(owner, amount.currency)
            txn = Transaction.objects.create(
                owner=owner,
                type=TransactionType.SEND_MONEY,
                status=TransactionStatus.PROCESSING,
                direction=TransactionDirection.DEBIT,
                amount_minor=amount.minor_units,
                fee_minor=fee.minor_units,
                currency=amount.currency.code,
                counterparty=counterparty,
                method_kind=method_kind,
                method_ref=method_ref,
                operator=operator,
                idempotency_key=idempotency_key,
                note=note,
            )
            if total > balance:
                self._transition_to(txn, TransactionStatus.FAILED)
                txn.save(update_fields=["status"])
                self._complete(key_obj, txn)
                return EngineResult(txn, None)

            if method_kind == "wallet":
                self._settle(txn)
                self._complete(key_obj, txn)
                return EngineResult(txn, None)

        request = PaymentRequest(
            idempotency_key=idempotency_key, reference=str(txn.id), amount=amount,
            operation=PaymentOperation.PAYOUT, method_kind=method_kind, method_ref=method_ref,
            operator=operator, narrative=note,
        )
        gateway = self.router.resolve(request)
        result = gateway.payout(request)
        self._apply_initial(txn, result)
        self._complete(key_obj, txn)
        return EngineResult(txn, result)

    # --- withdrawals ---
    def initiate_withdrawal(
        self, *, owner: str, amount: Money, method_kind: str, method_ref: str,
        operator: str = "", counterparty: str = "", idempotency_key: str, note: str = "",
        auto_approve: bool | None = None,
    ) -> EngineResult:
        request_hash = _hash({
            "op": "withdrawal", "owner": owner, "amt": amount.minor_units,
            "cur": amount.currency.code, "ref": method_ref, "kind": method_kind,
        })
        key_obj, created = self._begin(idempotency_key, "withdrawal", request_hash)
        if not created and key_obj.transaction:
            return EngineResult(key_obj.transaction, None, replayed=True)

        if auto_approve is None:
            auto_approve = bool(getattr(settings, "WITHDRAWAL_AUTO_APPROVE", False))

        txn = Transaction.objects.create(
            owner=owner,
            type=TransactionType.WITHDRAWAL,
            status=TransactionStatus.PENDING,
            direction=TransactionDirection.DEBIT,
            amount_minor=amount.minor_units,
            currency=amount.currency.code,
            counterparty=counterparty or method_ref or "Withdrawal",
            method_kind=method_kind,
            method_ref=method_ref,
            operator=operator,
            idempotency_key=idempotency_key,
            note=note,
        )
        self._complete(key_obj, txn)

        if auto_approve:
            self.approve_withdrawal(txn)
            txn.refresh_from_db()
            if txn.status == TransactionStatus.APPROVED:
                self.process_withdrawal(txn)
                txn.refresh_from_db()
        return EngineResult(txn, None)

    @db_transaction.atomic
    def approve_withdrawal(self, txn: Transaction) -> Transaction:
        txn = Transaction.objects.select_for_update().get(pk=txn.pk)
        if txn.type != TransactionType.WITHDRAWAL:
            raise InvalidTransition("Not a withdrawal")
        if txn.status == TransactionStatus.APPROVED:
            return txn
        if txn.status != TransactionStatus.PENDING:
            raise InvalidTransition(f"Cannot approve from {txn.status}")

        owner = self._owner_of(txn)
        amount = txn.amount
        balance = self._locked_wallet_balance(owner, amount.currency)
        if amount > balance:
            self._transition_to(txn, TransactionStatus.FAILED)
            txn.save(update_fields=["status", "updated_at"])
            return txn

        if journal.entry_of_kind(txn, LedgerEntryKind.HOLD) is None:
            journal.post_withdrawal_hold(txn, owner, amount)
        self._transition_to(txn, TransactionStatus.APPROVED)
        txn.save(update_fields=["status", "updated_at"])
        return txn

    @db_transaction.atomic
    def reject_withdrawal(self, txn: Transaction, reason: str = "") -> Transaction:
        txn = Transaction.objects.select_for_update().get(pk=txn.pk)
        if txn.type != TransactionType.WITHDRAWAL:
            raise InvalidTransition("Not a withdrawal")
        if txn.status == TransactionStatus.REJECTED:
            return txn
        if txn.status == TransactionStatus.PENDING:
            self._transition_to(txn, TransactionStatus.REJECTED)
            if reason:
                txn.note = (txn.note + f" | rejected: {reason}").strip(" |")
            txn.save(update_fields=["status", "note", "updated_at"])
            return txn
        if txn.status == TransactionStatus.APPROVED:
            owner = self._owner_of(txn)
            if journal.entry_of_kind(txn, LedgerEntryKind.RELEASE) is None:
                journal.post_withdrawal_release(txn, owner, txn.amount, reason or "rejected")
            self._transition_to(txn, TransactionStatus.REJECTED)
            txn.save(update_fields=["status", "updated_at"])
            return txn
        raise InvalidTransition(f"Cannot reject from {txn.status}")

    def process_withdrawal(self, txn: Transaction) -> EngineResult:
        with db_transaction.atomic():
            txn = Transaction.objects.select_for_update().get(pk=txn.pk)
            if txn.type != TransactionType.WITHDRAWAL:
                raise InvalidTransition("Not a withdrawal")
            if txn.status == TransactionStatus.SUCCEEDED:
                return EngineResult(txn, None, replayed=True)
            if txn.status != TransactionStatus.APPROVED:
                raise InvalidTransition(f"Cannot process from {txn.status}")
            self._transition_to(txn, TransactionStatus.PROCESSING)
            txn.save(update_fields=["status", "updated_at"])

        request = PaymentRequest(
            idempotency_key=f"wd-{txn.idempotency_key}",
            reference=str(txn.id),
            amount=txn.amount,
            operation=PaymentOperation.PAYOUT,
            method_kind=txn.method_kind,
            method_ref=txn.method_ref,
            operator=txn.operator,
            narrative=txn.note or "TAIFA withdrawal",
        )
        gateway = self.router.resolve(request)
        result = gateway.payout(request)
        self._apply_withdrawal_rail(txn, result)
        txn.refresh_from_db()
        return EngineResult(txn, result)

    def _apply_withdrawal_rail(self, txn: Transaction, result: PaymentResult) -> None:
        if isinstance(result, PaymentAccepted):
            txn.provider = result.provider.name
            txn.provider_ref = result.provider_ref
            txn.save(update_fields=["provider", "provider_ref"])
            self._settle_withdrawal(txn)
        elif isinstance(result, PaymentPending):
            txn.provider = result.provider.name
            txn.provider_ref = result.provider_ref
            self._transition_to(txn, TransactionStatus.PROCESSING)
            txn.save(update_fields=["provider", "provider_ref", "status"])
        elif isinstance(result, PaymentFailed):
            txn.provider = result.provider.name if result.provider else ""
            txn.provider_ref = result.provider_ref or ""
            txn.save(update_fields=["provider", "provider_ref"])
            self._fail_withdrawal(txn, result.message)

    @db_transaction.atomic
    def _settle_withdrawal(self, txn: Transaction) -> None:
        locked = Transaction.objects.select_for_update().get(pk=txn.pk)
        if locked.ledger_entry_id is not None or locked.status == TransactionStatus.SUCCEEDED:
            txn.refresh_from_db()
            return
        self._transition_to(locked, TransactionStatus.SUCCEEDED)
        owner = self._owner_of(locked)
        if journal.entry_of_kind(locked, LedgerEntryKind.SETTLE) is None:
            entry = journal.post_withdrawal_settle(locked, owner, locked.amount)
        else:
            entry = journal.entry_of_kind(locked, LedgerEntryKind.SETTLE)
        Transaction.objects.filter(pk=locked.pk).update(
            ledger_entry=entry, status=TransactionStatus.SUCCEEDED
        )
        txn.refresh_from_db()

    @db_transaction.atomic
    def _fail_withdrawal(self, txn: Transaction, reason: str = "") -> None:
        locked = Transaction.objects.select_for_update().get(pk=txn.pk)
        if locked.status in {TransactionStatus.FAILED, TransactionStatus.SUCCEEDED, TransactionStatus.REVERSED}:
            txn.refresh_from_db()
            return
        owner = self._owner_of(locked)
        if journal.entry_of_kind(locked, LedgerEntryKind.HOLD) and journal.entry_of_kind(locked, LedgerEntryKind.RELEASE) is None:
            if journal.entry_of_kind(locked, LedgerEntryKind.SETTLE) is None:
                journal.post_withdrawal_release(locked, owner, locked.amount, reason or "failed")
        self._transition_to(locked, TransactionStatus.FAILED)
        locked.save(update_fields=["status", "updated_at"])
        txn.refresh_from_db()

    # --- refunds ---
    def initiate_refund(
        self, *, owner: str, original: Transaction, amount: Money,
        idempotency_key: str, note: str = "",
    ) -> EngineResult:
        request_hash = _hash({
            "op": "refund", "owner": owner, "orig": str(original.id),
            "amt": amount.minor_units, "cur": amount.currency.code,
        })
        key_obj, created = self._begin(idempotency_key, "refund", request_hash)
        if not created and key_obj.transaction:
            return EngineResult(key_obj.transaction, None, replayed=True)

        with db_transaction.atomic():
            original = Transaction.objects.select_for_update().get(pk=original.pk)
            if original.owner != owner:
                raise RefundError("Original transaction is not owned by this principal")
            if original.status != TransactionStatus.SUCCEEDED:
                raise RefundError("Only succeeded transactions can be refunded")
            if original.type in {TransactionType.REFUND, TransactionType.REVERSAL}:
                raise RefundError("Cannot refund a refund/reversal")
            if original.currency != amount.currency.code:
                raise RefundError("Currency mismatch")
            if amount.minor_units <= 0:
                raise RefundError("Refund amount must be positive")

            already = (
                Transaction.objects.filter(
                    parent=original,
                    type=TransactionType.REFUND,
                    status=TransactionStatus.SUCCEEDED,
                ).aggregate(s=Sum("amount_minor"))["s"]
                or 0
            )
            if already + amount.minor_units > original.amount_minor:
                raise RefundError(
                    f"Refund would exceed original amount "
                    f"(already={already}, requested={amount.minor_units}, "
                    f"original={original.amount_minor})"
                )

            reverse_fee = Money.zero(amount.currency)
            if (
                already == 0
                and amount.minor_units == original.amount_minor
                and original.fee_minor > 0
            ):
                reverse_fee = original.fee

            if original.type == TransactionType.TOP_UP:
                bal = self._locked_wallet_balance(owner, amount.currency)
                if amount > bal:
                    raise InsufficientFunds("Insufficient wallet balance to refund top-up")

            txn = Transaction.objects.create(
                owner=owner,
                type=TransactionType.REFUND,
                status=TransactionStatus.PROCESSING,
                direction=TransactionDirection.CREDIT
                if original.type != TransactionType.TOP_UP
                else TransactionDirection.DEBIT,
                amount_minor=amount.minor_units,
                fee_minor=reverse_fee.minor_units,
                currency=amount.currency.code,
                counterparty=f"Refund of {original.id}",
                method_kind=original.method_kind,
                method_ref=original.method_ref,
                operator=original.operator,
                idempotency_key=idempotency_key,
                note=note,
                parent=original,
            )
            entry = journal.post_refund_for_original(
                txn, original, owner, amount, reverse_fee=reverse_fee
            )
            Transaction.objects.filter(pk=txn.pk).update(
                ledger_entry=entry, status=TransactionStatus.SUCCEEDED
            )
            txn.refresh_from_db()
            self._complete(key_obj, txn)
            return EngineResult(txn, None)

    # --- reversals ---
    def reverse_transaction(
        self, *, owner: str, original: Transaction, idempotency_key: str, note: str = ""
    ) -> EngineResult:
        request_hash = _hash({"op": "reversal", "owner": owner, "orig": str(original.id)})
        key_obj, created = self._begin(idempotency_key, "reversal", request_hash)
        if not created and key_obj.transaction:
            return EngineResult(key_obj.transaction, None, replayed=True)

        with db_transaction.atomic():
            original = Transaction.objects.select_for_update().get(pk=original.pk)
            if original.owner != owner:
                raise InvalidTransition("Not owned by principal")
            if original.status == TransactionStatus.REVERSED:
                raise InvalidTransition("Already reversed")
            if original.status != TransactionStatus.SUCCEEDED:
                raise InvalidTransition("Only succeeded transactions can be reversed")
            if original.ledger_entry_id is None:
                raise InvalidTransition("No ledger entry to reverse")
            if original.type in {TransactionType.REFUND, TransactionType.REVERSAL}:
                raise InvalidTransition("Cannot reverse a refund/reversal via this path")

            target = original.ledger_entry
            entries = list(original.ledger_entries.order_by("-created_at"))
            if not entries and target is not None:
                entries = [target]

            txn = Transaction.objects.create(
                owner=owner,
                type=TransactionType.REVERSAL,
                status=TransactionStatus.PROCESSING,
                direction=TransactionDirection.CREDIT
                if original.direction == TransactionDirection.DEBIT
                else TransactionDirection.DEBIT,
                amount_minor=original.amount_minor,
                fee_minor=original.fee_minor,
                currency=original.currency,
                counterparty=f"Reversal of {original.id}",
                method_kind=original.method_kind,
                method_ref=original.method_ref,
                operator=original.operator,
                idempotency_key=idempotency_key,
                note=note,
                parent=original,
            )
            last_entry = None
            for entry in entries:
                last_entry = journal.post_reversal(
                    txn, entry, f"Reversal of entry {entry.id} ({entry.kind})"
                )
            Transaction.objects.filter(pk=txn.pk).update(
                ledger_entry=last_entry, status=TransactionStatus.SUCCEEDED
            )
            self._transition_to(original, TransactionStatus.REVERSED)
            Transaction.objects.filter(pk=original.pk).update(status=TransactionStatus.REVERSED)
            txn.refresh_from_db()
            self._complete(key_obj, txn)
            return EngineResult(txn, None)

    # --- result application (top-up / transfer) ---
    def _apply_initial(self, txn: Transaction, result: PaymentResult) -> None:
        if isinstance(result, PaymentAccepted):
            txn.provider = result.provider.name
            txn.provider_ref = result.provider_ref
            txn.save(update_fields=["provider", "provider_ref"])
            self._settle(txn)
        elif isinstance(result, PaymentPending):
            txn.provider = result.provider.name
            txn.provider_ref = result.provider_ref
            self._transition_to(txn, TransactionStatus.PROCESSING)
            txn.save(update_fields=["provider", "provider_ref", "status"])
        elif isinstance(result, PaymentFailed):
            txn.provider = result.provider.name if result.provider else ""
            txn.provider_ref = result.provider_ref or ""
            self._transition_to(txn, TransactionStatus.FAILED)
            txn.save(update_fields=["provider", "provider_ref", "status"])

    @db_transaction.atomic
    def _settle(self, txn: Transaction) -> None:
        # Lock a fresh row; always refresh the caller's instance so callers do not
        # observe a stale PROCESSING status after a successful settle.
        locked = Transaction.objects.select_for_update().get(pk=txn.pk)
        if locked.ledger_entry_id is not None:
            txn.refresh_from_db()
            return
        if locked.type == TransactionType.WITHDRAWAL:
            self._settle_withdrawal(txn)
            return

        owner = self._owner_of(locked)
        self._transition_to(locked, TransactionStatus.SUCCEEDED)

        if locked.type == TransactionType.TOP_UP:
            entry = journal.post_topup_settle(
                locked, owner, locked.amount, f"Top-up via {locked.provider or locked.operator}"
            )
        else:
            entry = journal.post_transfer_settle(
                locked, owner, locked.amount, locked.fee, f"Send to {locked.counterparty}"
            )

        Transaction.objects.filter(pk=locked.pk).update(
            ledger_entry=entry, status=TransactionStatus.SUCCEEDED
        )
        txn.refresh_from_db()

    def settle_success(self, txn: Transaction) -> None:
        if txn.status in {TransactionStatus.SUCCEEDED}:
            return
        if txn.type == TransactionType.WITHDRAWAL:
            self._settle_withdrawal(txn)
            return
        self._settle(txn)

    def settle_failure(self, txn: Transaction, reason: str = "") -> None:
        if txn.status in {TransactionStatus.SUCCEEDED, TransactionStatus.FAILED, TransactionStatus.REVERSED}:
            return
        if txn.type == TransactionType.WITHDRAWAL:
            self._fail_withdrawal(txn, reason)
            return
        self._transition_to(txn, TransactionStatus.FAILED)
        Transaction.objects.filter(pk=txn.pk).update(status=TransactionStatus.FAILED)
        txn.refresh_from_db()


def default_engine() -> TransactionEngine:
    return TransactionEngine()
