"""Winga settlement — customer payment + commission payout via Taifa Payments."""
from __future__ import annotations

from django.db import transaction
from django.utils import timezone

from enterprise.models import Merchant, MerchantStatus
from enterprise.orchestrator import PlatformContext, PlatformError, default_platform
from payments.models import (
    DomainEventType,
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money
from enterprise import event_bus

from . import commission as commission_engine
from .ledger_bridge import post_winga_commission_credit
from .metrics import (
    observe_commission_settled,
    observe_deal_paid,
)
from .models import (
    BrokerageDeal,
    CommissionEvent,
    CommissionEventStatus,
    DealStage,
    ProviderProfile,
    VerificationStatus,
)


class SettlementError(Exception):
    pass


def ensure_provider_merchant(provider: ProviderProfile) -> Merchant:
    if provider.merchant_id and provider.merchant:
        merchant = provider.merchant
        if merchant.status != MerchantStatus.ACTIVE:
            raise SettlementError("provider merchant is not active")
        return merchant
    code = f"winga-provider-{str(provider.id)[:8]}"
    merchant, _ = Merchant.objects.get_or_create(
        code=code,
        defaults={
            "legal_name": provider.legal_name,
            "trading_name": provider.trading_name or provider.legal_name,
            "status": MerchantStatus.ACTIVE,
            "fee_bps": 150,
            "tax_bps": 0,
            "commission_bps": 0,  # Winga commission handled separately
            "sector": "winga",
            "owner_principal": provider.principal,
        },
    )
    if provider.merchant_id != merchant.id:
        provider.merchant = merchant
        provider.save(update_fields=["merchant", "updated_at"])
    return merchant


@transaction.atomic
def collect_deal_payment(
    *,
    deal: BrokerageDeal,
    actor: str,
    idempotency_key: str,
) -> BrokerageDeal:
    """Customer pays provider via Taifa Payments; AI never authorizes this path."""
    deal = BrokerageDeal.objects.select_for_update().select_related(
        "provider", "winga", "domain"
    ).get(pk=deal.pk)

    if deal.payment_ref and deal.stage in {
        DealStage.PAYMENT,
        DealStage.FULFILLMENT,
        DealStage.SETTLEMENT,
        DealStage.COMMISSION_PAYOUT,
        DealStage.REVIEW,
        DealStage.CLOSED,
    }:
        return deal

    if deal.winga.verification_status != VerificationStatus.VERIFIED:
        raise SettlementError("winga must be verified before payment")
    if deal.provider.verification_status != VerificationStatus.VERIFIED:
        raise SettlementError("provider must be verified before payment")
    if deal.amount_minor <= 0:
        raise SettlementError("deal amount must be positive")
    if deal.stage not in {DealStage.ACCEPTED, DealStage.OFFER, DealStage.PAYMENT}:
        raise SettlementError(f"deal stage {deal.stage} cannot accept payment")

    # Pre-calculate winga commission and temporarily set merchant.commission_bps
    # so capture reserves commission_income in the ledger for later Winga credit.
    calcs = commission_engine.calculate(deal=deal)
    winga_commission = sum(c.commission_minor for c in calcs if c.level == 1)
    merchant = ensure_provider_merchant(deal.provider)
    # Apply deal-level commission into capture (basis points of amount)
    bps = 0
    if deal.amount_minor > 0 and winga_commission > 0:
        bps = min(10_000, int(winga_commission * 10_000 // deal.amount_minor))
    prev_bps = merchant.commission_bps
    merchant.commission_bps = bps
    merchant.save(update_fields=["commission_bps", "updated_at"])

    currency = Currency.from_code(deal.currency or "TZS")
    amount = Money(deal.amount_minor, currency)
    try:
        txn = default_platform().capture_merchant_payment(
            ctx=PlatformContext(actor=actor),
            merchant=merchant,
            payer_owner=deal.customer_principal,
            amount=amount,
            idempotency_key=idempotency_key,
            note=f"Winga deal {deal.reference}",
        )
    except PlatformError as exc:
        merchant.commission_bps = prev_bps
        merchant.save(update_fields=["commission_bps", "updated_at"])
        raise SettlementError(str(exc)) from exc
    finally:
        # Restore merchant default; deal-specific commission is on CommissionEvent
        Merchant.objects.filter(pk=merchant.pk).update(commission_bps=prev_bps)

    deal.payment_ref = str(txn.id)
    deal.stage = DealStage.PAYMENT
    deal.save(update_fields=["payment_ref", "stage", "updated_at"])
    commission_engine.record_for_deal(deal=deal)
    observe_deal_paid(domain=deal.domain.code)
    return deal


@transaction.atomic
def settle_commissions(*, deal: BrokerageDeal, actor: str) -> list[CommissionEvent]:
    """Credit Winga wallet from commission_income for calculated events."""
    deal = BrokerageDeal.objects.select_for_update().select_related("winga").get(pk=deal.pk)
    if not deal.payment_ref:
        raise SettlementError("deal is not paid")

    events = list(
        CommissionEvent.objects.select_for_update().filter(
            deal=deal,
            status=CommissionEventStatus.CALCULATED,
        )
    )
    if not events:
        events = commission_engine.record_for_deal(deal=deal)

    settled: list[CommissionEvent] = []
    currency = Currency.from_code(deal.currency or "TZS")
    for ev in events:
        if ev.commission_minor <= 0:
            ev.status = CommissionEventStatus.CANCELLED
            ev.save(update_fields=["status"])
            continue
        # Level > 1 would pay upline principals from metadata — level 1 = deal.winga
        principal = deal.winga.principal
        if ev.level > 1:
            upline = (deal.metadata or {}).get("upline") or []
            idx = ev.level - 2
            if idx < 0 or idx >= len(upline):
                continue
            principal = str(upline[idx])

        idem = f"winga-commission:{deal.id}:{ev.level}"
        existing = Transaction.objects.filter(idempotency_key=idem).first()
        if existing:
            ev.ledger_txn_id = str(existing.id)
            ev.status = CommissionEventStatus.SETTLED
            ev.settled_at = timezone.now()
            ev.save(update_fields=["ledger_txn_id", "status", "settled_at"])
            settled.append(ev)
            continue

        amount = Money(ev.commission_minor, currency)
        txn = Transaction.objects.create(
            owner=principal,
            type=TransactionType.RECEIVE_MONEY,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=amount.minor_units,
            fee_minor=0,
            currency=currency.code,
            counterparty=f"winga-deal:{deal.reference}",
            method_kind="winga_commission",
            idempotency_key=idem,
            note=f"Winga commission {deal.reference} L{ev.level}",
        )
        entry = post_winga_commission_credit(
            txn,
            winga_principal=principal,
            amount=amount,
            deal_ref=deal.reference,
        )
        Transaction.objects.filter(pk=txn.pk).update(ledger_entry=entry)
        ev.ledger_txn_id = str(txn.id)
        ev.status = CommissionEventStatus.SETTLED
        ev.settled_at = timezone.now()
        ev.save(update_fields=["ledger_txn_id", "status", "settled_at"])
        settled.append(ev)
        observe_commission_settled(domain=deal.domain.code)
        event_bus.publish(
            DomainEventType.COMMISSION_CALCULATED,
            aggregate_type="winga_deal",
            aggregate_id=str(deal.id),
            transaction=txn,
            owner=principal,
            payload={
                "commission_minor": ev.commission_minor,
                "level": ev.level,
                "deal": deal.reference,
                "actor": actor,
            },
        )

    deal.stage = DealStage.COMMISSION_PAYOUT
    deal.save(update_fields=["stage", "updated_at"])
    return settled


@transaction.atomic
def reverse_commissions(*, deal: BrokerageDeal, actor: str, reason: str = "") -> list[CommissionEvent]:
    """Mark settled commissions reversed; refund path uses payments refund separately."""
    events = list(
        CommissionEvent.objects.select_for_update().filter(
            deal=deal, status=CommissionEventStatus.SETTLED
        )
    )
    for ev in events:
        ev.status = CommissionEventStatus.REVERSED
        calc = dict(ev.calculation or {})
        calc["reversal"] = {"actor": actor, "reason": reason, "at": timezone.now().isoformat()}
        ev.calculation = calc
        ev.save(update_fields=["status", "calculation"])
    return events
