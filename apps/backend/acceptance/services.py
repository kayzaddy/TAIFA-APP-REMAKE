"""MAP services — acceptance UX + intent lifecycle.

All money movement goes through enterprise.PlatformOrchestrator.capture_merchant_payment.
"""
from __future__ import annotations

from datetime import timedelta
from typing import Any

from django.db import transaction
from django.utils import timezone

from enterprise.models import Merchant, MerchantStatus
from enterprise.orchestrator import PlatformContext, PlatformError, PlatformOrchestrator
from payments.money import Currency, Money

from . import metrics, security
from .models import (
    AcceptanceChannel,
    AcceptanceIntent,
    AcceptanceProfile,
    AcceptanceReceipt,
    AcceptanceTerminal,
    CheckoutSession,
    DigitalInvoice,
    IntentStatus,
    LinkPurpose,
    PaymentLink,
    QrArtifact,
    QrKind,
    TerminalKind,
)


class MapError(Exception):
    pass


DEFAULT_METHODS = [
    AcceptanceChannel.STATIC_QR,
    AcceptanceChannel.DYNAMIC_QR,
    AcceptanceChannel.PAYMENT_LINK,
    AcceptanceChannel.INVOICE,
    AcceptanceChannel.REMOTE_CHECKOUT,
    AcceptanceChannel.POS,
    AcceptanceChannel.WALLET,
    AcceptanceChannel.MOBILE_MONEY,
    AcceptanceChannel.CARD,
]


def ensure_profile(
    *,
    merchant: Merchant,
    display_name: str = "",
    actor: str = "",
) -> AcceptanceProfile:
    profile, created = AcceptanceProfile.objects.get_or_create(
        merchant=merchant,
        defaults={
            "display_name": display_name
            or merchant.trading_name
            or merchant.legal_name,
            "default_currency": merchant.settlement_currency or "TZS",
            "accepted_methods": list(DEFAULT_METHODS),
        },
    )
    if created:
        metrics.profiles_created.inc()
    return profile


def _sign_intent(intent: AcceptanceIntent) -> str:
    exp = int(intent.expires_at.timestamp()) if intent.expires_at else None
    return security.sign_payload(
        [
            intent.public_code,
            intent.merchant.code,
            intent.amount_minor,
            intent.currency,
            intent.channel,
            exp,
        ]
    )


def create_intent(
    *,
    merchant: Merchant,
    amount_minor: int,
    channel: str,
    currency: str = "TZS",
    description: str = "",
    ttl_minutes: int | None = 60,
    max_uses: int = 1,
    metadata: dict | None = None,
    sales_order_id=None,
    winga_deal_id=None,
    trip_id=None,
    invoice_id=None,
    created_by: str = "",
) -> AcceptanceIntent:
    if merchant.status != MerchantStatus.ACTIVE:
        raise MapError("merchant not active")
    amount_minor = int(amount_minor)
    if amount_minor <= 0:
        raise MapError("amount_minor must be positive")
    profile = ensure_profile(merchant=merchant)
    if profile.accepted_methods and channel not in profile.accepted_methods:
        # SoftPOS / NFC always allowed as future-ready when listed in request
        if channel not in (
            AcceptanceChannel.SOFTPOS,
            AcceptanceChannel.NFC,
            AcceptanceChannel.WINGA,
            AcceptanceChannel.MOBILITY,
            AcceptanceChannel.COMMERCE_ORDER,
        ):
            raise MapError(f"channel {channel} not enabled for merchant")

    expires_at = None
    if ttl_minutes is not None and ttl_minutes > 0:
        expires_at = timezone.now() + timedelta(minutes=ttl_minutes)

    intent = AcceptanceIntent(
        profile=profile,
        merchant=merchant,
        channel=channel,
        status=IntentStatus.OPEN,
        amount_minor=amount_minor,
        currency=currency or profile.default_currency,
        description=description,
        metadata=metadata or {},
        sales_order_id=sales_order_id,
        winga_deal_id=winga_deal_id,
        trip_id=trip_id,
        invoice_id=invoice_id,
        expires_at=expires_at,
        max_uses=max_uses,
        created_by=created_by,
    )
    intent.save()  # assign public_code before signing
    intent.signature = _sign_intent(intent)
    intent.save(update_fields=["signature", "updated_at"])
    metrics.intents_created.labels(channel=channel).inc()
    return intent


def issue_qr(
    *,
    merchant: Merchant,
    kind: str = QrKind.DYNAMIC,
    amount_minor: int | None = None,
    currency: str = "TZS",
    description: str = "",
    ttl_minutes: int | None = 60,
    branch_ref: str = "",
    terminal_ref: str = "",
    created_by: str = "",
) -> tuple[QrArtifact, AcceptanceIntent | None]:
    profile = ensure_profile(merchant=merchant)
    intent = None
    channel = (
        AcceptanceChannel.STATIC_QR
        if kind == QrKind.STATIC
        else AcceptanceChannel.DYNAMIC_QR
    )

    if amount_minor is not None:
        amount_minor = int(amount_minor)
    if kind == QrKind.STATIC and amount_minor is None:
        # Static merchant QR — amount collected at scan time via follow-up intent
        payload_base_code = profile.qr_identity
        currency_code = currency or profile.default_currency
        canonical = security.qr_canonical(
            merchant_code=merchant.code,
            public_code=payload_base_code,
            amount_minor=None,
            currency=currency_code,
            intent_code=None,
            expires_epoch=None,
        )
        sig = security.sign_payload(
            [merchant.code, payload_base_code, "", currency_code, "", ""]
        )
        qr, _created = QrArtifact.objects.update_or_create(
            merchant=merchant,
            public_code=payload_base_code,
            defaults={
                "profile": profile,
                "kind": kind,
                "intent": None,
                "branch_ref": branch_ref,
                "terminal_ref": terminal_ref,
                "payload": f"{canonical}&s={sig}",
                "signature": sig,
                "expires_at": None,
                "active": True,
                "metadata": {"static": True},
            },
        )
        metrics.qr_issued.labels(kind=kind).inc()
        return qr, None

    if amount_minor is None or amount_minor <= 0:
        raise MapError("dynamic QR requires amount_minor")

    intent = create_intent(
        merchant=merchant,
        amount_minor=amount_minor,
        channel=channel,
        currency=currency,
        description=description or f"QR {kind}",
        ttl_minutes=ttl_minutes,
        created_by=created_by,
    )
    exp_epoch = int(intent.expires_at.timestamp()) if intent.expires_at else None
    canonical = security.qr_canonical(
        merchant_code=merchant.code,
        public_code=intent.public_code,
        amount_minor=intent.amount_minor,
        currency=intent.currency,
        intent_code=intent.public_code,
        expires_epoch=exp_epoch,
    )
    sig = intent.signature
    qr = QrArtifact.objects.create(
        profile=profile,
        merchant=merchant,
        kind=kind,
        intent=intent,
        branch_ref=branch_ref,
        terminal_ref=terminal_ref,
        payload=f"{canonical}&s={sig}",
        signature=sig,
        expires_at=intent.expires_at,
        metadata={"description": description},
    )
    metrics.qr_issued.labels(kind=kind).inc()
    return qr, intent


def create_payment_link(
    *,
    merchant: Merchant,
    amount_minor: int,
    purpose: str = LinkPurpose.GENERAL,
    currency: str = "TZS",
    description: str = "",
    ttl_minutes: int | None = 1440,
    max_uses: int = 1,
    branding: dict | None = None,
    created_by: str = "",
    sales_order_id=None,
    winga_deal_id=None,
) -> PaymentLink:
    intent = create_intent(
        merchant=merchant,
        amount_minor=amount_minor,
        channel=AcceptanceChannel.PAYMENT_LINK,
        currency=currency,
        description=description or f"Link:{purpose}",
        ttl_minutes=ttl_minutes,
        max_uses=max_uses,
        sales_order_id=sales_order_id,
        winga_deal_id=winga_deal_id,
        created_by=created_by,
    )
    profile = intent.profile
    link = PaymentLink(
        profile=profile,
        merchant=merchant,
        intent=intent,
        purpose=purpose,
        signature=intent.signature,
        expires_at=intent.expires_at,
        max_uses=max_uses,
        branding=branding or profile.branding or {},
    )
    link.save()
    metrics.links_created.inc()
    return link


def create_invoice(
    *,
    merchant: Merchant,
    invoice_number: str,
    amount_minor: int,
    line_items: list | None = None,
    currency: str = "TZS",
    customer_name: str = "",
    customer_ref: str = "",
    allow_partial: bool = False,
    installment_plan: dict | None = None,
    due_at=None,
    created_by: str = "",
) -> tuple[DigitalInvoice, AcceptanceIntent, QrArtifact]:
    if not invoice_number:
        raise MapError("invoice_number required")
    profile = ensure_profile(merchant=merchant)
    if DigitalInvoice.objects.filter(
        merchant=merchant, invoice_number=invoice_number
    ).exists():
        raise MapError("invoice_number already exists")

    inv = DigitalInvoice.objects.create(
        profile=profile,
        merchant=merchant,
        invoice_number=invoice_number,
        customer_name=customer_name,
        customer_ref=customer_ref,
        line_items=line_items or [],
        amount_minor=amount_minor,
        currency=currency,
        allow_partial=allow_partial,
        installment_plan=installment_plan or {},
        due_at=due_at,
        status=IntentStatus.OPEN,
    )
    pay_amount = amount_minor if not allow_partial else amount_minor
    intent = create_intent(
        merchant=merchant,
        amount_minor=pay_amount,
        channel=AcceptanceChannel.INVOICE,
        currency=currency,
        description=f"Invoice {invoice_number}",
        ttl_minutes=None if due_at else 60 * 24 * 30,
        max_uses=99 if allow_partial else 1,
        invoice_id=inv.id,
        created_by=created_by,
    )
    if due_at:
        intent.expires_at = due_at
        intent.signature = _sign_intent(intent)
        intent.save(update_fields=["expires_at", "signature", "updated_at"])

    exp_epoch = int(intent.expires_at.timestamp()) if intent.expires_at else None
    canonical = security.qr_canonical(
        merchant_code=merchant.code,
        public_code=intent.public_code,
        amount_minor=intent.amount_minor,
        currency=intent.currency,
        intent_code=intent.public_code,
        expires_epoch=exp_epoch,
    )
    qr = QrArtifact.objects.create(
        profile=profile,
        merchant=merchant,
        kind=QrKind.INVOICE,
        intent=intent,
        payload=f"{canonical}&s={intent.signature}",
        signature=intent.signature,
        expires_at=intent.expires_at,
        metadata={"invoice_number": invoice_number},
    )
    metrics.qr_issued.labels(kind=QrKind.INVOICE).inc()
    metrics.invoices_created.inc()
    return inv, intent, qr


def create_checkout(
    *,
    merchant: Merchant,
    amount_minor: int,
    mode: str = "mobile",
    currency: str = "TZS",
    description: str = "",
    return_url: str = "",
    cancel_url: str = "",
    ttl_minutes: int | None = 30,
    sales_order_id=None,
    winga_deal_id=None,
    trip_id=None,
    created_by: str = "",
) -> CheckoutSession:
    intent = create_intent(
        merchant=merchant,
        amount_minor=amount_minor,
        channel=AcceptanceChannel.REMOTE_CHECKOUT,
        currency=currency,
        description=description or "Checkout",
        ttl_minutes=ttl_minutes,
        sales_order_id=sales_order_id,
        winga_deal_id=winga_deal_id,
        trip_id=trip_id,
        created_by=created_by,
    )
    session = CheckoutSession.objects.create(
        profile=intent.profile,
        merchant=merchant,
        intent=intent,
        mode=mode,
        return_url=return_url,
        cancel_url=cancel_url,
        status=IntentStatus.OPEN,
        expires_at=intent.expires_at,
    )
    metrics.checkouts_created.inc()
    return session


def register_terminal(
    *,
    merchant: Merchant,
    code: str,
    kind: str = TerminalKind.POS,
    label: str = "",
    branch_ref: str = "",
    softpos_ready: bool = False,
    nfc_ready: bool = False,
) -> AcceptanceTerminal:
    import secrets

    profile = ensure_profile(merchant=merchant)
    existing = AcceptanceTerminal.objects.filter(merchant=merchant, code=code).first()
    pairing = (existing.pairing_token if existing and existing.pairing_token else secrets.token_urlsafe(12))
    term, _ = AcceptanceTerminal.objects.update_or_create(
        merchant=merchant,
        code=code,
        defaults={
            "profile": profile,
            "kind": kind,
            "label": label or code,
            "branch_ref": branch_ref,
            "softpos_ready": softpos_ready,
            "nfc_ready": nfc_ready,
            "active": True,
            "pairing_token": pairing,
        },
    )
    return term


def resolve_intent(public_code: str) -> AcceptanceIntent:
    intent = AcceptanceIntent.objects.select_related("merchant", "profile").filter(
        public_code=public_code
    ).first()
    if intent is None:
        raise MapError("intent not found")
    return intent


def validate_intent_for_pay(intent: AcceptanceIntent) -> None:
    if intent.status in (IntentStatus.CANCELLED, IntentStatus.FAILED):
        raise MapError("intent not payable")
    if intent.status == IntentStatus.PAID and intent.use_count >= intent.max_uses:
        raise MapError("intent already paid")
    if intent.is_expired:
        if intent.status != IntentStatus.EXPIRED:
            intent.status = IntentStatus.EXPIRED
            intent.save(update_fields=["status", "updated_at"])
        raise MapError("intent expired")
    if not security.verify_signature(
        [
            intent.public_code,
            intent.merchant.code,
            intent.amount_minor,
            intent.currency,
            intent.channel,
            int(intent.expires_at.timestamp()) if intent.expires_at else None,
        ],
        intent.signature,
    ):
        raise MapError("intent signature invalid")
    if intent.merchant.status != MerchantStatus.ACTIVE:
        raise MapError("merchant not active")


@transaction.atomic
def pay_intent(
    *,
    intent: AcceptanceIntent,
    payer_principal: str,
    idempotency_key: str,
    amount_minor: int | None = None,
    actor: str = "",
) -> tuple[AcceptanceIntent, AcceptanceReceipt]:
    """Fulfill acceptance intent via Payments Platform — no MAP ledger."""
    validate_intent_for_pay(intent)
    pay_amount = amount_minor if amount_minor is not None else intent.remaining_minor
    if pay_amount <= 0:
        raise MapError("nothing to pay")
    if pay_amount > intent.remaining_minor:
        raise MapError("amount exceeds remaining")

    # Invoice partial rules
    if intent.invoice_id:
        inv = DigitalInvoice.objects.select_for_update().filter(id=intent.invoice_id).first()
        if inv and not inv.allow_partial and pay_amount != inv.remaining_minor:
            raise MapError("partial payment not allowed on this invoice")

    intent.status = IntentStatus.PROCESSING
    intent.save(update_fields=["status", "updated_at"])

    currency = Currency.from_code(intent.currency or "TZS")
    try:
        txn = PlatformOrchestrator().capture_merchant_payment(
            ctx=PlatformContext(actor=actor or payer_principal),
            merchant=intent.merchant,
            payer_owner=payer_principal,
            amount=Money(pay_amount, currency),
            idempotency_key=idempotency_key,
            note=f"map:{intent.channel}:{intent.public_code}",
        )
    except PlatformError as exc:
        intent.status = IntentStatus.FAILED
        intent.save(update_fields=["status", "updated_at"])
        metrics.payments_failed.labels(channel=intent.channel).inc()
        raise MapError(str(exc)) from exc

    intent.amount_paid_minor = int(intent.amount_paid_minor) + pay_amount
    intent.use_count = int(intent.use_count) + 1
    intent.payment_ref = str(txn.id)
    intent.payer_principal = payer_principal
    intent.paid_at = timezone.now()
    if intent.amount_paid_minor >= intent.amount_minor:
        intent.status = IntentStatus.PAID
    else:
        intent.status = IntentStatus.PARTIALLY_PAID
    intent.save()

    if intent.invoice_id:
        inv = DigitalInvoice.objects.filter(id=intent.invoice_id).first()
        if inv:
            inv.amount_paid_minor = int(inv.amount_paid_minor) + pay_amount
            if inv.amount_paid_minor >= inv.amount_minor:
                inv.status = IntentStatus.PAID
            else:
                inv.status = IntentStatus.PARTIALLY_PAID
            inv.save(update_fields=["amount_paid_minor", "status", "updated_at"])

    receipt = _issue_receipt(intent=intent, payment_ref=str(txn.id), amount_minor=pay_amount)
    metrics.payments_succeeded.labels(channel=intent.channel).inc()
    return intent, receipt


def _issue_receipt(
    *, intent: AcceptanceIntent, payment_ref: str, amount_minor: int
) -> AcceptanceReceipt:
    profile = intent.profile
    prefs = profile.receipt_preferences or {}
    delivery = prefs.get("channels") or ["digital", "wallet"]
    body: dict[str, Any] = {
        "intent": intent.public_code,
        "channel": intent.channel,
        "description": intent.description,
        "merchant_code": intent.merchant.code,
        "paid_at": intent.paid_at.isoformat() if intent.paid_at else None,
        "payment_ref": payment_ref,
    }
    verification = security.sign_payload(
        [payment_ref, intent.public_code, amount_minor, intent.currency]
    )
    receipt = AcceptanceReceipt.objects.create(
        intent=intent,
        merchant=intent.merchant,
        payment_ref=payment_ref,
        amount_minor=amount_minor,
        currency=intent.currency,
        channel=intent.channel,
        merchant_display=profile.display_name,
        payer_principal=intent.payer_principal,
        delivery=delivery,
        verification_qr=f"taifa://receipt/{payment_ref}?v={verification}",
        body=body,
    )
    metrics.receipts_issued.inc()
    return receipt


def analytics_summary(*, merchant: Merchant) -> dict[str, Any]:
    profile = AcceptanceProfile.objects.filter(merchant=merchant).first()
    intents = AcceptanceIntent.objects.filter(merchant=merchant)
    paid = intents.filter(status__in=[IntentStatus.PAID, IntentStatus.PARTIALLY_PAID])
    by_channel: dict[str, int] = {}
    for row in paid.values_list("channel", flat=True):
        by_channel[row] = by_channel.get(row, 0) + 1
    gmv = sum(paid.values_list("amount_paid_minor", flat=True)) or 0
    return {
        "merchant_id": str(merchant.id),
        "merchant_code": merchant.code,
        "profile_active": bool(profile and profile.active),
        "intents_total": intents.count(),
        "intents_paid": paid.count(),
        "gmv_minor": gmv,
        "qr_count": QrArtifact.objects.filter(merchant=merchant).count(),
        "links_count": PaymentLink.objects.filter(merchant=merchant).count(),
        "invoices_open": DigitalInvoice.objects.filter(
            merchant=merchant, status=IntentStatus.OPEN
        ).count(),
        "checkouts_open": CheckoutSession.objects.filter(
            merchant=merchant, status=IntentStatus.OPEN
        ).count(),
        "terminals": AcceptanceTerminal.objects.filter(
            merchant=merchant, active=True
        ).count(),
        "channel_mix": by_channel,
        "accepted_methods": (profile.accepted_methods if profile else DEFAULT_METHODS),
    }


def pay_from_static_qr(
    *,
    merchant: Merchant,
    amount_minor: int,
    payer_principal: str,
    idempotency_key: str,
    currency: str = "TZS",
    actor: str = "",
) -> tuple[AcceptanceIntent, AcceptanceReceipt]:
    """Customer entered amount against static merchant QR."""
    intent = create_intent(
        merchant=merchant,
        amount_minor=amount_minor,
        channel=AcceptanceChannel.STATIC_QR,
        currency=currency,
        description="Static QR payment",
        ttl_minutes=15,
        created_by=payer_principal,
    )
    return pay_intent(
        intent=intent,
        payer_principal=payer_principal,
        idempotency_key=idempotency_key,
        actor=actor,
    )
