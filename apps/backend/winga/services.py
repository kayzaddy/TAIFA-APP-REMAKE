"""Winga brokerage workflow services — configurable stage machine."""
from __future__ import annotations

import secrets
from django.db import transaction
from django.utils import timezone

from enterprise import workflow as enterprise_workflow
from enterprise.models import WorkflowDefinition

from . import metrics
from .models import (
    BrokerageDeal,
    DealEvent,
    DealStage,
    Lead,
    Offering,
    ProviderProfile,
    Quotation,
    Review,
    VerificationStatus,
    WingaProfile,
)


class WingaError(Exception):
    pass


DEFAULT_STAGES = [
    DealStage.LEAD,
    DealStage.INQUIRY,
    DealStage.QUOTATION,
    DealStage.OFFER,
    DealStage.ACCEPTED,
    DealStage.PAYMENT,
    DealStage.FULFILLMENT,
    DealStage.SETTLEMENT,
    DealStage.COMMISSION_PAYOUT,
    DealStage.REVIEW,
    DealStage.CLOSED,
]


def _ref() -> str:
    return f"WG-{secrets.token_hex(4).upper()}"


def ensure_default_workflow() -> WorkflowDefinition:
    definition, _ = WorkflowDefinition.objects.get_or_create(
        code="winga.default_brokerage",
        defaults={
            "name": "Winga Default Brokerage",
            "active": True,
            "steps": [{"code": s, "name": s} for s in DEFAULT_STAGES],
        },
    )
    return definition


def _require_verified_winga(winga: WingaProfile) -> None:
    if winga.verification_status != VerificationStatus.VERIFIED:
        raise WingaError("winga is not verified")
    if not winga.active:
        raise WingaError("winga is inactive")


def create_lead(
    *,
    winga: WingaProfile,
    customer_principal: str,
    domain,
    title: str,
    offering: Offering | None = None,
    notes: str = "",
) -> Lead:
    _require_verified_winga(winga)
    lead = Lead.objects.create(
        winga=winga,
        customer_principal=customer_principal,
        domain=domain,
        offering=offering,
        title=title,
        notes=notes,
    )
    metrics.observe_lead_created(domain=domain.code)
    return lead


@transaction.atomic
def open_deal(
    *,
    winga: WingaProfile,
    provider: ProviderProfile,
    customer_principal: str,
    domain,
    amount_minor: int,
    currency: str = "TZS",
    offering: Offering | None = None,
    lead: Lead | None = None,
    quotation: Quotation | None = None,
    booking: dict | None = None,
    actor: str,
) -> BrokerageDeal:
    _require_verified_winga(winga)
    if provider.verification_status != VerificationStatus.VERIFIED:
        raise WingaError("provider is not verified")
    if amount_minor < 0:
        raise WingaError("amount cannot be negative")

    ensure_default_workflow()
    deal = BrokerageDeal.objects.create(
        reference=_ref(),
        domain=domain,
        winga=winga,
        provider=provider,
        customer_principal=customer_principal,
        offering=offering,
        lead=lead,
        quotation=quotation,
        stage=DealStage.LEAD,
        currency=currency,
        amount_minor=amount_minor,
        booking=booking or {},
    )
    try:
        inst = enterprise_workflow.start(
            definition_code=domain.workflow_definition_code or "winga.default_brokerage",
            resource_type="winga_deal",
            resource_id=str(deal.id),
            context={"reference": deal.reference},
        )
        deal.workflow_instance_id = inst.id
        deal.save(update_fields=["workflow_instance_id"])
    except Exception:
        pass

    DealEvent.objects.create(
        deal=deal, from_stage="", to_stage=DealStage.LEAD, actor=actor, note="deal opened"
    )
    metrics.observe_deal_opened(domain=domain.code)
    return deal


def advance_deal(*, deal: BrokerageDeal, to_stage: str, actor: str, note: str = "") -> BrokerageDeal:
    if to_stage not in DealStage.values:
        raise WingaError(f"unknown stage: {to_stage}")
    if deal.stage in {DealStage.CLOSED, DealStage.CANCELLED}:
        raise WingaError("deal is terminal")

    # Payment stage must go through settlement.collect_deal_payment
    if to_stage == DealStage.PAYMENT:
        raise WingaError("use POST …/pay to enter payment stage")
    if to_stage == DealStage.COMMISSION_PAYOUT:
        raise WingaError("use POST …/settle-commission for commission payout")

    prev = deal.stage
    # Optional negotiation is allowed between quotation and offer
    deal.stage = to_stage
    if to_stage == DealStage.CLOSED:
        deal.closed_at = timezone.now()
        deal.save(update_fields=["stage", "closed_at", "updated_at"])
    else:
        deal.save(update_fields=["stage", "updated_at"])

    DealEvent.objects.create(
        deal=deal, from_stage=prev, to_stage=to_stage, actor=actor, note=note
    )
    if deal.workflow_instance_id:
        try:
            enterprise_workflow.advance(
                instance_id=deal.workflow_instance_id, actor=actor, note=note or to_stage
            )
        except Exception:
            pass
    metrics.observe_deal_stage(domain=deal.domain.code, stage=to_stage)
    return deal


def create_quotation(
    *,
    lead: Lead,
    provider: ProviderProfile,
    amount_minor: int,
    currency: str = "TZS",
    line_items: list | None = None,
    notes: str = "",
) -> Quotation:
    return Quotation.objects.create(
        lead=lead,
        provider=provider,
        amount_minor=amount_minor,
        currency=currency,
        line_items=line_items or [],
        notes=notes,
        status="sent",
    )


def submit_review(
    *,
    deal: BrokerageDeal,
    author_principal: str,
    subject_type: str,
    subject_id,
    rating_e4: int,
    comment: str = "",
) -> Review:
    if subject_type not in {"winga", "provider"}:
        raise WingaError("subject_type must be winga|provider")
    if not (1000 <= rating_e4 <= 5000):
        raise WingaError("rating_e4 must be between 1000 and 5000")
    if deal.stage not in {DealStage.REVIEW, DealStage.COMMISSION_PAYOUT, DealStage.CLOSED, DealStage.FULFILLMENT}:
        raise WingaError("reviews allowed after fulfillment")
    return Review.objects.create(
        deal=deal,
        author_principal=author_principal,
        subject_type=subject_type,
        subject_id=subject_id,
        rating_e4=rating_e4,
        comment=comment,
    )
