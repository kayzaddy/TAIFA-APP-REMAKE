"""Winga commission engine — percentage, flat, tiered, category, provider, campaign, multi-level."""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from django.db.models import Q
from django.utils import timezone

from .models import (
    BrokerageDeal,
    CommissionEvent,
    CommissionEventStatus,
    CommissionKind,
    CommissionRule,
    WingaProfile,
)


@dataclass(frozen=True)
class CommissionCalculation:
    kind: str
    commission_minor: int
    bps_applied: int
    rule_id: str | None
    level: int
    detail: dict


class CommissionError(Exception):
    pass


def _rule_active(rule: CommissionRule, now: datetime) -> bool:
    if not rule.active:
        return False
    if rule.valid_from and now < rule.valid_from:
        return False
    if rule.valid_to and now > rule.valid_to:
        return False
    return True


def select_rule(*, deal: BrokerageDeal, now: datetime | None = None) -> CommissionRule | None:
    """Most specific matching rule wins (priority ascending, then specificity)."""
    now = now or timezone.now()
    qs = CommissionRule.objects.filter(active=True).filter(
        Q(domain__isnull=True) | Q(domain=deal.domain),
        Q(provider__isnull=True) | Q(provider=deal.provider),
        Q(winga__isnull=True) | Q(winga=deal.winga),
        Q(category__isnull=True)
        | Q(category=deal.offering.category if deal.offering_id else None),
    ).order_by("priority", "-created_at")

    candidates = [r for r in qs if _rule_active(r, now)]
    if not candidates:
        return None

    def specificity(r: CommissionRule) -> int:
        score = 0
        if r.winga_id:
            score += 8
        if r.provider_id:
            score += 4
        if r.category_id:
            score += 2
        if r.domain_id:
            score += 1
        if r.campaign_code:
            score += 1
        return score

    candidates.sort(key=lambda r: (r.priority, -specificity(r)))
    return candidates[0]


def _tiered_bps(tiers: list, amount_minor: int) -> int:
    for tier in tiers or []:
        lo = int(tier.get("min_minor", 0))
        hi = tier.get("max_minor")
        if amount_minor < lo:
            continue
        if hi is None or amount_minor <= int(hi):
            return int(tier.get("bps", 0))
    return 0


def calculate(*, deal: BrokerageDeal, rule: CommissionRule | None = None) -> list[CommissionCalculation]:
    """Return one or more commission lines (multi-level expands to multiple)."""
    amount = int(deal.amount_minor or 0)
    if amount <= 0:
        raise CommissionError("deal amount must be positive to calculate commission")

    rule = rule or select_rule(deal=deal)
    if rule is None:
        # Domain default
        bps = int(deal.domain.default_commission_bps or 0)
        return [
            CommissionCalculation(
                kind=CommissionKind.PERCENTAGE,
                commission_minor=amount * bps // 10_000,
                bps_applied=bps,
                rule_id=None,
                level=1,
                detail={"source": "domain_default", "domain": deal.domain.code},
            )
        ]

    kind = rule.kind
    if kind == CommissionKind.FLAT:
        return [
            CommissionCalculation(
                kind=kind,
                commission_minor=int(rule.flat_minor),
                bps_applied=0,
                rule_id=str(rule.id),
                level=1,
                detail={"flat_minor": rule.flat_minor, "rule": rule.code},
            )
        ]

    if kind == CommissionKind.TIERED:
        bps = _tiered_bps(rule.tiers, amount)
        return [
            CommissionCalculation(
                kind=kind,
                commission_minor=amount * bps // 10_000,
                bps_applied=bps,
                rule_id=str(rule.id),
                level=1,
                detail={"tiers": rule.tiers, "rule": rule.code},
            )
        ]

    if kind == CommissionKind.MULTI_LEVEL:
        levels = rule.multi_level or [{"level": 1, "bps": rule.bps}]
        out: list[CommissionCalculation] = []
        for row in levels:
            bps = int(row.get("bps", 0))
            level = int(row.get("level", 1))
            out.append(
                CommissionCalculation(
                    kind=kind,
                    commission_minor=amount * bps // 10_000,
                    bps_applied=bps,
                    rule_id=str(rule.id),
                    level=level,
                    detail={"rule": rule.code, "level": level},
                )
            )
        return out

    # percentage / category / provider / campaign / referral_bonus
    bps = int(rule.bps)
    return [
        CommissionCalculation(
            kind=kind,
            commission_minor=amount * bps // 10_000,
            bps_applied=bps,
            rule_id=str(rule.id),
            level=1,
            detail={"rule": rule.code, "campaign": rule.campaign_code},
        )
    ]


def record_for_deal(*, deal: BrokerageDeal, winga: WingaProfile | None = None) -> list[CommissionEvent]:
    """Persist CommissionEvent rows (status=calculated). Idempotent per deal+level."""
    winga = winga or deal.winga
    calcs = calculate(deal=deal)
    events: list[CommissionEvent] = []
    for calc in calcs:
        existing = CommissionEvent.objects.filter(
            deal=deal, winga=winga, level=calc.level, status=CommissionEventStatus.CALCULATED
        ).first()
        if existing:
            events.append(existing)
            continue
        rule = None
        if calc.rule_id:
            rule = CommissionRule.objects.filter(pk=calc.rule_id).first()
        events.append(
            CommissionEvent.objects.create(
                deal=deal,
                rule=rule,
                winga=winga,
                kind=calc.kind,
                currency=deal.currency,
                basis_amount_minor=deal.amount_minor,
                commission_minor=calc.commission_minor,
                bps_applied=calc.bps_applied,
                level=calc.level,
                status=CommissionEventStatus.CALCULATED,
                calculation=calc.detail,
            )
        )
    return events
