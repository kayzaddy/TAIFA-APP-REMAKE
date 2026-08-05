"""Taifa Merchant Acceptance Platform (MAP) models.

Control-plane only. Money truth = payments ledger via enterprise capture.
Never stores merchant balances, settlements, or a second ledger.
"""
from __future__ import annotations

import secrets
import uuid

from django.db import models
from django.utils import timezone


class AcceptanceChannel(models.TextChoices):
    STATIC_QR = "static_qr"
    DYNAMIC_QR = "dynamic_qr"
    PAYMENT_LINK = "payment_link"
    INVOICE = "invoice"
    REMOTE_CHECKOUT = "remote_checkout"
    POS = "pos"
    SOFTPOS = "softpos"
    NFC = "nfc"
    WALLET = "wallet"
    MOBILE_MONEY = "mobile_money"
    CARD = "card"
    WINGA = "winga"
    MOBILITY = "mobility"
    COMMERCE_ORDER = "commerce_order"
    OTHER = "other"


class IntentStatus(models.TextChoices):
    DRAFT = "draft"
    OPEN = "open"
    PROCESSING = "processing"
    PAID = "paid"
    PARTIALLY_PAID = "partially_paid"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    FAILED = "failed"


class QrKind(models.TextChoices):
    STATIC = "static"
    DYNAMIC = "dynamic"
    MERCHANT = "merchant"
    BRANCH = "branch"
    TERMINAL = "terminal"
    INVOICE = "invoice"
    ORDER = "order"
    CAMPAIGN = "campaign"
    OFFLINE = "offline"


class LinkPurpose(models.TextChoices):
    INVOICE = "invoice"
    ORDER = "order"
    BOOKING = "booking"
    RESERVATION = "reservation"
    DEPOSIT = "deposit"
    SUBSCRIPTION = "subscription"
    DONATION = "donation"
    CAMPAIGN = "campaign"
    GENERAL = "general"


class TerminalKind(models.TextChoices):
    POS = "pos"
    SOFTPOS = "softpos"
    VIRTUAL = "virtual"
    NFC_READER = "nfc_reader"


class ReceiptDelivery(models.TextChoices):
    DIGITAL = "digital"
    SMS = "sms"
    EMAIL = "email"
    WALLET = "wallet"
    PRINT = "print"
    PDF = "pdf"


def _public_code(prefix: str, nbytes: int = 8) -> str:
    return f"{prefix}_{secrets.token_urlsafe(nbytes)}"


class AcceptanceProfile(models.Model):
    """Merchant acceptance configuration — FK to enterprise.Merchant only."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.OneToOneField(
        "enterprise.Merchant",
        on_delete=models.CASCADE,
        related_name="acceptance_profile",
    )
    display_name = models.CharField(max_length=255, blank=True, default="")
    logo_url = models.URLField(blank=True, default="")
    default_currency = models.CharField(max_length=8, default="TZS")
    accepted_methods = models.JSONField(
        default=list,
        blank=True,
        help_text="Channel codes enabled for this merchant",
    )
    receipt_preferences = models.JSONField(default=dict, blank=True)
    branding = models.JSONField(default=dict, blank=True)
    branch_config = models.JSONField(default=dict, blank=True)
    store_config = models.JSONField(default=dict, blank=True)
    terminal_config = models.JSONField(default=dict, blank=True)
    qr_identity = models.CharField(max_length=64, unique=True, db_index=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["active", "qr_identity"])]

    def __str__(self) -> str:
        return f"MAP:{self.display_name or self.merchant.code}"

    def save(self, *args, **kwargs):
        if not self.qr_identity:
            self.qr_identity = _public_code("mqr", 6)
        if not self.accepted_methods:
            self.accepted_methods = [
                AcceptanceChannel.STATIC_QR,
                AcceptanceChannel.DYNAMIC_QR,
                AcceptanceChannel.PAYMENT_LINK,
                AcceptanceChannel.INVOICE,
                AcceptanceChannel.REMOTE_CHECKOUT,
                AcceptanceChannel.POS,
                AcceptanceChannel.WALLET,
            ]
        if not self.display_name:
            self.display_name = self.merchant.trading_name or self.merchant.legal_name
        super().save(*args, **kwargs)


class AcceptanceIntent(models.Model):
    """Payment Intent owned by MAP — processing delegated to Payments Platform."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    profile = models.ForeignKey(
        AcceptanceProfile, on_delete=models.CASCADE, related_name="intents"
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.PROTECT, related_name="acceptance_intents"
    )
    channel = models.CharField(max_length=32, choices=AcceptanceChannel.choices)
    status = models.CharField(
        max_length=24, choices=IntentStatus.choices, default=IntentStatus.OPEN
    )
    amount_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    amount_paid_minor = models.PositiveBigIntegerField(default=0)
    description = models.CharField(max_length=512, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    # Integration refs (optional — never money state)
    sales_order_id = models.UUIDField(null=True, blank=True, db_index=True)
    winga_deal_id = models.UUIDField(null=True, blank=True, db_index=True)
    trip_id = models.UUIDField(null=True, blank=True, db_index=True)
    invoice_id = models.UUIDField(null=True, blank=True, db_index=True)
    # Security
    signature = models.CharField(max_length=128, blank=True, default="")
    expires_at = models.DateTimeField(null=True, blank=True)
    max_uses = models.PositiveIntegerField(default=1)
    use_count = models.PositiveIntegerField(default=0)
    # Result from Payments Platform (ledger-backed)
    payment_ref = models.CharField(max_length=64, blank=True, default="", db_index=True)
    payer_principal = models.CharField(max_length=128, blank=True, default="")
    paid_at = models.DateTimeField(null=True, blank=True)
    created_by = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["merchant", "status"]),
            models.Index(fields=["channel", "status"]),
        ]

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _public_code("pi", 10)
        super().save(*args, **kwargs)

    @property
    def is_expired(self) -> bool:
        return bool(self.expires_at and timezone.now() >= self.expires_at)

    @property
    def remaining_minor(self) -> int:
        return max(0, int(self.amount_minor) - int(self.amount_paid_minor))


class QrArtifact(models.Model):
    """QR presentation artifact — payload signed; money via linked intent or profile."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        AcceptanceProfile, on_delete=models.CASCADE, related_name="qr_codes"
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.CASCADE, related_name="map_qr_codes"
    )
    kind = models.CharField(max_length=24, choices=QrKind.choices, default=QrKind.DYNAMIC)
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    intent = models.ForeignKey(
        AcceptanceIntent,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="qr_codes",
    )
    branch_ref = models.CharField(max_length=64, blank=True, default="")
    terminal_ref = models.CharField(max_length=64, blank=True, default="")
    payload = models.TextField(help_text="Canonical QR payload string")
    signature = models.CharField(max_length=128)
    expires_at = models.DateTimeField(null=True, blank=True)
    active = models.BooleanField(default=True)
    scan_count = models.PositiveIntegerField(default=0)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _public_code("qr", 8)
        super().save(*args, **kwargs)


class PaymentLink(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        AcceptanceProfile, on_delete=models.CASCADE, related_name="payment_links"
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.CASCADE, related_name="map_payment_links"
    )
    intent = models.ForeignKey(
        AcceptanceIntent, on_delete=models.CASCADE, related_name="payment_links"
    )
    purpose = models.CharField(
        max_length=24, choices=LinkPurpose.choices, default=LinkPurpose.GENERAL
    )
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    path_token = models.CharField(max_length=64, unique=True, db_index=True)
    signature = models.CharField(max_length=128)
    expires_at = models.DateTimeField(null=True, blank=True)
    max_uses = models.PositiveIntegerField(default=1)
    use_count = models.PositiveIntegerField(default=0)
    branding = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _public_code("pl", 8)
        if not self.path_token:
            self.path_token = secrets.token_urlsafe(16)
        super().save(*args, **kwargs)


class DigitalInvoice(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        AcceptanceProfile, on_delete=models.CASCADE, related_name="invoices"
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.CASCADE, related_name="map_invoices"
    )
    invoice_number = models.CharField(max_length=64, db_index=True)
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    customer_name = models.CharField(max_length=255, blank=True, default="")
    customer_ref = models.CharField(max_length=128, blank=True, default="")
    line_items = models.JSONField(default=list, blank=True)
    amount_minor = models.PositiveBigIntegerField()
    amount_paid_minor = models.PositiveBigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    allow_partial = models.BooleanField(default=False)
    installment_plan = models.JSONField(default=dict, blank=True)
    due_at = models.DateTimeField(null=True, blank=True)
    status = models.CharField(
        max_length=24, choices=IntentStatus.choices, default=IntentStatus.OPEN
    )
    reminder_count = models.PositiveIntegerField(default=0)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [("merchant", "invoice_number")]

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _public_code("inv", 8)
        super().save(*args, **kwargs)

    @property
    def remaining_minor(self) -> int:
        return max(0, int(self.amount_minor) - int(self.amount_paid_minor))


class CheckoutSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        AcceptanceProfile, on_delete=models.CASCADE, related_name="checkouts"
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.CASCADE, related_name="map_checkouts"
    )
    intent = models.ForeignKey(
        AcceptanceIntent, on_delete=models.CASCADE, related_name="checkouts"
    )
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    mode = models.CharField(
        max_length=24,
        default="mobile",
        help_text="web | mobile | embedded | share",
    )
    return_url = models.URLField(blank=True, default="")
    cancel_url = models.URLField(blank=True, default="")
    status = models.CharField(
        max_length=24, choices=IntentStatus.choices, default=IntentStatus.OPEN
    )
    expires_at = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _public_code("cs", 8)
        super().save(*args, **kwargs)


class AcceptanceTerminal(models.Model):
    """POS / SoftPOS / NFC terminal registry — acceptance UX only."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    profile = models.ForeignKey(
        AcceptanceProfile, on_delete=models.CASCADE, related_name="terminals"
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.CASCADE, related_name="map_terminals"
    )
    code = models.CharField(max_length=64)
    label = models.CharField(max_length=128, blank=True, default="")
    kind = models.CharField(
        max_length=24, choices=TerminalKind.choices, default=TerminalKind.POS
    )
    branch_ref = models.CharField(max_length=64, blank=True, default="")
    pairing_token = models.CharField(max_length=64, blank=True, default="")
    device_attestation = models.JSONField(default=dict, blank=True)
    softpos_ready = models.BooleanField(default=False)
    nfc_ready = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    last_seen_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("merchant", "code")]


class AcceptanceReceipt(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    intent = models.ForeignKey(
        AcceptanceIntent, on_delete=models.CASCADE, related_name="receipts"
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.CASCADE, related_name="map_receipts"
    )
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    payment_ref = models.CharField(max_length=64, db_index=True)
    amount_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    channel = models.CharField(max_length=32)
    merchant_display = models.CharField(max_length=255)
    payer_principal = models.CharField(max_length=128, blank=True, default="")
    delivery = models.JSONField(default=list, blank=True)
    verification_qr = models.TextField(blank=True, default="")
    body = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _public_code("rcpt", 8)
        super().save(*args, **kwargs)


class FundingSourceKind(models.TextChoices):
    WALLET = "wallet"
    MOBILE_MONEY = "mobile_money"
    BANK = "bank"
    CARD = "card"
    EMPLOYER = "employer"
    GIFT = "gift"
    GOVERNMENT = "government"
    CBDC = "cbdc"
    OTHER = "other"


class AuthPolicy(models.TextChoices):
    ALWAYS = "always"
    RISK_BASED = "risk_based"
    LOW_FRICTION = "low_friction"
    PIN_ONLY = "pin_only"
    BIOMETRIC_PREFERRED = "biometric_preferred"


class TapSessionStatus(models.TextChoices):
    DETECTED = "detected"
    AUTH_REQUIRED = "auth_required"
    AUTHORIZING = "authorizing"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    EXPIRED = "expired"
    CANCELLED = "cancelled"
    FALLBACK = "fallback"


class WalletFundingPreference(models.Model):
    """User funding priority — control plane only; no balances."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner_principal = models.CharField(max_length=128, unique=True, db_index=True)
    priority = models.JSONField(
        default=list,
        blank=True,
        help_text="Ordered list of {kind, ref, label, enabled, confirm}",
    )
    auto_route = models.BooleanField(default=True)
    require_confirmation = models.BooleanField(default=False)
    auth_policy = models.CharField(
        max_length=32, choices=AuthPolicy.choices, default=AuthPolicy.RISK_BASED
    )
    low_risk_threshold_minor = models.PositiveBigIntegerField(
        default=50_000, help_text="Below this, risk-based auth may skip step-up"
    )
    merchant_overrides = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"funding:{self.owner_principal}"


class TapSession(models.Model):
    """NFC / SoftPOS tap lifecycle — money only via linked AcceptanceIntent."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    merchant = models.ForeignKey(
        "enterprise.Merchant", on_delete=models.PROTECT, related_name="tap_sessions"
    )
    intent = models.ForeignKey(
        AcceptanceIntent,
        on_delete=models.PROTECT,
        related_name="tap_sessions",
        null=True,
        blank=True,
    )
    terminal = models.ForeignKey(
        AcceptanceTerminal,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="tap_sessions",
    )
    channel = models.CharField(
        max_length=32,
        choices=AcceptanceChannel.choices,
        default=AcceptanceChannel.NFC,
    )
    status = models.CharField(
        max_length=24, choices=TapSessionStatus.choices, default=TapSessionStatus.DETECTED
    )
    amount_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    payer_principal = models.CharField(max_length=128, blank=True, default="", db_index=True)
    selected_funding = models.JSONField(default=dict, blank=True)
    auth_required = models.BooleanField(default=True)
    auth_method = models.CharField(max_length=32, blank=True, default="")
    auth_completed = models.BooleanField(default=False)
    merchant_display = models.CharField(max_length=255, blank=True, default="")
    terminal_capability = models.JSONField(default=dict, blank=True)
    nfc_meta = models.JSONField(default=dict, blank=True)
    failure_reason = models.CharField(max_length=255, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    receipt_code = models.CharField(max_length=48, blank=True, default="")
    expires_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["payer_principal", "status"]),
            models.Index(fields=["merchant", "status"]),
        ]

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _public_code("tap", 10)
        super().save(*args, **kwargs)
