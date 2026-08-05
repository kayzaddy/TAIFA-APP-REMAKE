"""Platform orchestrator — coordinates enterprise money flows via payment journal.

Does not implement accounting recipes. Does not bypass the ledger.
"""
from __future__ import annotations

from dataclasses import dataclass

from django.db import transaction
from django.utils import timezone

from payments import audit, journal, ledger
from payments.models import (
    DomainEventType,
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money

from . import approval, event_bus, projections, rules
from .models import (
    ChargebackCase,
    ChargebackEvent,
    ChargebackStatus,
    Merchant,
    MerchantSettlement,
    MerchantSettlementStatus,
    MerchantStatus,
    TreasuryTransfer,
    TreasuryTransferStatus,
)


@dataclass
class PlatformContext:
    actor: str
    ip: str | None = None


class PlatformError(Exception):
    pass


class PlatformOrchestrator:
    def capture_merchant_payment(
        self,
        *,
        ctx: PlatformContext,
        merchant: Merchant,
        payer_owner: str,
        amount: Money,
        idempotency_key: str,
        note: str = "",
    ) -> Transaction:
        if merchant.status != MerchantStatus.ACTIVE:
            raise PlatformError("merchant not active")
        existing = Transaction.objects.filter(idempotency_key=idempotency_key).first()
        if existing:
            return existing

        comps = rules.fee_components(
            amount_minor=amount.minor_units,
            merchant_fee_bps=merchant.fee_bps,
            merchant_tax_bps=merchant.tax_bps,
            merchant_commission_bps=merchant.commission_bps,
            sector=merchant.sector,
        )
        fee = Money(comps["fee_minor"], amount.currency)
        tax = Money(comps["tax_minor"], amount.currency)
        commission = Money(comps["commission_minor"], amount.currency)
        total = amount + fee + tax + commission

        with transaction.atomic():
            bal = ledger.balance_of(journal.user_wallet(payer_owner, amount.currency))
            if total > bal:
                raise PlatformError("insufficient funds")
            txn = Transaction.objects.create(
                owner=payer_owner,
                type=TransactionType.MERCHANT_PAYMENT,
                status=TransactionStatus.SUCCEEDED,
                direction=TransactionDirection.DEBIT,
                amount_minor=amount.minor_units,
                fee_minor=fee.minor_units,
                currency=amount.currency.code,
                counterparty=merchant.code,
                method_kind="wallet",
                idempotency_key=idempotency_key,
                note=note or f"Pay {merchant.trading_name or merchant.legal_name}",
            )
            entry = journal.post_merchant_capture(
                txn,
                payer_owner=payer_owner,
                merchant_id=str(merchant.id),
                amount=amount,
                fee=fee,
                tax=tax,
                commission=commission,
            )
            Transaction.objects.filter(pk=txn.pk).update(ledger_entry=entry)
            txn.refresh_from_db()
            event_bus.publish(
                DomainEventType.MERCHANT_CAPTURED,
                aggregate_type="merchant",
                aggregate_id=str(merchant.id),
                transaction=txn,
                owner=payer_owner,
                payload={
                    "amount_minor": amount.minor_units,
                    "fee_minor": fee.minor_units,
                    "tax_minor": tax.minor_units,
                    "commission_minor": commission.minor_units,
                    "rules": comps["rules"],
                },
            )
            if not fee.is_zero:
                event_bus.publish(
                    DomainEventType.FEE_COLLECTED,
                    aggregate_type="merchant",
                    aggregate_id=str(merchant.id),
                    transaction=txn,
                    payload={"fee_minor": fee.minor_units},
                )
            if not commission.is_zero:
                event_bus.publish(
                    DomainEventType.COMMISSION_CALCULATED,
                    aggregate_type="merchant",
                    aggregate_id=str(merchant.id),
                    transaction=txn,
                    payload={"commission_minor": commission.minor_units},
                )
            if not tax.is_zero:
                event_bus.publish(
                    DomainEventType.TAX_POSTED,
                    aggregate_type="merchant",
                    aggregate_id=str(merchant.id),
                    transaction=txn,
                    payload={"tax_minor": tax.minor_units},
                )
            audit.record(
                actor=ctx.actor,
                action="merchant.capture",
                resource_type="transaction",
                resource_id=str(txn.id),
                ip=ctx.ip,
                after={"merchant": merchant.code, "amount_minor": amount.minor_units},
            )
        projections.refresh_merchant(merchant)
        projections.refresh_finance(amount.currency.code)
        return txn

    def create_settlement(
        self,
        *,
        ctx: PlatformContext,
        merchant: Merchant,
        amount: Money,
        period_start,
        period_end,
        idempotency_key: str,
        mode: str | None = None,
        require_approval_above_minor: int = 50_000_000,
    ) -> MerchantSettlement:
        existing = MerchantSettlement.objects.filter(idempotency_key=idempotency_key).first()
        if existing:
            return existing
        payable = ledger.balance_of(journal.merchant_payable(str(merchant.id), amount.currency))
        # merchant_payable is credit-normal; balance_of returns credit-positive for liabilities
        if amount.minor_units <= 0:
            raise PlatformError("invalid amount")
        if amount > payable and payable.minor_units >= 0:
            # For credit-normal accounts, available payable is the credit balance
            pass
        settlement = MerchantSettlement.objects.create(
            merchant=merchant,
            status=MerchantSettlementStatus.DRAFT,
            mode=mode or merchant.settlement_mode,
            currency=amount.currency.code,
            amount_minor=amount.minor_units,
            fee_minor=0,
            net_minor=amount.minor_units,
            period_start=period_start,
            period_end=period_end,
            idempotency_key=idempotency_key,
        )
        event_bus.publish(
            DomainEventType.SETTLEMENT_CREATED,
            aggregate_type="merchant_settlement",
            aggregate_id=str(settlement.id),
            owner=str(merchant.id),
            payload={"amount_minor": amount.minor_units, "mode": settlement.mode},
        )
        try:
            approval.request_approval(
                action="settlement.execute",
                resource_type="merchant_settlement",
                resource_id=str(settlement.id),
                maker=ctx.actor,
                amount_minor=amount.minor_units,
                threshold_minor=require_approval_above_minor,
                payload={"merchant": merchant.code},
            )
            settlement.status = MerchantSettlementStatus.PENDING_APPROVAL
            settlement.save(update_fields=["status", "updated_at"])
        except approval.ApprovalError:
            # below threshold — ready to execute
            settlement.status = MerchantSettlementStatus.APPROVED
            settlement.save(update_fields=["status", "updated_at"])
        audit.record(
            actor=ctx.actor,
            action="settlement.create",
            resource_type="merchant_settlement",
            resource_id=str(settlement.id),
            ip=ctx.ip,
        )
        return settlement

    def execute_settlement(self, *, ctx: PlatformContext, settlement: MerchantSettlement) -> MerchantSettlement:
        if settlement.status not in {
            MerchantSettlementStatus.APPROVED,
            MerchantSettlementStatus.FAILED,
        }:
            raise PlatformError(f"cannot execute from {settlement.status}")
        amount = Money(settlement.net_minor, Currency.from_code(settlement.currency))
        with transaction.atomic():
            settlement = MerchantSettlement.objects.select_for_update().get(pk=settlement.pk)
            settlement.status = MerchantSettlementStatus.PROCESSING
            settlement.attempt += 1
            settlement.save(update_fields=["status", "attempt", "updated_at"])
            txn = Transaction.objects.create(
                owner=str(settlement.merchant_id),
                type=TransactionType.MERCHANT_SETTLEMENT,
                status=TransactionStatus.SUCCEEDED,
                direction=TransactionDirection.DEBIT,
                amount_minor=amount.minor_units,
                currency=amount.currency.code,
                counterparty=settlement.merchant.bank_account_ref or settlement.merchant.code,
                method_kind="bank",
                idempotency_key=f"ms-{settlement.idempotency_key}-{settlement.attempt}",
                note=f"Settlement {settlement.id}",
            )
            entry = journal.post_merchant_settlement_payout(
                txn,
                merchant_id=str(settlement.merchant_id),
                amount=amount,
                bank_code=settlement.merchant.bank_code or "primary",
            )
            Transaction.objects.filter(pk=txn.pk).update(ledger_entry=entry)
            settlement.transaction = txn
            settlement.status = MerchantSettlementStatus.COMPLETED
            settlement.completed_at = timezone.now()
            settlement.statement_ref = f"STMT-{settlement.id.hex[:12].upper()}"
            settlement.save()
            event_bus.publish(
                DomainEventType.SETTLEMENT_COMPLETED,
                aggregate_type="merchant_settlement",
                aggregate_id=str(settlement.id),
                transaction=txn,
                payload={"amount_minor": amount.minor_units},
            )
            event_bus.publish(
                DomainEventType.MERCHANT_PAID,
                aggregate_type="merchant",
                aggregate_id=str(settlement.merchant_id),
                transaction=txn,
                payload={"settlement_id": str(settlement.id)},
            )
            audit.record(
                actor=ctx.actor,
                action="settlement.execute",
                resource_type="merchant_settlement",
                resource_id=str(settlement.id),
                ip=ctx.ip,
            )
        projections.refresh_merchant(settlement.merchant)
        projections.refresh_executive(settlement.currency)
        return settlement

    def cancel_settlement(self, *, ctx: PlatformContext, settlement: MerchantSettlement) -> MerchantSettlement:
        if settlement.status in {
            MerchantSettlementStatus.COMPLETED,
            MerchantSettlementStatus.CANCELLED,
        }:
            raise PlatformError("cannot cancel")
        settlement.status = MerchantSettlementStatus.CANCELLED
        settlement.save(update_fields=["status", "updated_at"])
        event_bus.publish(
            DomainEventType.SETTLEMENT_CANCELLED,
            aggregate_type="merchant_settlement",
            aggregate_id=str(settlement.id),
            payload={},
        )
        audit.record(
            actor=ctx.actor,
            action="settlement.cancel",
            resource_type="merchant_settlement",
            resource_id=str(settlement.id),
            ip=ctx.ip,
        )
        return settlement

    def split_settlement(
        self,
        *,
        ctx: PlatformContext,
        settlement: MerchantSettlement,
        parts: list[int],
    ) -> list[MerchantSettlement]:
        if sum(parts) != settlement.net_minor:
            raise PlatformError("parts must sum to net")
        if settlement.status not in {MerchantSettlementStatus.DRAFT, MerchantSettlementStatus.APPROVED}:
            raise PlatformError("cannot split")
        created = []
        for i, minor in enumerate(parts):
            child = MerchantSettlement.objects.create(
                merchant=settlement.merchant,
                status=MerchantSettlementStatus.APPROVED,
                mode=settlement.mode,
                currency=settlement.currency,
                amount_minor=minor,
                fee_minor=0,
                net_minor=minor,
                period_start=settlement.period_start,
                period_end=settlement.period_end,
                idempotency_key=f"{settlement.idempotency_key}-split-{i}",
                parent=settlement,
            )
            created.append(child)
        settlement.status = MerchantSettlementStatus.PARTIAL
        settlement.save(update_fields=["status", "updated_at"])
        audit.record(
            actor=ctx.actor,
            action="settlement.split",
            resource_type="merchant_settlement",
            resource_id=str(settlement.id),
            ip=ctx.ip,
            metadata={"parts": parts},
        )
        return created

    def open_chargeback(
        self,
        *,
        ctx: PlatformContext,
        merchant: Merchant,
        original: Transaction,
        amount: Money,
        idempotency_key: str,
        reason_code: str = "",
    ) -> ChargebackCase:
        existing = ChargebackCase.objects.filter(idempotency_key=idempotency_key).first()
        if existing:
            return existing
        with transaction.atomic():
            case = ChargebackCase.objects.create(
                merchant=merchant,
                original_transaction=original,
                amount_minor=amount.minor_units,
                currency=amount.currency.code,
                reason_code=reason_code,
                idempotency_key=idempotency_key,
                status=ChargebackStatus.OPENED,
            )
            txn = Transaction.objects.create(
                owner=str(merchant.id),
                type=TransactionType.CHARGEBACK,
                status=TransactionStatus.SUCCEEDED,
                direction=TransactionDirection.DEBIT,
                amount_minor=amount.minor_units,
                currency=amount.currency.code,
                counterparty=f"CB-{original.id}",
                method_kind="card",
                idempotency_key=f"cb-open-{idempotency_key}",
                parent=original,
                note=f"Chargeback open {reason_code}",
            )
            entry = journal.post_chargeback_open(txn, merchant_id=str(merchant.id), amount=amount)
            Transaction.objects.filter(pk=txn.pk).update(ledger_entry=entry)
            case.open_transaction = txn
            case.save(update_fields=["open_transaction"])
            ChargebackEvent.objects.create(
                case=case, from_status="", to_status=ChargebackStatus.OPENED, actor=ctx.actor
            )
            event_bus.publish(
                DomainEventType.CHARGEBACK_OPENED,
                aggregate_type="chargeback",
                aggregate_id=str(case.id),
                transaction=txn,
                payload={"amount_minor": amount.minor_units, "reason": reason_code},
            )
        projections.refresh_merchant(merchant)
        return case

    def transition_chargeback(
        self,
        *,
        ctx: PlatformContext,
        case: ChargebackCase,
        to_status: str,
        note: str = "",
        evidence: dict | None = None,
    ) -> ChargebackCase:
        allowed = {
            ChargebackStatus.OPENED: {
                ChargebackStatus.EVIDENCE_REQUESTED,
                ChargebackStatus.REPRESENTMENT,
                ChargebackStatus.WON,
                ChargebackStatus.LOST,
            },
            ChargebackStatus.EVIDENCE_REQUESTED: {
                ChargebackStatus.EVIDENCE_SUBMITTED,
                ChargebackStatus.LOST,
            },
            ChargebackStatus.EVIDENCE_SUBMITTED: {
                ChargebackStatus.REPRESENTMENT,
                ChargebackStatus.WON,
                ChargebackStatus.LOST,
            },
            ChargebackStatus.REPRESENTMENT: {
                ChargebackStatus.WON,
                ChargebackStatus.LOST,
            },
            ChargebackStatus.LOST: {ChargebackStatus.REVERSED},
        }
        if to_status not in allowed.get(case.status, set()):
            raise PlatformError(f"illegal chargeback {case.status} → {to_status}")
        amount = Money(case.amount_minor, Currency.from_code(case.currency))
        prev = case.status
        with transaction.atomic():
            case = ChargebackCase.objects.select_for_update().get(pk=case.pk)
            if evidence:
                case.evidence = {**(case.evidence or {}), **evidence}
            resolve_txn = None
            if to_status == ChargebackStatus.WON:
                resolve_txn = Transaction.objects.create(
                    owner=str(case.merchant_id),
                    type=TransactionType.CHARGEBACK,
                    status=TransactionStatus.SUCCEEDED,
                    direction=TransactionDirection.CREDIT,
                    amount_minor=amount.minor_units,
                    currency=amount.currency.code,
                    counterparty="chargeback-won",
                    method_kind="card",
                    idempotency_key=f"cb-won-{case.idempotency_key}",
                    parent=case.original_transaction,
                )
                entry = journal.post_chargeback_won(
                    resolve_txn, amount=amount, merchant_id=str(case.merchant_id)
                )
                Transaction.objects.filter(pk=resolve_txn.pk).update(ledger_entry=entry)
                case.resolve_transaction = resolve_txn
                case.resolved_at = timezone.now()
                event_type = DomainEventType.CHARGEBACK_WON
            elif to_status == ChargebackStatus.LOST:
                resolve_txn = Transaction.objects.create(
                    owner=str(case.merchant_id),
                    type=TransactionType.CHARGEBACK,
                    status=TransactionStatus.SUCCEEDED,
                    direction=TransactionDirection.DEBIT,
                    amount_minor=amount.minor_units,
                    currency=amount.currency.code,
                    counterparty="chargeback-lost",
                    method_kind="card",
                    idempotency_key=f"cb-lost-{case.idempotency_key}",
                    parent=case.original_transaction,
                )
                entry = journal.post_chargeback_lost(resolve_txn, amount=amount)
                Transaction.objects.filter(pk=resolve_txn.pk).update(ledger_entry=entry)
                case.resolve_transaction = resolve_txn
                case.resolved_at = timezone.now()
                event_type = DomainEventType.CHARGEBACK_LOST
            elif to_status == ChargebackStatus.REVERSED:
                # Compensating: reopen reserve from settlement is complex; use won path semantics
                event_type = DomainEventType.CHARGEBACK_REVERSED
            elif to_status == ChargebackStatus.EVIDENCE_REQUESTED:
                event_type = DomainEventType.CHARGEBACK_EVIDENCE_REQUESTED
            elif to_status == ChargebackStatus.EVIDENCE_SUBMITTED:
                event_type = DomainEventType.CHARGEBACK_EVIDENCE_SUBMITTED
            else:
                event_type = DomainEventType.CHARGEBACK_REPRESENTMENT
            case.status = to_status
            case.save()
            ChargebackEvent.objects.create(
                case=case, from_status=prev, to_status=to_status, actor=ctx.actor, note=note
            )
            event_bus.publish(
                event_type,
                aggregate_type="chargeback",
                aggregate_id=str(case.id),
                transaction=resolve_txn,
                payload={"from": prev, "to": to_status},
            )
        projections.refresh_merchant(case.merchant)
        return case

    def treasury_transfer(
        self,
        *,
        ctx: PlatformContext,
        transfer: TreasuryTransfer,
        require_approval_above_minor: int = 100_000_000,
    ) -> TreasuryTransfer:
        if transfer.status == TreasuryTransferStatus.COMPLETED:
            return transfer
        amount = Money(transfer.amount_minor, Currency.from_code(transfer.currency))
        try:
            approval.request_approval(
                action="treasury.transfer",
                resource_type="treasury_transfer",
                resource_id=str(transfer.id),
                maker=ctx.actor,
                amount_minor=amount.minor_units,
                threshold_minor=require_approval_above_minor,
            )
            transfer.status = TreasuryTransferStatus.PENDING_APPROVAL
            transfer.save(update_fields=["status"])
            return transfer
        except approval.ApprovalError:
            pass
        return self._execute_treasury_transfer(ctx=ctx, transfer=transfer)

    def _execute_treasury_transfer(self, *, ctx: PlatformContext, transfer: TreasuryTransfer) -> TreasuryTransfer:
        amount = Money(transfer.amount_minor, Currency.from_code(transfer.currency))
        with transaction.atomic():
            transfer = TreasuryTransfer.objects.select_for_update().get(pk=transfer.pk)
            txn = Transaction.objects.create(
                owner="treasury",
                type=TransactionType.TREASURY_TRANSFER,
                status=TransactionStatus.SUCCEEDED,
                direction=TransactionDirection.DEBIT,
                amount_minor=amount.minor_units,
                currency=amount.currency.code,
                counterparty=transfer.to_account.code,
                method_kind="bank",
                idempotency_key=f"tt-{transfer.idempotency_key}",
                note=transfer.narrative,
            )
            entry = journal.post_treasury_transfer(
                txn,
                amount=amount,
                from_bank=transfer.from_account.ledger_bank_code,
                to_bank=transfer.to_account.ledger_bank_code,
            )
            Transaction.objects.filter(pk=txn.pk).update(ledger_entry=entry)
            transfer.transaction = txn
            transfer.status = TreasuryTransferStatus.COMPLETED
            transfer.completed_at = timezone.now()
            transfer.save()
            event_bus.publish(
                DomainEventType.TREASURY_TRANSFER,
                aggregate_type="treasury_transfer",
                aggregate_id=str(transfer.id),
                transaction=txn,
                payload={
                    "from": transfer.from_account.code,
                    "to": transfer.to_account.code,
                    "amount_minor": amount.minor_units,
                },
            )
            audit.record(
                actor=ctx.actor,
                action="treasury.transfer",
                resource_type="treasury_transfer",
                resource_id=str(transfer.id),
                ip=ctx.ip,
            )
        projections.refresh_liquidity(transfer.currency)
        return transfer


def default_platform() -> PlatformOrchestrator:
    return PlatformOrchestrator()
