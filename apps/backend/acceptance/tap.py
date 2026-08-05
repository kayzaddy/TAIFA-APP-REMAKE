"""Tap & Pay services — NFC/SoftPOS session + funding prefs.

Money capture exclusively via pay_intent → capture_merchant_payment.
"""
from __future__ import annotations

from datetime import timedelta
from typing import Any

from django.db import transaction
from django.utils import timezone

from enterprise.models import Merchant, MerchantStatus
from payments import journal, ledger
from payments.money import Currency

from . import metrics, services
from .models import (
    AcceptanceChannel,
    AcceptanceTerminal,
    AuthPolicy,
    FundingSourceKind,
    TapSession,
    TapSessionStatus,
    WalletFundingPreference,
)


class TapError(Exception):
    pass


DEFAULT_PRIORITY: list[dict[str, Any]] = [
    {"kind": FundingSourceKind.WALLET, "ref": "taifa_wallet", "label": "Taifa Wallet", "enabled": True},
    {"kind": FundingSourceKind.MOBILE_MONEY, "ref": "mpesa", "label": "M-Pesa", "enabled": True},
    {"kind": FundingSourceKind.MOBILE_MONEY, "ref": "airtel", "label": "Airtel Money", "enabled": True},
    {"kind": FundingSourceKind.BANK, "ref": "crdb", "label": "CRDB", "enabled": True},
    {"kind": FundingSourceKind.BANK, "ref": "nmb", "label": "NMB", "enabled": True},
    {"kind": FundingSourceKind.CARD, "ref": "visa", "label": "Visa", "enabled": True},
    {"kind": FundingSourceKind.CARD, "ref": "mastercard", "label": "Mastercard", "enabled": True},
]


def get_or_create_funding_prefs(*, owner_principal: str) -> WalletFundingPreference:
    prefs, _ = WalletFundingPreference.objects.get_or_create(
        owner_principal=owner_principal,
        defaults={"priority": list(DEFAULT_PRIORITY)},
    )
    if not prefs.priority:
        prefs.priority = list(DEFAULT_PRIORITY)
        prefs.save(update_fields=["priority", "updated_at"])
    return prefs


def update_funding_prefs(
    *,
    owner_principal: str,
    priority: list | None = None,
    auto_route: bool | None = None,
    require_confirmation: bool | None = None,
    auth_policy: str | None = None,
    low_risk_threshold_minor: int | None = None,
    merchant_overrides: dict | None = None,
) -> WalletFundingPreference:
    prefs = get_or_create_funding_prefs(owner_principal=owner_principal)
    if priority is not None:
        prefs.priority = priority
    if auto_route is not None:
        prefs.auto_route = auto_route
    if require_confirmation is not None:
        prefs.require_confirmation = require_confirmation
    if auth_policy is not None:
        prefs.auth_policy = auth_policy
    if low_risk_threshold_minor is not None:
        prefs.low_risk_threshold_minor = low_risk_threshold_minor
    if merchant_overrides is not None:
        prefs.merchant_overrides = merchant_overrides
    prefs.save()
    return prefs


def _wallet_balance_minor(owner: str, currency: str) -> int:
    try:
        bal = ledger.balance_of(journal.user_wallet(owner, Currency.from_code(currency)))
        return int(bal.minor_units)
    except Exception:
        return 0


def resolve_funding(
    *,
    owner_principal: str,
    amount_minor: int,
    currency: str = "TZS",
    merchant_code: str = "",
) -> dict[str, Any]:
    """Pick preferred funding source. Capture still uses wallet ledger today.

    Non-wallet sources return as suggestions / fallbacks without charging.
    """
    prefs = get_or_create_funding_prefs(owner_principal=owner_principal)
    priority = list(prefs.priority or DEFAULT_PRIORITY)
    if merchant_code and prefs.merchant_overrides.get(merchant_code):
        override = prefs.merchant_overrides[merchant_code]
        if isinstance(override, list):
            priority = override

    balance = _wallet_balance_minor(owner_principal, currency)
    selected = None
    fallbacks: list[dict] = []
    for item in priority:
        if not item.get("enabled", True):
            continue
        kind = item.get("kind") or FundingSourceKind.WALLET
        entry = {
            "kind": kind,
            "ref": item.get("ref") or "",
            "label": item.get("label") or kind,
            "available": True,
            "reason": "",
        }
        if kind == FundingSourceKind.WALLET:
            if balance >= amount_minor:
                entry["balance_minor"] = balance
                selected = entry
                break
            entry["available"] = False
            entry["reason"] = "insufficient_wallet_balance"
            entry["balance_minor"] = balance
            fallbacks.append(entry)
            continue
        # External rails: eligible as fallback suggestion (top-up / future capture)
        entry["available"] = True
        entry["reason"] = "requires_wallet_funding_or_future_rail"
        if selected is None:
            # Prefer wallet; park others as next options
            fallbacks.append(entry)
        else:
            fallbacks.append(entry)

    if selected is None:
        # Auto-route: if wallet short, suggest first enabled non-wallet
        for fb in fallbacks:
            if fb.get("kind") != FundingSourceKind.WALLET and fb.get("available"):
                selected = {**fb, "pending_action": "fund_or_switch"}
                break
        if selected is None and fallbacks:
            selected = fallbacks[0]

    return {
        "selected": selected,
        "fallbacks": fallbacks,
        "wallet_balance_minor": balance,
        "auto_route": prefs.auto_route,
        "require_confirmation": prefs.require_confirmation,
        "auth_policy": prefs.auth_policy,
        "low_risk_threshold_minor": prefs.low_risk_threshold_minor,
    }


def _auth_required(prefs: WalletFundingPreference, amount_minor: int) -> bool:
    if prefs.require_confirmation:
        return True
    if prefs.auth_policy == AuthPolicy.ALWAYS:
        return True
    if prefs.auth_policy == AuthPolicy.LOW_FRICTION:
        return amount_minor > prefs.low_risk_threshold_minor
    if prefs.auth_policy == AuthPolicy.PIN_ONLY:
        return True
    # risk_based / biometric_preferred
    return amount_minor > prefs.low_risk_threshold_minor


@transaction.atomic
def start_tap(
    *,
    merchant: Merchant,
    amount_minor: int,
    currency: str = "TZS",
    payer_principal: str,
    channel: str = AcceptanceChannel.NFC,
    terminal_code: str = "",
    nfc_meta: dict | None = None,
    ttl_seconds: int = 90,
    created_by: str = "",
) -> TapSession:
    if merchant.status != MerchantStatus.ACTIVE:
        raise TapError("merchant not active")
    amount_minor = int(amount_minor)
    if amount_minor <= 0:
        raise TapError("amount_minor must be positive")
    if channel not in (AcceptanceChannel.NFC, AcceptanceChannel.SOFTPOS, AcceptanceChannel.POS):
        channel = AcceptanceChannel.NFC

    profile = services.ensure_profile(merchant=merchant)
    terminal = None
    if terminal_code:
        terminal = AcceptanceTerminal.objects.filter(
            merchant=merchant, code=terminal_code, active=True
        ).first()

    intent = services.create_intent(
        merchant=merchant,
        amount_minor=amount_minor,
        channel=channel,
        currency=currency,
        description=f"Tap & Pay · {profile.display_name}",
        ttl_minutes=max(2, (ttl_seconds + 59) // 60),
        created_by=created_by or payer_principal,
        metadata={"tap": True, "terminal": terminal_code},
    )

    prefs = get_or_create_funding_prefs(owner_principal=payer_principal)
    routing = resolve_funding(
        owner_principal=payer_principal,
        amount_minor=amount_minor,
        currency=currency,
        merchant_code=merchant.code,
    )
    need_auth = _auth_required(prefs, amount_minor)
    status = TapSessionStatus.AUTH_REQUIRED if need_auth else TapSessionStatus.DETECTED

    session = TapSession.objects.create(
        merchant=merchant,
        intent=intent,
        terminal=terminal,
        channel=channel,
        status=status,
        amount_minor=amount_minor,
        currency=currency,
        payer_principal=payer_principal,
        selected_funding=routing.get("selected") or {},
        auth_required=need_auth,
        merchant_display=profile.display_name,
        terminal_capability={
            "softpos_ready": bool(terminal.softpos_ready) if terminal else False,
            "nfc_ready": bool(terminal.nfc_ready) if terminal else True,
            "code": terminal_code,
        },
        nfc_meta=nfc_meta or {},
        expires_at=timezone.now() + timedelta(seconds=ttl_seconds),
    )
    metrics.tap_started.labels(channel=channel).inc()
    return session


def authenticate_tap(
    *,
    session: TapSession,
    method: str = "biometric",
    actor: str = "",
) -> TapSession:
    if session.status in (
        TapSessionStatus.SUCCEEDED,
        TapSessionStatus.CANCELLED,
        TapSessionStatus.EXPIRED,
    ):
        raise TapError("session not authenticatable")
    if session.expires_at and timezone.now() >= session.expires_at:
        session.status = TapSessionStatus.EXPIRED
        session.save(update_fields=["status", "updated_at"])
        raise TapError("session expired")
    session.auth_method = method
    session.auth_completed = True
    session.status = TapSessionStatus.AUTHORIZING
    session.save(update_fields=["auth_method", "auth_completed", "status", "updated_at"])
    metrics.tap_auth.labels(method=method).inc()
    return session


def confirm_tap(
    *,
    session: TapSession,
    idempotency_key: str,
    funding_ref: str | None = None,
    actor: str = "",
) -> TapSession:
    """Authorize tap — delegates to pay_intent (ledger-backed)."""
    if session.status == TapSessionStatus.SUCCEEDED and session.payment_ref:
        return session
    if session.expires_at and timezone.now() >= session.expires_at:
        TapSession.objects.filter(pk=session.pk).update(
            status=TapSessionStatus.EXPIRED, updated_at=timezone.now()
        )
        session.refresh_from_db()
        raise TapError("session expired")
    if session.auth_required and not session.auth_completed:
        raise TapError("authentication required")
    if not session.intent_id:
        raise TapError("missing payment intent")

    routing = resolve_funding(
        owner_principal=session.payer_principal,
        amount_minor=session.amount_minor,
        currency=session.currency,
        merchant_code=session.merchant.code,
    )
    selected = routing.get("selected") or {}
    if funding_ref:
        for cand in [selected, *routing.get("fallbacks", [])]:
            if cand and cand.get("ref") == funding_ref:
                selected = cand
                break

    # Capture path requires wallet funds today — never double-charge other rails here
    wallet_ok = (
        selected.get("kind") == FundingSourceKind.WALLET
        and selected.get("available", False)
        and routing["wallet_balance_minor"] >= session.amount_minor
    )
    if not wallet_ok:
        TapSession.objects.filter(pk=session.pk).update(
            status=TapSessionStatus.FALLBACK,
            failure_reason="insufficient_wallet_balance",
            selected_funding=selected,
            updated_at=timezone.now(),
        )
        session.refresh_from_db()
        metrics.tap_failed.labels(reason="insufficient_funds").inc()
        raise TapError(
            "insufficient_wallet_balance: fund wallet or choose another source after top-up"
        )

    TapSession.objects.filter(pk=session.pk).update(
        status=TapSessionStatus.AUTHORIZING,
        selected_funding=selected,
        updated_at=timezone.now(),
    )
    session.refresh_from_db()

    try:
        with transaction.atomic():
            intent, receipt = services.pay_intent(
                intent=session.intent,
                payer_principal=session.payer_principal,
                idempotency_key=idempotency_key,
                actor=actor or session.payer_principal,
            )
    except services.MapError as exc:
        TapSession.objects.filter(pk=session.pk).update(
            status=TapSessionStatus.FAILED,
            failure_reason=str(exc),
            updated_at=timezone.now(),
        )
        session.refresh_from_db()
        metrics.tap_failed.labels(reason="capture").inc()
        raise TapError(str(exc)) from exc

    TapSession.objects.filter(pk=session.pk).update(
        status=TapSessionStatus.SUCCEEDED,
        payment_ref=intent.payment_ref,
        receipt_code=receipt.public_code,
        completed_at=timezone.now(),
        failure_reason="",
        updated_at=timezone.now(),
    )
    session.refresh_from_db()
    metrics.tap_succeeded.labels(channel=session.channel).inc()
    return session


def cancel_tap(*, session: TapSession) -> TapSession:
    if session.status == TapSessionStatus.SUCCEEDED:
        raise TapError("cannot cancel completed tap")
    session.status = TapSessionStatus.CANCELLED
    session.save(update_fields=["status", "updated_at"])
    return session
