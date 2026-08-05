"""Production readiness gates — Django system checks + runtime helpers.

When DEBUG is false these checks refuse unsafe configuration so a mis-set
.env cannot mint demo money, accept unsigned webhooks, or run unlimited risk.
"""
from __future__ import annotations

from django.conf import settings
from django.core.checks import Error, register


def demo_wallet_funding_allowed() -> bool:
    """True only when explicitly enabled (defaults on in DEBUG for local demos)."""
    return bool(getattr(settings, "ALLOW_DEMO_WALLET_FUNDING", False))


def is_production_runtime() -> bool:
    """True for non-DEBUG, non-test deployments."""
    return (not settings.DEBUG) and (not getattr(settings, "RUNNING_TESTS", False))


@register()
def check_production_payment_gates(app_configs, **kwargs):
    errors: list[Error] = []
    if not is_production_runtime():
        return errors

    if getattr(settings, "ALLOW_DEMO_WALLET_FUNDING", False):
        errors.append(
            Error(
                "TAIFA_ALLOW_DEMO_WALLET_FUNDING must be false in production.",
                hint="Demo wallet minting creates liability outside settlement.",
                id="payments.E001",
            )
        )
    if getattr(settings, "ALLOW_DEMO_STK", False):
        errors.append(
            Error(
                "TAIFA_ALLOW_DEMO_STK must be false in production.",
                hint="Demo STK settle synthesizes money movement without Daraja.",
                id="payments.E002",
            )
        )
    if getattr(settings, "WITHDRAWAL_AUTO_APPROVE", False):
        errors.append(
            Error(
                "TAIFA_WITHDRAWAL_AUTO_APPROVE must be false in production.",
                id="payments.E003",
            )
        )
    secret = getattr(settings, "MPESA_WEBHOOK_SHARED_SECRET", "") or ""
    if not secret:
        errors.append(
            Error(
                "MPESA_WEBHOOK_SHARED_SECRET is required when DEBUG=false.",
                hint="Unsigned webhooks must never change money in production.",
                id="payments.E004",
            )
        )
    if int(getattr(settings, "RISK_PER_TXN_LIMIT_MINOR", 0) or 0) <= 0 and not getattr(
        settings, "RISK_ALLOW_UNLIMITED", False
    ):
        errors.append(
            Error(
                "RISK_PER_TXN_LIMIT_MINOR must be > 0 in production "
                "(or set RISK_ALLOW_UNLIMITED=true with explicit approval).",
                id="payments.E005",
            )
        )
    if int(getattr(settings, "RISK_DAILY_DEBIT_LIMIT_MINOR", 0) or 0) <= 0 and not getattr(
        settings, "RISK_ALLOW_UNLIMITED", False
    ):
        errors.append(
            Error(
                "RISK_DAILY_DEBIT_LIMIT_MINOR must be > 0 in production "
                "(or set RISK_ALLOW_UNLIMITED=true with explicit approval).",
                id="payments.E006",
            )
        )
    return errors
