"""Payment Orchestrator — coordinates risk → engine → events → audit.

Contains no ledger posting recipes and no balance math. Accounting stays in
`journal` / `ledger`. Settlement rails stay in `engine` / gateways.
"""
from __future__ import annotations

from dataclasses import dataclass

from . import audit, events
from .engine import EngineResult, TransactionEngine, default_engine
from .models import DomainEventType, Transaction
from .money import Money
from .risk import RiskContext, RiskDecisionKind, RiskDenied, RiskEngine, default_risk_engine
from .state_machine import IllegalStateTransition


@dataclass
class OrchestratorContext:
    actor: str
    device_id: str = ""
    ip: str | None = None


class PaymentOrchestrator:
    def __init__(
        self,
        engine: TransactionEngine | None = None,
        risk: RiskEngine | None = None,
    ):
        self.engine = engine or default_engine()
        self.risk = risk or default_risk_engine()

    def wallet_balance(self, owner: str, currency):
        return self.engine.wallet_balance(owner, currency)

    def open_wallet(self, owner: str, initial: Money, ctx: OrchestratorContext | None = None):
        txn = self.engine.open_wallet(owner, initial)
        events.emit(
            DomainEventType.PAYMENT_SETTLED,
            transaction=txn,
            payload={"kind": "opening", "amount_minor": initial.minor_units},
        )
        if ctx:
            audit.record(
                actor=ctx.actor,
                action="wallet.open",
                resource_type="transaction",
                resource_id=str(txn.id),
                device_id=ctx.device_id,
                ip=ctx.ip,
                after={"status": txn.status, "amount_minor": txn.amount_minor},
            )
        return txn

    def _gate(self, ctx: OrchestratorContext, risk_ctx: RiskContext) -> None:
        decision = self.risk.evaluate(risk_ctx)
        if decision.kind == RiskDecisionKind.ALLOW:
            return
        events.emit(
            DomainEventType.RISK_DENIED
            if decision.kind == RiskDecisionKind.DENY
            else DomainEventType.RISK_REVIEW,
            owner=risk_ctx.owner,
            payload={
                "code": decision.code,
                "message": decision.message,
                "operation": risk_ctx.operation,
                "amount_minor": risk_ctx.amount.minor_units,
                "rules": list(decision.rules_fired),
            },
        )
        audit.record(
            actor=ctx.actor,
            action="risk.deny",
            resource_type="risk",
            device_id=ctx.device_id,
            ip=ctx.ip,
            reason=decision.message,
            metadata={"code": decision.code, "kind": decision.kind},
        )
        # Automated rails: review == deny until ops queue exists.
        raise RiskDenied(decision)

    def _after_money(self, ctx: OrchestratorContext, action: str, outcome: EngineResult, previous: str | None = None):
        txn = outcome.transaction
        if not outcome.replayed:
            if previous:
                events.for_status(txn, previous)
            elif txn.type == "withdrawal" and txn.status == "pending":
                events.emit(DomainEventType.WITHDRAWAL_REQUESTED, transaction=txn)
            elif txn.type == "refund":
                events.emit(DomainEventType.REFUND_CREATED, transaction=txn)
                events.emit(DomainEventType.REFUND_COMPLETED, transaction=txn)
            elif txn.status == "succeeded":
                events.payment_settled(txn)
            else:
                events.emit(DomainEventType.PAYMENT_CREATED, transaction=txn, payload={"status": txn.status})
        audit.record(
            actor=ctx.actor,
            action=action,
            resource_type="transaction",
            resource_id=str(txn.id),
            device_id=ctx.device_id,
            ip=ctx.ip,
            after={
                "status": txn.status,
                "type": txn.type,
                "amount_minor": txn.amount_minor,
                "replayed": outcome.replayed,
            },
        )
        return outcome

    def initiate_topup(self, *, ctx: OrchestratorContext, owner: str, amount: Money, **kwargs) -> EngineResult:
        self._gate(ctx, RiskContext(owner=owner, amount=amount, operation="topup", device_id=ctx.device_id, ip=ctx.ip))
        outcome = self.engine.initiate_topup(owner=owner, amount=amount, **kwargs)
        return self._after_money(ctx, "payment.topup", outcome)

    def initiate_transfer(self, *, ctx: OrchestratorContext, owner: str, amount: Money, **kwargs) -> EngineResult:
        self._gate(
            ctx,
            RiskContext(
                owner=owner,
                amount=amount,
                operation="transfer",
                device_id=ctx.device_id,
                ip=ctx.ip,
                counterparty=kwargs.get("counterparty", ""),
            ),
        )
        outcome = self.engine.initiate_transfer(owner=owner, amount=amount, **kwargs)
        return self._after_money(ctx, "payment.transfer", outcome)

    def initiate_p2p(self, *, ctx: OrchestratorContext, payer: str, payee: str, amount: Money, **kwargs) -> EngineResult:
        self._gate(
            ctx,
            RiskContext(
                owner=payer,
                amount=amount,
                operation="transfer",
                device_id=ctx.device_id,
                ip=ctx.ip,
                counterparty=payee,
            ),
        )
        outcome = self.engine.initiate_p2p(payer=payer, payee=payee, amount=amount, **kwargs)
        return self._after_money(ctx, "payment.p2p", outcome)

    def initiate_withdrawal(self, *, ctx: OrchestratorContext, owner: str, amount: Money, **kwargs) -> EngineResult:
        self._gate(
            ctx,
            RiskContext(owner=owner, amount=amount, operation="withdrawal", device_id=ctx.device_id, ip=ctx.ip),
        )
        outcome = self.engine.initiate_withdrawal(owner=owner, amount=amount, **kwargs)
        return self._after_money(ctx, "payment.withdrawal", outcome)

    def approve_withdrawal(self, *, ctx: OrchestratorContext, txn: Transaction) -> Transaction:
        previous = txn.status
        try:
            txn = self.engine.approve_withdrawal(txn)
        except IllegalStateTransition:
            raise
        events.for_status(txn, previous)
        audit.record(
            actor=ctx.actor,
            action="withdrawal.approve",
            resource_type="transaction",
            resource_id=str(txn.id),
            device_id=ctx.device_id,
            ip=ctx.ip,
            before={"status": previous},
            after={"status": txn.status},
        )
        return txn

    def reject_withdrawal(self, *, ctx: OrchestratorContext, txn: Transaction, reason: str = "") -> Transaction:
        previous = txn.status
        txn = self.engine.reject_withdrawal(txn, reason=reason)
        events.for_status(txn, previous)
        audit.record(
            actor=ctx.actor,
            action="withdrawal.reject",
            resource_type="transaction",
            resource_id=str(txn.id),
            device_id=ctx.device_id,
            ip=ctx.ip,
            reason=reason,
            before={"status": previous},
            after={"status": txn.status},
        )
        return txn

    def process_withdrawal(self, *, ctx: OrchestratorContext, txn: Transaction) -> EngineResult:
        previous = txn.status
        outcome = self.engine.process_withdrawal(txn)
        return self._after_money(ctx, "withdrawal.process", outcome, previous=previous)

    def initiate_refund(self, *, ctx: OrchestratorContext, owner: str, amount: Money, **kwargs) -> EngineResult:
        self._gate(ctx, RiskContext(owner=owner, amount=amount, operation="refund", device_id=ctx.device_id, ip=ctx.ip))
        outcome = self.engine.initiate_refund(owner=owner, amount=amount, **kwargs)
        return self._after_money(ctx, "payment.refund", outcome)

    def reverse_transaction(self, *, ctx: OrchestratorContext, owner: str, **kwargs) -> EngineResult:
        original = kwargs["original"]
        previous = original.status
        outcome = self.engine.reverse_transaction(owner=owner, **kwargs)
        events.for_status(outcome.transaction, previous)
        events.for_status(original, previous)  # original now reversed — refresh
        original.refresh_from_db()
        events.emit(
            DomainEventType.REVERSAL_COMPLETED,
            transaction=outcome.transaction,
            payload={"original": str(original.id)},
        )
        audit.record(
            actor=ctx.actor,
            action="payment.reverse",
            resource_type="transaction",
            resource_id=str(outcome.transaction.id),
            device_id=ctx.device_id,
            ip=ctx.ip,
            after={"original": str(original.id), "status": outcome.transaction.status},
        )
        return outcome


    def settle_mpesa_stk_callback(self, payload: dict, *, ctx: OrchestratorContext | None = None) -> object:
        """Single entry for STK money settlement — events + audit, no bypass."""
        from .webhooks import process_mpesa_stk_callback

        ctx = ctx or OrchestratorContext(actor="mpesa-webhook", device_id="", ip=None)
        event = process_mpesa_stk_callback(payload, engine=self.engine)
        audit.record(
            actor=ctx.actor,
            action="webhook.mpesa.stk",
            resource_type="webhook_event",
            resource_id=str(event.id),
            device_id=ctx.device_id,
            ip=ctx.ip,
            after={
                "result": event.result,
                "provider_ref": event.provider_ref,
                "processed": event.processed,
            },
        )
        if event.result == "succeeded":
            txn = Transaction.objects.filter(provider_ref=event.provider_ref).first()
            if txn:
                events.payment_settled(txn)
                events.emit(
                    DomainEventType.PAYMENT_SETTLED,
                    transaction=txn,
                    payload={"source": "mpesa_stk_webhook"},
                )
        elif event.result == "failed":
            txn = Transaction.objects.filter(provider_ref=event.provider_ref).first()
            if txn:
                events.emit(
                    DomainEventType.PAYMENT_FAILED,
                    transaction=txn,
                    payload={"source": "mpesa_stk_webhook"},
                )
        return event


def default_orchestrator() -> PaymentOrchestrator:
    return PaymentOrchestrator()
