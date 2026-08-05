"""Configurable business rule engine — no deploy required to change parameters."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from .models import BusinessRule


@dataclass
class RuleResult:
    matched: list[str]
    actions: dict[str, Any]


def _match(conditions: dict, ctx: dict) -> bool:
    for key, expected in (conditions or {}).items():
        if key.endswith("_gt_minor"):
            field = key[: -len("_gt_minor")]
            if int(ctx.get(field, 0) or 0) <= int(expected):
                return False
        elif key.endswith("_gte_minor"):
            field = key[: -len("_gte_minor")]
            if int(ctx.get(field, 0) or 0) < int(expected):
                return False
        elif ctx.get(key) != expected:
            return False
    return True


def evaluate(category: str, ctx: dict) -> RuleResult:
    matched: list[str] = []
    actions: dict[str, Any] = {}
    rules = BusinessRule.objects.filter(category=category, active=True).order_by("priority", "code")
    for rule in rules:
        if _match(rule.conditions or {}, ctx):
            matched.append(rule.code)
            actions.update(rule.actions or {})
    return RuleResult(matched=matched, actions=actions)


def fee_components(*, amount_minor: int, merchant_fee_bps: int, merchant_tax_bps: int, merchant_commission_bps: int, sector: str = "") -> dict[str, int]:
    """Merge merchant defaults with category=fee rules."""
    result = evaluate(
        "fee",
        {
            "amount_minor": amount_minor,
            "sector": sector,
            "fee_bps": merchant_fee_bps,
        },
    )
    fee_bps = int(result.actions.get("fee_bps", merchant_fee_bps))
    tax_bps = int(result.actions.get("tax_bps", merchant_tax_bps))
    commission_bps = int(result.actions.get("commission_bps", merchant_commission_bps))
    fee = amount_minor * fee_bps // 10_000
    tax = amount_minor * tax_bps // 10_000
    commission = amount_minor * commission_bps // 10_000
    return {
        "fee_minor": fee,
        "tax_minor": tax,
        "commission_minor": commission,
        "rules": result.matched,
    }
