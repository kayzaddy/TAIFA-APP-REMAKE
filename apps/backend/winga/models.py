"""Taifa Winga — Universal Brokerage Platform models.

Actors: Customer (principal), Winga (intermediary), Provider, Platform.
Money truth stays in payments ledger. Winga never owns inventory by default.
"""
from __future__ import annotations

import uuid

from django.db import models


class VerificationStatus(models.TextChoices):
    UNVERIFIED = "unverified"
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"
    SUSPENDED = "suspended"


class WingaKind(models.TextChoices):
    INDIVIDUAL = "individual"
    BUSINESS = "business"
    CORPORATE_AGENCY = "corporate_agency"
    REFERRAL_ORG = "referral_org"


class OfferingKind(models.TextChoices):
    PRODUCT = "product"
    SERVICE = "service"
    BOOKING = "booking"
    RENTAL = "rental"
    DIGITAL = "digital"
    REFERRAL = "referral"
    LOGISTICS = "logistics"
    OTHER = "other"


class DealStage(models.TextChoices):
    LEAD = "lead"
    INQUIRY = "inquiry"
    QUOTATION = "quotation"
    NEGOTIATION = "negotiation"
    OFFER = "offer"
    ACCEPTED = "accepted"
    PAYMENT = "payment"
    FULFILLMENT = "fulfillment"
    SETTLEMENT = "settlement"
    COMMISSION_PAYOUT = "commission_payout"
    REVIEW = "review"
    CLOSED = "closed"
    CANCELLED = "cancelled"
    DISPUTED = "disputed"


class CommissionKind(models.TextChoices):
    PERCENTAGE = "percentage"
    FLAT = "flat"
    TIERED = "tiered"
    CATEGORY = "category"
    PROVIDER = "provider"
    CAMPAIGN = "campaign"
    REFERRAL_BONUS = "referral_bonus"
    MULTI_LEVEL = "multi_level"


class CommissionEventStatus(models.TextChoices):
    CALCULATED = "calculated"
    HELD = "held"
    SETTLED = "settled"
    REVERSED = "reversed"
    CANCELLED = "cancelled"


class BrokerageDomain(models.Model):
    """Configurable industry vertical — new sectors via config, not redesign."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    active = models.BooleanField(default=True)
    workflow_definition_code = models.CharField(
        max_length=64,
        default="winga.default_brokerage",
        help_text="enterprise.WorkflowDefinition.code",
    )
    default_commission_bps = models.PositiveIntegerField(default=500)  # 5%
    attributes_schema = models.JSONField(default=dict, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["code"]

    def __str__(self) -> str:
        return self.code


class Category(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    domain = models.ForeignKey(BrokerageDomain, on_delete=models.CASCADE, related_name="categories")
    parent = models.ForeignKey(
        "self", null=True, blank=True, on_delete=models.SET_NULL, related_name="children"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=128)
    active = models.BooleanField(default=True)

    class Meta:
        unique_together = [("domain", "code")]
        verbose_name_plural = "categories"


class WingaProfile(models.Model):
    """Verified intermediary — never required to own inventory."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, unique=True, db_index=True)
    kind = models.CharField(max_length=32, choices=WingaKind.choices, default=WingaKind.INDIVIDUAL)
    display_name = models.CharField(max_length=255)
    bio = models.TextField(blank=True, default="")
    verification_status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.UNVERIFIED
    )
    kyc_ref = models.CharField(max_length=128, blank=True, default="")
    certification = models.CharField(max_length=128, blank=True, default="")
    reputation_score_e4 = models.PositiveIntegerField(default=5000)
    risk_score_e4 = models.PositiveIntegerField(default=0)
    domains = models.ManyToManyField(BrokerageDomain, blank=True, related_name="wingas")
    metadata = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class ProviderProfile(models.Model):
    """Verified supplier of products/services — optional Taifa Merchant link."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, unique=True, db_index=True)
    legal_name = models.CharField(max_length=255)
    trading_name = models.CharField(max_length=255, blank=True, default="")
    verification_status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.UNVERIFIED
    )
    kyb_ref = models.CharField(max_length=128, blank=True, default="")
    merchant = models.ForeignKey(
        "enterprise.Merchant",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="winga_providers",
    )
    domains = models.ManyToManyField(BrokerageDomain, blank=True, related_name="providers")
    locations = models.JSONField(default=list, blank=True)
    operating_hours = models.JSONField(default=dict, blank=True)
    reputation_score_e4 = models.PositiveIntegerField(default=5000)
    risk_score_e4 = models.PositiveIntegerField(default=0)
    metadata = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class Offering(models.Model):
    """Catalog listing — goods, services, bookings, rentals, referrals, etc."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    provider = models.ForeignKey(ProviderProfile, on_delete=models.CASCADE, related_name="offerings")
    domain = models.ForeignKey(BrokerageDomain, on_delete=models.PROTECT, related_name="offerings")
    category = models.ForeignKey(
        Category, null=True, blank=True, on_delete=models.SET_NULL, related_name="offerings"
    )
    kind = models.CharField(max_length=16, choices=OfferingKind.choices, default=OfferingKind.SERVICE)
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, default="")
    currency = models.CharField(max_length=8, default="TZS")
    price_minor = models.BigIntegerField(default=0)
    compare_at_minor = models.BigIntegerField(null=True, blank=True)
    inventory_qty = models.IntegerField(null=True, blank=True)  # null = unlimited / non-inventory
    attributes = models.JSONField(default=dict, blank=True)
    variants = models.JSONField(default=list, blank=True)
    availability = models.JSONField(default=dict, blank=True)
    locations = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["domain", "active"]),
            models.Index(fields=["kind", "active"]),
        ]


class CommissionRule(models.Model):
    """Flexible commission configuration — percentage, flat, tiered, campaign, multi-level."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    kind = models.CharField(max_length=32, choices=CommissionKind.choices, default=CommissionKind.PERCENTAGE)
    domain = models.ForeignKey(
        BrokerageDomain, null=True, blank=True, on_delete=models.CASCADE, related_name="commission_rules"
    )
    category = models.ForeignKey(
        Category, null=True, blank=True, on_delete=models.CASCADE, related_name="commission_rules"
    )
    provider = models.ForeignKey(
        ProviderProfile, null=True, blank=True, on_delete=models.CASCADE, related_name="commission_rules"
    )
    winga = models.ForeignKey(
        WingaProfile, null=True, blank=True, on_delete=models.CASCADE, related_name="commission_rules"
    )
    bps = models.PositiveIntegerField(default=500, help_text="Basis points when kind=percentage")
    flat_minor = models.BigIntegerField(default=0)
    tiers = models.JSONField(
        default=list,
        blank=True,
        help_text='[{"min_minor":0,"max_minor":100000,"bps":800}, ...]',
    )
    multi_level = models.JSONField(
        default=list,
        blank=True,
        help_text='[{"level":1,"bps":500},{"level":2,"bps":100}]',
    )
    campaign_code = models.CharField(max_length=64, blank=True, default="")
    priority = models.PositiveIntegerField(default=100, help_text="Lower wins")
    active = models.BooleanField(default=True)
    valid_from = models.DateTimeField(null=True, blank=True)
    valid_to = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["priority", "code"]


class Lead(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    winga = models.ForeignKey(WingaProfile, on_delete=models.CASCADE, related_name="leads")
    customer_principal = models.CharField(max_length=128, db_index=True)
    domain = models.ForeignKey(BrokerageDomain, on_delete=models.PROTECT, related_name="leads")
    offering = models.ForeignKey(
        Offering, null=True, blank=True, on_delete=models.SET_NULL, related_name="leads"
    )
    title = models.CharField(max_length=255)
    notes = models.TextField(blank=True, default="")
    pipeline_stage = models.CharField(max_length=32, default="new")
    priority_e4 = models.PositiveIntegerField(default=5000)
    follow_up_at = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class Quotation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    lead = models.ForeignKey(Lead, on_delete=models.CASCADE, related_name="quotations")
    provider = models.ForeignKey(ProviderProfile, on_delete=models.CASCADE, related_name="quotations")
    currency = models.CharField(max_length=8, default="TZS")
    amount_minor = models.BigIntegerField()
    line_items = models.JSONField(default=list, blank=True)
    valid_until = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=16, default="draft")  # draft|sent|accepted|rejected|expired
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class BrokerageDeal(models.Model):
    """Core brokerage transaction lifecycle across any domain."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reference = models.CharField(max_length=32, unique=True, db_index=True)
    domain = models.ForeignKey(BrokerageDomain, on_delete=models.PROTECT, related_name="deals")
    winga = models.ForeignKey(WingaProfile, on_delete=models.PROTECT, related_name="deals")
    provider = models.ForeignKey(ProviderProfile, on_delete=models.PROTECT, related_name="deals")
    customer_principal = models.CharField(max_length=128, db_index=True)
    offering = models.ForeignKey(
        Offering, null=True, blank=True, on_delete=models.SET_NULL, related_name="deals"
    )
    lead = models.ForeignKey(Lead, null=True, blank=True, on_delete=models.SET_NULL, related_name="deals")
    quotation = models.ForeignKey(
        Quotation, null=True, blank=True, on_delete=models.SET_NULL, related_name="deals"
    )
    stage = models.CharField(max_length=32, choices=DealStage.choices, default=DealStage.LEAD)
    currency = models.CharField(max_length=8, default="TZS")
    amount_minor = models.BigIntegerField(default=0)
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    workflow_instance_id = models.UUIDField(null=True, blank=True)
    booking = models.JSONField(
        default=dict,
        blank=True,
        help_text="Appointments/reservations payload (dates, guests, resources)",
    )
    fulfillment = models.JSONField(default=dict, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    closed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["stage", "domain"]),
            models.Index(fields=["winga", "stage"]),
            models.Index(fields=["customer_principal", "stage"]),
        ]


class DealEvent(models.Model):
    """Append-only audit trail for deal stage transitions."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    deal = models.ForeignKey(BrokerageDeal, on_delete=models.CASCADE, related_name="events")
    from_stage = models.CharField(max_length=32, blank=True, default="")
    to_stage = models.CharField(max_length=32)
    actor = models.CharField(max_length=128)
    note = models.TextField(blank=True, default="")
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]


class CommissionEvent(models.Model):
    """Auditable commission — every event must settle via ledger."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    deal = models.ForeignKey(BrokerageDeal, on_delete=models.CASCADE, related_name="commissions")
    rule = models.ForeignKey(
        CommissionRule, null=True, blank=True, on_delete=models.SET_NULL, related_name="events"
    )
    winga = models.ForeignKey(WingaProfile, on_delete=models.PROTECT, related_name="commission_events")
    kind = models.CharField(max_length=32, choices=CommissionKind.choices)
    currency = models.CharField(max_length=8, default="TZS")
    basis_amount_minor = models.BigIntegerField()
    commission_minor = models.BigIntegerField()
    bps_applied = models.PositiveIntegerField(default=0)
    level = models.PositiveSmallIntegerField(default=1)
    status = models.CharField(
        max_length=16, choices=CommissionEventStatus.choices, default=CommissionEventStatus.CALCULATED
    )
    ledger_txn_id = models.CharField(max_length=64, blank=True, default="")
    calculation = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    settled_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]


class Review(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    deal = models.ForeignKey(BrokerageDeal, on_delete=models.CASCADE, related_name="reviews")
    author_principal = models.CharField(max_length=128, db_index=True)
    subject_type = models.CharField(max_length=16)  # winga|provider
    subject_id = models.UUIDField()
    rating_e4 = models.PositiveIntegerField()  # 1000–5000 ≈ 1–5 stars
    comment = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("deal", "author_principal", "subject_type")]


class Dispute(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    deal = models.ForeignKey(BrokerageDeal, on_delete=models.CASCADE, related_name="disputes")
    opened_by = models.CharField(max_length=128)
    reason = models.CharField(max_length=255)
    status = models.CharField(max_length=16, default="open")  # open|investigating|resolved|rejected
    resolution = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)


class Favorite(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner_principal = models.CharField(max_length=128, db_index=True)
    offering = models.ForeignKey(Offering, on_delete=models.CASCADE, related_name="favorites")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("owner_principal", "offering")]
