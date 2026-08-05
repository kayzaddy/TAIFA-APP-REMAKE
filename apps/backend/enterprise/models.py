"""Enterprise financial platform models — merchants, settlements, treasury,
chargebacks, rules, workflows, approvals, RBAC, and reporting projections.

Money truth remains in `payments` ledger. These models are control-plane and
read-model state only (except where they reference Transaction / LedgerEntry).
"""
from __future__ import annotations

import uuid

from django.db import models

from payments.models import CURRENCY_CHOICES, Transaction


class MerchantStatus(models.TextChoices):
    DRAFT = "draft"
    PENDING_APPROVAL = "pending_approval"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    CLOSED = "closed"


class SettlementMode(models.TextChoices):
    DAILY = "daily"
    INSTANT = "instant"
    SCHEDULED = "scheduled"
    MANUAL = "manual"


class Merchant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    legal_name = models.CharField(max_length=255)
    trading_name = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=32, choices=MerchantStatus.choices, default=MerchantStatus.DRAFT)
    settlement_mode = models.CharField(max_length=16, choices=SettlementMode.choices, default=SettlementMode.DAILY)
    settlement_currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    bank_code = models.CharField(max_length=32, default="primary")
    bank_account_ref = models.CharField(max_length=64, blank=True, default="")
    fee_bps = models.PositiveIntegerField(default=150, help_text="Platform fee in basis points")
    commission_bps = models.PositiveIntegerField(default=0)
    tax_bps = models.PositiveIntegerField(default=0)
    mcc = models.CharField(max_length=8, blank=True, default="")
    sector = models.CharField(max_length=64, blank=True, default="")  # healthcare, insurance, gov, retail…
    owner_principal = models.CharField(max_length=128, blank=True, default="", db_index=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["status", "sector"])]

    def __str__(self) -> str:
        return f"{self.code} ({self.legal_name})"


class MerchantApiKey(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="api_keys")
    name = models.CharField(max_length=64)
    key_prefix = models.CharField(max_length=12)
    key_hash = models.CharField(max_length=64, unique=True)
    scopes = models.JSONField(default=list)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(null=True, blank=True)


class MerchantWebhookEndpoint(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="webhooks")
    url = models.URLField()
    secret_hash = models.CharField(max_length=64)
    events = models.JSONField(default=list)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)


class MerchantSettlementStatus(models.TextChoices):
    DRAFT = "draft"
    PENDING_APPROVAL = "pending_approval"
    APPROVED = "approved"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELLED = "cancelled"
    PARTIAL = "partial"


class MerchantSettlement(models.Model):
    """Batched payout of merchant_payable → external bank via journal."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.PROTECT, related_name="settlements")
    status = models.CharField(
        max_length=32, choices=MerchantSettlementStatus.choices, default=MerchantSettlementStatus.DRAFT
    )
    mode = models.CharField(max_length=16, choices=SettlementMode.choices, default=SettlementMode.DAILY)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    amount_minor = models.BigIntegerField()
    fee_minor = models.BigIntegerField(default=0)
    net_minor = models.BigIntegerField()
    period_start = models.DateTimeField()
    period_end = models.DateTimeField()
    scheduled_at = models.DateTimeField(null=True, blank=True)
    idempotency_key = models.CharField(max_length=128, unique=True)
    transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.PROTECT, related_name="merchant_settlements"
    )
    parent = models.ForeignKey(
        "self", null=True, blank=True, on_delete=models.PROTECT, related_name="splits"
    )
    attempt = models.PositiveIntegerField(default=0)
    statement_ref = models.CharField(max_length=64, blank=True, default="")
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["merchant", "-created_at"]),
            models.Index(fields=["status"]),
        ]


class MerchantStatement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="statements")
    period_start = models.DateField()
    period_end = models.DateField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    opening_payable_minor = models.BigIntegerField(default=0)
    captures_minor = models.BigIntegerField(default=0)
    settlements_minor = models.BigIntegerField(default=0)
    fees_minor = models.BigIntegerField(default=0)
    chargebacks_minor = models.BigIntegerField(default=0)
    closing_payable_minor = models.BigIntegerField(default=0)
    payload = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("merchant", "period_start", "period_end", "currency")]


class TreasuryAccountKind(models.TextChoices):
    OPERATING = "operating"
    SETTLEMENT = "settlement"
    RESERVE = "reserve"
    FLOAT = "float"
    PROVIDER = "provider"


class TreasuryBankAccount(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    bank_name = models.CharField(max_length=128)
    account_number_masked = models.CharField(max_length=32)
    kind = models.CharField(max_length=16, choices=TreasuryAccountKind.choices)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    ledger_bank_code = models.CharField(max_length=32, help_text="Maps to journal external_bank code")
    is_active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class TreasuryTransferStatus(models.TextChoices):
    PENDING = "pending"
    PENDING_APPROVAL = "pending_approval"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    FAILED = "failed"


class TreasuryTransfer(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    from_account = models.ForeignKey(
        TreasuryBankAccount, on_delete=models.PROTECT, related_name="outbound_transfers"
    )
    to_account = models.ForeignKey(
        TreasuryBankAccount, on_delete=models.PROTECT, related_name="inbound_transfers"
    )
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    status = models.CharField(
        max_length=32, choices=TreasuryTransferStatus.choices, default=TreasuryTransferStatus.PENDING
    )
    idempotency_key = models.CharField(max_length=128, unique=True)
    transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.PROTECT, related_name="treasury_transfers"
    )
    narrative = models.CharField(max_length=255, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)


class LiquiditySnapshot(models.Model):
    """Point-in-time cash position (projection, not ledger)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    treasury_minor = models.BigIntegerField(default=0)
    provider_settlement_minor = models.BigIntegerField(default=0)
    merchant_payable_minor = models.BigIntegerField(default=0)
    reserve_minor = models.BigIntegerField(default=0)
    float_minor = models.BigIntegerField(default=0)
    as_of = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["currency", "-as_of"])]


class ChargebackStatus(models.TextChoices):
    OPENED = "opened"
    EVIDENCE_REQUESTED = "evidence_requested"
    EVIDENCE_SUBMITTED = "evidence_submitted"
    REPRESENTMENT = "representment"
    WON = "won"
    LOST = "lost"
    REVERSED = "reversed"


class ChargebackCase(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.PROTECT, related_name="chargebacks")
    original_transaction = models.ForeignKey(
        Transaction, on_delete=models.PROTECT, related_name="chargeback_cases"
    )
    status = models.CharField(max_length=32, choices=ChargebackStatus.choices, default=ChargebackStatus.OPENED)
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES)
    reason_code = models.CharField(max_length=32, blank=True, default="")
    evidence = models.JSONField(default=dict, blank=True)
    open_transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.PROTECT, related_name="chargeback_opens"
    )
    resolve_transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.PROTECT, related_name="chargeback_resolves"
    )
    idempotency_key = models.CharField(max_length=128, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    resolved_at = models.DateTimeField(null=True, blank=True)


class ChargebackEvent(models.Model):
    """Append-only chargeback audit trail (case history)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    case = models.ForeignKey(ChargebackCase, on_delete=models.CASCADE, related_name="events")
    from_status = models.CharField(max_length=32, blank=True, default="")
    to_status = models.CharField(max_length=32)
    actor = models.CharField(max_length=128)
    note = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]


# --- Rules / Workflow / Approval / RBAC ---


class BusinessRule(models.Model):
    """Configurable rule — evaluated at runtime, no deploy required to change values."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    category = models.CharField(max_length=64, db_index=True)  # fee, settlement, tax, risk, commission
    description = models.CharField(max_length=255, blank=True, default="")
    priority = models.IntegerField(default=100)
    active = models.BooleanField(default=True)
    conditions = models.JSONField(default=dict)  # {"sector": "healthcare", "amount_gt_minor": 0}
    actions = models.JSONField(default=dict)  # {"fee_bps": 100, "settlement_delay_hours": 24}
    version = models.PositiveIntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class WorkflowDefinition(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    steps = models.JSONField(default=list)  # [{"code": "maker", "role": "ops"}, ...]
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)


class WorkflowInstance(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    definition = models.ForeignKey(WorkflowDefinition, on_delete=models.PROTECT, related_name="instances")
    resource_type = models.CharField(max_length=64)
    resource_id = models.CharField(max_length=64)
    status = models.CharField(max_length=32, default="running")  # running|completed|cancelled
    current_step = models.PositiveIntegerField(default=0)
    context = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)


class ApprovalStatus(models.TextChoices):
    PENDING = "pending"
    APPROVED = "approved"
    DENIED = "denied"
    EXPIRED = "expired"


class ApprovalRequest(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    action = models.CharField(max_length=64, db_index=True)
    resource_type = models.CharField(max_length=64)
    resource_id = models.CharField(max_length=64)
    maker = models.CharField(max_length=128)
    checker = models.CharField(max_length=128, blank=True, default="")
    status = models.CharField(max_length=16, choices=ApprovalStatus.choices, default=ApprovalStatus.PENDING)
    threshold_minor = models.BigIntegerField(default=0)
    amount_minor = models.BigIntegerField(default=0)
    payload = models.JSONField(default=dict)
    reason = models.CharField(max_length=255, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    decided_at = models.DateTimeField(null=True, blank=True)


class PlatformRole(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    permissions = models.JSONField(default=list)  # ["settlement.approve", "treasury.transfer", ...]
    created_at = models.DateTimeField(auto_now_add=True)


class PlatformPrincipal(models.Model):
    """Staff / partner identity for RBAC (separate from device wallet auth)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal_id = models.CharField(max_length=128, unique=True)
    display_name = models.CharField(max_length=128)
    roles = models.ManyToManyField(PlatformRole, blank=True, related_name="principals")
    attributes = models.JSONField(default=dict, blank=True)  # ABAC attrs: sector, region, mfa=true
    mfa_required = models.BooleanField(default=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)


# --- Reporting projections (OLAP-ish read models; never report from hot ledger joins) ---


class MerchantDashboardProjection(models.Model):
    merchant = models.OneToOneField(Merchant, on_delete=models.CASCADE, primary_key=True, related_name="dashboard")
    currency = models.CharField(max_length=8, default="TZS")
    payable_minor = models.BigIntegerField(default=0)
    captures_today_minor = models.BigIntegerField(default=0)
    settlements_mtd_minor = models.BigIntegerField(default=0)
    open_chargebacks = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)


class FinanceDashboardProjection(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    currency = models.CharField(max_length=8, unique=True)
    fee_income_mtd_minor = models.BigIntegerField(default=0)
    commission_mtd_minor = models.BigIntegerField(default=0)
    tax_payable_minor = models.BigIntegerField(default=0)
    chargeback_expense_mtd_minor = models.BigIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)


class ExecutiveDashboardProjection(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    currency = models.CharField(max_length=8, unique=True)
    gmv_mtd_minor = models.BigIntegerField(default=0)
    revenue_mtd_minor = models.BigIntegerField(default=0)
    active_merchants = models.PositiveIntegerField(default=0)
    settlement_success_rate_e4 = models.PositiveIntegerField(default=0)  # 9999 = 99.99%
    updated_at = models.DateTimeField(auto_now=True)


class RegulatoryReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    report_type = models.CharField(max_length=64, db_index=True)  # bot_daily, aml_sar, tax_monthly…
    period_start = models.DateField()
    period_end = models.DateField()
    status = models.CharField(max_length=16, default="generated")
    payload = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["report_type", "-created_at"])]


class EventOutbox(models.Model):
    """Reliable event bus outbox — published asynchronously to webhooks/partners."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_type = models.CharField(max_length=64, db_index=True)
    aggregate_type = models.CharField(max_length=64)
    aggregate_id = models.CharField(max_length=64)
    payload = models.JSONField(default=dict)
    published = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    published_at = models.DateTimeField(null=True, blank=True)
