"""Database schema for the payment service.

The ledger tables (`LedgerEntry`, `Posting`) are **append-only**: once written
they are never mutated. Balances are always the sum of immutable postings, which
makes the system auditable and reconstructable. This mirrors the Dart domain in
`apps/mobile/lib/features/wallet/domain/`.
"""
from __future__ import annotations

import uuid

from django.db import models

from .money import Currency, Money

CURRENCY_CHOICES = [(c.code, c.currency_name) for c in Currency]


class AppendOnly(models.Model):
    """Base for immutable records: updates after creation are rejected."""

    class Meta:
        abstract = True

    def save(self, *args, **kwargs):
        if not self._state.adding:
            raise ValueError(f"{type(self).__name__} is append-only and cannot be modified.")
        super().save(*args, **kwargs)


class LedgerAccountType(models.TextChoices):
    # --- Assets ---
    TREASURY = "treasury"
    PROVIDER_SETTLEMENT = "provider_settlement"
    SETTLEMENT_PENDING = "settlement_pending"
    CASH_IN_TRANSIT = "cash_in_transit"
    WALLET_CLEARING = "wallet_clearing"
    EXTERNAL_MOBILE_MONEY = "external_mobile_money"
    EXTERNAL_BANK = "external_bank"
    CRYPTO_VAULT = "crypto_vault"
    # --- Liabilities ---
    USER_WALLET = "user_wallet"
    FUNDS_ON_HOLD = "funds_on_hold"
    MERCHANT_PAYABLE = "merchant_payable"
    TAX_PAYABLE = "tax_payable"
    PROVIDER_PAYABLE = "provider_payable"
    FEES_PAYABLE = "fees_payable"
    # --- Revenue ---
    FEE_INCOME = "fee_income"
    COMMISSION_INCOME = "commission_income"
    FX_GAIN = "fx_gain"
    # --- Expenses ---
    FX_LOSS = "fx_loss"
    CHARGEBACK_EXPENSE = "chargeback_expense"
    FRAUD_LOSS = "fraud_loss"
    # --- Reserves ---
    CHARGEBACK_RESERVE = "chargeback_reserve"
    LIQUIDITY_RESERVE = "liquidity_reserve"
    # --- Suspense ---
    SUSPENSE = "suspense"
    UNKNOWN_CREDITS = "unknown_credits"
    UNKNOWN_DEBITS = "unknown_debits"


class LedgerAccount(models.Model):
    """A named account money can be posted against. `id` is a stable natural key
    (e.g. `user:amani:wallet:TZS`)."""

    id = models.CharField(primary_key=True, max_length=128)
    account_type = models.CharField(max_length=32, choices=LedgerAccountType.choices)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    owner = models.CharField(max_length=128, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["owner"]), models.Index(fields=["account_type"])]

    def __str__(self) -> str:
        return self.id


class TransactionType(models.TextChoices):
    SEND_MONEY = "send_money"
    RECEIVE_MONEY = "receive_money"
    BILL_PAYMENT = "bill_payment"
    TOP_UP = "top_up"
    WITHDRAWAL = "withdrawal"
    MERCHANT_PAYMENT = "merchant_payment"
    REFUND = "refund"
    REVERSAL = "reversal"
    CHARGEBACK = "chargeback"
    RIDE_FARE = "ride_fare"
    TREASURY_TRANSFER = "treasury_transfer"
    MERCHANT_SETTLEMENT = "merchant_settlement"
    FEE_COLLECTION = "fee_collection"
    TAX_POSTING = "tax_posting"


class TransactionStatus(models.TextChoices):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    PROCESSING = "processing"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    CANCELLED = "cancelled"
    REVERSED = "reversed"


class LedgerEntryKind(models.TextChoices):
    OPENING = "opening"
    SETTLE = "settle"
    HOLD = "hold"
    RELEASE = "release"
    REFUND = "refund"
    REVERSAL = "reversal"
    ADJUSTMENT = "adjustment"
    MERCHANT_CAPTURE = "merchant_capture"
    MERCHANT_PAYOUT = "merchant_payout"
    CHARGEBACK = "chargeback"
    TREASURY = "treasury"
    FEE = "fee"
    TAX = "tax"
    COMMISSION = "commission"
    RESERVE = "reserve"


class TransactionDirection(models.TextChoices):
    CREDIT = "credit"
    DEBIT = "debit"


class Transaction(models.Model):
    """User-facing record. Mutable status field is intentionally *not* on the
    ledger — the ledger stays immutable; the transaction tracks lifecycle state
    and links to the ledger entry that actually moved the money."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    # The wallet owner (the authenticated principal). Every read/write is scoped
    # to this so a device can only ever see and move its own money.
    owner = models.CharField(max_length=128, db_index=True, default="")
    type = models.CharField(max_length=32, choices=TransactionType.choices)
    status = models.CharField(max_length=16, choices=TransactionStatus.choices, default=TransactionStatus.PENDING)
    direction = models.CharField(max_length=8, choices=TransactionDirection.choices)

    amount_minor = models.BigIntegerField()
    fee_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)

    counterparty = models.CharField(max_length=255)

    # Denormalised payment method (the server does not need the full instrument).
    method_kind = models.CharField(max_length=24)  # mobile_money | card | bank | wallet
    method_label = models.CharField(max_length=128, blank=True, default="")
    method_ref = models.CharField(max_length=128, blank=True, default="")  # msisdn / last4
    operator = models.CharField(max_length=32, blank=True, default="")

    idempotency_key = models.CharField(max_length=128, db_index=True)
    note = models.TextField(blank=True, default="")

    provider = models.CharField(max_length=32, blank=True, default="")
    provider_ref = models.CharField(max_length=128, blank=True, default="", db_index=True)

    # Refunds / reversals / chargebacks point at the original money movement.
    parent = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="children",
    )

    ledger_entry = models.OneToOneField(
        "LedgerEntry", null=True, blank=True, on_delete=models.PROTECT, related_name="transaction_ref"
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["status"]),
            models.Index(fields=["type"]),
            models.Index(fields=["owner", "-created_at"]),
            models.Index(fields=["parent"]),
        ]

    @property
    def amount(self) -> Money:
        return Money(self.amount_minor, Currency.from_code(self.currency))

    @property
    def fee(self) -> Money:
        return Money(self.fee_minor, Currency.from_code(self.currency))

    def __str__(self) -> str:
        return f"{self.type} {self.amount} [{self.status}]"


class LedgerEntry(AppendOnly):
    """An immutable double-entry record. Its postings must net to zero per
    currency — enforced by the ledger service on creation."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    transaction = models.ForeignKey(Transaction, on_delete=models.PROTECT, related_name="ledger_entries")
    description = models.CharField(max_length=255)
    kind = models.CharField(
        max_length=16,
        choices=LedgerEntryKind.choices,
        default=LedgerEntryKind.SETTLE,
        db_index=True,
    )
    # Compensating entries point at the journal they reverse (never mutate it).
    reverses = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="reversed_by",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self) -> str:
        return f"LedgerEntry {self.id} ({self.kind}: {self.description})"


class PostingDirection(models.TextChoices):
    DEBIT = "debit"
    CREDIT = "credit"


class Posting(AppendOnly):
    """One immutable movement against one account. Amount is always positive;
    `direction` carries the sign (debit = +, credit = − for the balance check).

    Multi-currency: `currency` is the posting currency; `base_currency` +
    `fx_rate_e8` + `base_amount_minor` record the books currency conversion
    (rate scaled by 1e8 so FX stays integer-safe). Same-currency posts use
    rate 100_000_000 and base_amount_minor == amount_minor.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    entry = models.ForeignKey(LedgerEntry, on_delete=models.PROTECT, related_name="postings")
    account = models.ForeignKey(LedgerAccount, on_delete=models.PROTECT, related_name="postings")
    direction = models.CharField(max_length=8, choices=PostingDirection.choices)
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    base_currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    # Integer FX: 1.0 == 100_000_000. Never store float rates.
    fx_rate_e8 = models.BigIntegerField(default=100_000_000)
    base_amount_minor = models.BigIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["account", "created_at"])]

    @property
    def signed_minor(self) -> int:
        return self.amount_minor if self.direction == PostingDirection.DEBIT else -self.amount_minor


class DomainEventType(models.TextChoices):
    PAYMENT_CREATED = "payment.created"
    PAYMENT_AUTHORIZED = "payment.authorized"
    PAYMENT_CAPTURED = "payment.captured"
    PAYMENT_SETTLED = "payment.settled"
    PAYMENT_FAILED = "payment.failed"
    PAYMENT_REJECTED = "payment.rejected"
    PAYMENT_CANCELLED = "payment.cancelled"
    WITHDRAWAL_REQUESTED = "withdrawal.requested"
    WITHDRAWAL_APPROVED = "withdrawal.approved"
    WITHDRAWAL_COMPLETED = "withdrawal.completed"
    WITHDRAWAL_REJECTED = "withdrawal.rejected"
    REFUND_CREATED = "refund.created"
    REFUND_COMPLETED = "refund.completed"
    REVERSAL_COMPLETED = "reversal.completed"
    RISK_DENIED = "risk.denied"
    RISK_REVIEW = "risk.review"
    # --- Phase 3 financial platform ---
    SETTLEMENT_CREATED = "settlement.created"
    SETTLEMENT_COMPLETED = "settlement.completed"
    SETTLEMENT_CANCELLED = "settlement.cancelled"
    MERCHANT_PAID = "merchant.paid"
    MERCHANT_CAPTURED = "merchant.captured"
    CHARGEBACK_OPENED = "chargeback.opened"
    CHARGEBACK_EVIDENCE_REQUESTED = "chargeback.evidence_requested"
    CHARGEBACK_EVIDENCE_SUBMITTED = "chargeback.evidence_submitted"
    CHARGEBACK_REPRESENTMENT = "chargeback.representment"
    CHARGEBACK_WON = "chargeback.won"
    CHARGEBACK_LOST = "chargeback.lost"
    CHARGEBACK_REVERSED = "chargeback.reversed"
    TREASURY_TRANSFER = "treasury.transfer"
    RESERVE_UPDATED = "reserve.updated"
    FEE_COLLECTED = "fee.collected"
    COMMISSION_CALCULATED = "commission.calculated"
    TAX_POSTED = "tax.posted"
    APPROVAL_REQUESTED = "approval.requested"
    APPROVAL_GRANTED = "approval.granted"
    APPROVAL_DENIED = "approval.denied"
    WORKFLOW_STARTED = "workflow.started"
    WORKFLOW_COMPLETED = "workflow.completed"
    RULE_EVALUATED = "rule.evaluated"


class DomainEvent(AppendOnly):
    """Immutable business-history event. Complements the ledger (money truth)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_type = models.CharField(max_length=64, choices=DomainEventType.choices, db_index=True)
    transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.PROTECT, related_name="domain_events"
    )
    owner = models.CharField(max_length=128, blank=True, default="", db_index=True)
    payload = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        indexes = [models.Index(fields=["event_type", "created_at"])]


class AuditRecord(AppendOnly):
    """Who / when / where — never a substitute for the ledger."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor = models.CharField(max_length=128, db_index=True)
    action = models.CharField(max_length=64, db_index=True)
    resource_type = models.CharField(max_length=64)
    resource_id = models.CharField(max_length=64, blank=True, default="")
    ip = models.GenericIPAddressField(null=True, blank=True)
    device_id = models.CharField(max_length=128, blank=True, default="")
    reason = models.CharField(max_length=255, blank=True, default="")
    before = models.JSONField(null=True, blank=True)
    after = models.JSONField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        indexes = [models.Index(fields=["actor", "created_at"]), models.Index(fields=["action"])]


class IdempotencyKeyStatus(models.TextChoices):
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"


class IdempotencyKey(models.Model):
    """Guarantees exactly-once processing. A replayed key returns the stored
    response instead of moving money again."""

    key = models.CharField(primary_key=True, max_length=128)
    scope = models.CharField(max_length=32)  # transfer | topup | ...
    request_hash = models.CharField(max_length=64)
    status = models.CharField(max_length=16, choices=IdempotencyKeyStatus.choices, default=IdempotencyKeyStatus.IN_PROGRESS)
    transaction = models.ForeignKey(Transaction, null=True, blank=True, on_delete=models.SET_NULL)
    response_code = models.IntegerField(null=True, blank=True)
    response_body = models.JSONField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return f"{self.key} [{self.status}]"


class WebhookEvent(models.Model):
    """A raw provider callback (e.g. an M-Pesa STK result), persisted before
    processing so nothing is lost and replays are idempotent. The raw `payload`
    is immutable in practice; only `processed`/`result` transition."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    provider = models.CharField(max_length=32)
    event_type = models.CharField(max_length=64)
    provider_ref = models.CharField(max_length=128, db_index=True)
    payload = models.JSONField()
    processed = models.BooleanField(default=False)
    result = models.CharField(max_length=32, blank=True, default="")
    received_at = models.DateTimeField(auto_now_add=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    def __str__(self) -> str:
        return f"{self.provider}:{self.event_type} {self.provider_ref}"


class Device(models.Model):
    """A registered mobile client. The bearer token is **bound to this device**:
    the client stores a stable `device_id`, registers once to obtain a token, and
    every authenticated call must present both. We persist only the SHA-256 of the
    token — the plaintext is returned exactly once and never stored.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    device_id = models.CharField(max_length=128, unique=True)
    token_hash = models.CharField(max_length=64, db_index=True)
    owner = models.CharField(max_length=128, db_index=True)
    label = models.CharField(max_length=128, blank=True, default="")
    platform = models.CharField(max_length=32, blank=True, default="")
    push_token = models.CharField(max_length=255, blank=True, default="")
    # Human-findable identity for P2P (pay/request by phone, like M-Pesa/Ziina).
    # Null (not blank-string) so only real numbers participate in the unique
    # constraint — many devices can otherwise have no phone on file.
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True, default=None)
    # Self-service merchant opt-in: payment links created while this is true
    # snapshot a platform fee (settings.PAYMENTS_MERCHANT_FEE_BPS) at creation
    # time. P2P (send/request/split) is always free regardless of this flag.
    is_merchant = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    last_seen_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["owner"])]

    # Lets DRF treat the device as the request principal (request.user).
    @property
    def is_authenticated(self) -> bool:
        return True

    @property
    def is_anonymous(self) -> bool:
        return False

    def __str__(self) -> str:
        return f"Device {self.device_id} → {self.owner}"


class WebhookReplayGuard(AppendOnly):
    """Replay protection — one fingerprint per accepted webhook payload."""

    fingerprint = models.CharField(primary_key=True, max_length=64)
    provider = models.CharField(max_length=32, db_index=True)
    provider_ref = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)


class SettlementBatchStatus(models.TextChoices):
    RECEIVED = "received"
    RECONCILED = "reconciled"
    FAILED = "failed"


class SettlementMatchStatus(models.TextChoices):
    PENDING = "pending"
    MATCHED = "matched"
    MISSING_INTERNAL = "missing_internal"
    AMOUNT_MISMATCH = "amount_mismatch"
    CURRENCY_MISMATCH = "currency_mismatch"
    DUPLICATE = "duplicate"
    UNEXPECTED = "unexpected"
    LATE = "late"


class SettlementBatch(models.Model):
    """A provider settlement file / statement ingested for reconciliation."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    provider = models.CharField(max_length=32, db_index=True)
    filename = models.CharField(max_length=255)
    status = models.CharField(
        max_length=16, choices=SettlementBatchStatus.choices, default=SettlementBatchStatus.RECEIVED
    )
    line_count = models.PositiveIntegerField(default=0)
    matched_count = models.PositiveIntegerField(default=0)
    exception_count = models.PositiveIntegerField(default=0)
    notes = models.TextField(blank=True, default="")
    received_at = models.DateTimeField(auto_now_add=True)
    reconciled_at = models.DateTimeField(null=True, blank=True)


class SettlementLine(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    batch = models.ForeignKey(SettlementBatch, on_delete=models.PROTECT, related_name="lines")
    provider_ref = models.CharField(max_length=128, db_index=True)
    external_id = models.CharField(max_length=128, blank=True, default="")
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    direction = models.CharField(max_length=8, choices=TransactionDirection.choices)
    settled_at = models.DateTimeField(null=True, blank=True)
    match_status = models.CharField(
        max_length=24, choices=SettlementMatchStatus.choices, default=SettlementMatchStatus.PENDING
    )
    transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.SET_NULL, related_name="settlement_lines"
    )


class Contact(models.Model):
    """A saved person in the owner's TAIFA address book (Ziina/Grab-style
    'pay a friend' picker). `contact_owner` is the target's wallet owner —
    resolved once at save time via phone lookup, then reused without another
    phone round-trip."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    contact_owner = models.CharField(max_length=128)
    display_name = models.CharField(max_length=128, blank=True, default="")
    phone_number = models.CharField(max_length=20, blank=True, default="")
    favorite = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-favorite", "display_name"]
        constraints = [
            models.UniqueConstraint(fields=["owner", "contact_owner"], name="unique_contact_per_owner")
        ]
        indexes = [models.Index(fields=["owner", "-favorite"])]

    def __str__(self) -> str:
        return f"Contact {self.owner} → {self.contact_owner}"


class RecurringInterval(models.TextChoices):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class RecurringPaymentStatus(models.TextChoices):
    ACTIVE = "active"
    PAUSED = "paused"
    CANCELLED = "cancelled"


class RecurringPayment(models.Model):
    """A standing order (rent, allowance, subscription) — an internal P2P
    transfer that fires automatically on a schedule via Celery beat.
    Auto-pauses after repeated insufficient-funds failures rather than
    silently failing forever; see `payments.recurring`."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)  # who pays
    payee = models.CharField(max_length=128)  # who receives (wallet owner)
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    note = models.CharField(max_length=255, blank=True, default="")
    emoji = models.CharField(max_length=16, blank=True, default="")
    interval = models.CharField(max_length=8, choices=RecurringInterval.choices)
    status = models.CharField(
        max_length=16, choices=RecurringPaymentStatus.choices, default=RecurringPaymentStatus.ACTIVE
    )
    next_run_at = models.DateTimeField(db_index=True)
    last_run_at = models.DateTimeField(null=True, blank=True)
    last_transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.SET_NULL, related_name="+"
    )
    consecutive_failures = models.PositiveIntegerField(default=0)
    max_consecutive_failures = models.PositiveIntegerField(default=3)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["owner", "-created_at"]),
            models.Index(fields=["status", "next_run_at"]),
        ]

    def __str__(self) -> str:
        return f"RecurringPayment {self.amount_minor} {self.currency} {self.owner}→{self.payee} [{self.interval}, {self.status}]"


class PushNotificationStatus(models.TextChoices):
    QUEUED = "queued"
    SENT = "sent"
    FAILED = "failed"


class PushNotification(models.Model):
    """A notification queued for a wallet owner (fanned out to their
    registered devices at send time — see `payments.notifications`).

    No real FCM/APNS credentials are configured yet, so the default
    `LoggingPushNotifier` just persists rows here (mirrors how
    `OfflineMpesaGateway` stands in for the real Daraja adapter). Swap in a
    real sender behind the same `PushNotifier` interface when ready."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    title = models.CharField(max_length=128)
    body = models.CharField(max_length=255)
    data = models.JSONField(default=dict, blank=True)
    status = models.CharField(
        max_length=16, choices=PushNotificationStatus.choices, default=PushNotificationStatus.QUEUED
    )
    read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    sent_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["owner", "-created_at"])]

    def __str__(self) -> str:
        return f"PushNotification {self.owner}: {self.title}"


class SpendingCapPeriod(models.TextChoices):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"


class SpendingCap(models.Model):
    """A self-imposed budget ceiling on outgoing money (transfers,
    withdrawals — not top-ups). Calendar-aligned (resets on the day/ISO
    week/month boundary), unlike the platform-wide RISK_DAILY_DEBIT_LIMIT_MINOR
    setting which is a rolling 24h window. Enforced in `payments.risk`."""

    owner = models.CharField(max_length=128, primary_key=True)
    period = models.CharField(max_length=8, choices=SpendingCapPeriod.choices)
    limit_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f"SpendingCap {self.owner}: {self.limit_minor} {self.currency} / {self.period}"


class ReconciliationExceptionCode(models.TextChoices):
    MISSING_SETTLEMENT = "missing_settlement"
    DUPLICATE_SETTLEMENT = "duplicate_settlement"
    AMOUNT_MISMATCH = "amount_mismatch"
    CURRENCY_MISMATCH = "currency_mismatch"
    UNEXPECTED_SETTLEMENT = "unexpected_settlement"
    LATE_SETTLEMENT = "late_settlement"
    UNKNOWN_TRANSACTION = "unknown_transaction"


class PaymentLinkStatus(models.TextChoices):
    ACTIVE = "active"
    PAUSED = "paused"
    COMPLETED = "completed"  # single-use link that has been paid
    EXPIRED = "expired"


class PaymentLink(models.Model):
    """A shareable receive-money link (Ziina-style): `taifa.app/pay/<slug>`.

    The owner shares the link (or its QR); any wallet holder opens it and pays.
    `amount_minor` may be null — the payer chooses the amount ("open" link).
    A `single_use` link completes after its first successful payment.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    slug = models.CharField(max_length=24, unique=True, db_index=True)
    owner = models.CharField(max_length=128, db_index=True)
    display_name = models.CharField(max_length=128, blank=True, default="")
    amount_minor = models.BigIntegerField(null=True, blank=True)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    note = models.CharField(max_length=255, blank=True, default="")
    emoji = models.CharField(max_length=16, blank=True, default="")
    status = models.CharField(
        max_length=16, choices=PaymentLinkStatus.choices, default=PaymentLinkStatus.ACTIVE
    )
    single_use = models.BooleanField(default=False)
    # Snapshotted at creation from the owner's merchant status — later toggling
    # is_merchant never changes fees on links already issued. 0 for plain P2P.
    fee_bps = models.PositiveIntegerField(default=0)
    expires_at = models.DateTimeField(null=True, blank=True)
    total_paid_minor = models.BigIntegerField(default=0)
    payment_count = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["owner", "-created_at"])]

    def __str__(self) -> str:
        return f"PaymentLink {self.slug} → {self.owner} [{self.status}]"


class BillSplitStatus(models.TextChoices):
    OPEN = "open"
    SETTLED = "settled"
    CANCELLED = "cancelled"


class BillSplit(models.Model):
    """A bill the organizer already paid, split across friends (Ziina-style).
    Each participant's share is a `MoneyRequest` (see `MoneyRequest.bill`) —
    BillSplit itself carries no money; it's the grouping + rollup status."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organizer = models.CharField(max_length=128, db_index=True)
    title = models.CharField(max_length=128)
    emoji = models.CharField(max_length=16, blank=True, default="")
    total_amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    status = models.CharField(max_length=16, choices=BillSplitStatus.choices, default=BillSplitStatus.OPEN)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["organizer", "-created_at"])]

    def __str__(self) -> str:
        return f"BillSplit {self.title} {self.total_amount_minor} {self.currency} [{self.status}]"


class MoneyRequestStatus(models.TextChoices):
    PENDING = "pending"
    PAID = "paid"
    DECLINED = "declined"
    CANCELLED = "cancelled"
    EXPIRED = "expired"


class MoneyRequest(models.Model):
    """A request for money from another wallet holder (Ziina-style).

    The requester names a payer (wallet owner); the payer sees it in their
    inbox and either pays (instant internal P2P settle) or declines.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    requester = models.CharField(max_length=128, db_index=True)
    payer = models.CharField(max_length=128, db_index=True)
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    note = models.CharField(max_length=255, blank=True, default="")
    emoji = models.CharField(max_length=16, blank=True, default="")
    status = models.CharField(
        max_length=16, choices=MoneyRequestStatus.choices, default=MoneyRequestStatus.PENDING
    )
    # The settlement transaction (payer side) once paid.
    transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.PROTECT, related_name="money_requests"
    )
    # Set when this request is one participant's share of a BillSplit.
    bill = models.ForeignKey(
        BillSplit, null=True, blank=True, on_delete=models.PROTECT, related_name="shares"
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    responded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["requester", "-created_at"]),
            models.Index(fields=["payer", "status"]),
        ]

    def __str__(self) -> str:
        return f"MoneyRequest {self.amount_minor} {self.currency} {self.requester}←{self.payer} [{self.status}]"


class ReconciliationException(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    batch = models.ForeignKey(
        SettlementBatch, on_delete=models.PROTECT, related_name="exceptions", null=True, blank=True
    )
    code = models.CharField(max_length=32, choices=ReconciliationExceptionCode.choices, db_index=True)
    provider_ref = models.CharField(max_length=128, blank=True, default="")
    detail = models.TextField()
    transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.SET_NULL, related_name="recon_exceptions"
    )
    created_at = models.DateTimeField(auto_now_add=True)
