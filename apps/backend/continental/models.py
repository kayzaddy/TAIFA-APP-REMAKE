"""Pan-African multi-country configuration — no hardcoded national logic in products.

Countries are tenants. Shared services (Payments, Identity, AI OS, Ecosystem)
remain centralized; local behavior is configuration + adapters.
"""
from __future__ import annotations

import hashlib
import secrets
import uuid

from django.db import models
from django.utils import timezone


class CountryProfile(models.Model):
    """National tenant — adding a country is configuration, not architecture."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=2, unique=True)  # ISO 3166-1 alpha-2
    name = models.CharField(max_length=128)
    official_name = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=16, default="active")  # active|pilot|planned
    default_currency = models.CharField(max_length=8)
    supported_currencies = models.JSONField(default=list)  # ["TZS","USD"]
    languages = models.JSONField(default=list)  # ["en","sw"]
    default_locale = models.CharField(max_length=16, default="en")
    timezone = models.CharField(max_length=64, default="Africa/Dar_es_Salaam")
    data_region = models.CharField(max_length=64, default="eastafrica")  # residency zone
    calling_code = models.CharField(max_length=8, blank=True, default="")
    branding = models.JSONField(default=dict, blank=True)  # primary_color, logo_ref
    feature_flags = models.JSONField(default=dict, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["code"]


class ComplianceProfile(models.Model):
    """Configurable compliance engine — never hardcode regulator rules in products."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    country = models.ForeignKey(
        CountryProfile, on_delete=models.CASCADE, related_name="compliance_profiles"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=128)
    category = models.CharField(
        max_length=32
    )  # aml|kyc|cdd|tax|central_bank|privacy|audit|data_residency
    rules = models.JSONField(default=dict)  # thresholds, report_codes, retention_days, …
    reporting_authority = models.CharField(max_length=128, blank=True, default="")
    active = models.BooleanField(default=True)
    version = models.PositiveIntegerField(default=1)
    effective_from = models.DateField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["country", "code", "version"],
                name="taifa_continental_unique_compliance",
            )
        ]


class PaymentRailBinding(models.Model):
    """Local payment providers per country — adapter paths, not hardcoded rails."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    country = models.ForeignKey(
        CountryProfile, on_delete=models.CASCADE, related_name="payment_rails"
    )
    rail_code = models.SlugField(max_length=64)  # mpesa|tigopesa|airtel|card|bank
    display_name = models.CharField(max_length=128)
    currencies = models.JSONField(default=list)
    adapter_path = models.CharField(max_length=255, blank=True, default="")
    sandbox = models.BooleanField(default=True)
    active = models.BooleanField(default=True)
    config = models.JSONField(default=dict, blank=True)


class IdentityFederationBinding(models.Model):
    """National identity / registry adapters per country."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    country = models.ForeignKey(
        CountryProfile, on_delete=models.CASCADE, related_name="identity_bindings"
    )
    provider_code = models.SlugField(max_length=64)  # nida|huduma|nin|passport|brela|ura|…
    provider_type = models.CharField(
        max_length=32
    )  # national_id|business|tax|passport|driver|health|education|gov_portal
    adapter_path = models.CharField(
        max_length=255, default="continental.adapters.StubIdentityAdapter"
    )
    active = models.BooleanField(default=True)
    config = models.JSONField(default=dict, blank=True)


class LanguagePack(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    locale = models.CharField(max_length=16, unique=True)  # en, sw, fr, ar, pt
    name = models.CharField(max_length=64)
    rtl = models.BooleanField(default=False)
    strings = models.JSONField(default=dict)  # key → translation
    active = models.BooleanField(default=True)


class FxRate(models.Model):
    """Locked FX quotes for treasury / cross-border — consumed by payments ledger."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    base_currency = models.CharField(max_length=8, db_index=True)
    quote_currency = models.CharField(max_length=8, db_index=True)
    rate_e8 = models.PositiveBigIntegerField()  # quote per 1 base * 1e8
    source = models.CharField(max_length=64, default="seed")
    as_of = models.DateTimeField(default=timezone.now, db_index=True)
    valid_until = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        indexes = [models.Index(fields=["base_currency", "quote_currency", "-as_of"])]


class CrossBorderCorridor(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    origin_country = models.ForeignKey(
        CountryProfile, on_delete=models.PROTECT, related_name="corridors_out"
    )
    destination_country = models.ForeignKey(
        CountryProfile, on_delete=models.PROTECT, related_name="corridors_in"
    )
    corridor_type = models.CharField(
        max_length=32, default="wallet"
    )  # wallet|merchant|logistics|freight|passenger
    origin_currency = models.CharField(max_length=8)
    destination_currency = models.CharField(max_length=8)
    settlement_currency = models.CharField(max_length=8, default="USD")
    fee_bps = models.PositiveIntegerField(default=50)  # 0.50%
    min_fee_minor = models.PositiveBigIntegerField(default=0)
    active = models.BooleanField(default=True)
    routing = models.JSONField(default=dict, blank=True)  # preferred rails, limits
    metadata = models.JSONField(default=dict, blank=True)


class CrossBorderTransferIntent(models.Model):
    """Intent only — money movement still executes via Taifa Payments."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    corridor = models.ForeignKey(
        CrossBorderCorridor, on_delete=models.PROTECT, related_name="intents"
    )
    owner_principal = models.CharField(max_length=128, db_index=True)
    amount_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8)
    converted_minor = models.PositiveBigIntegerField(default=0)
    converted_currency = models.CharField(max_length=8, blank=True, default="")
    fx_rate_e8 = models.PositiveBigIntegerField(default=0)
    fee_minor = models.PositiveBigIntegerField(default=0)
    status = models.CharField(
        max_length=16, default="quoted"
    )  # quoted|submitted|settled|failed|cancelled
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    compliance_flags = models.JSONField(default=list, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class DataResidencyPolicy(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    country = models.OneToOneField(
        CountryProfile, on_delete=models.CASCADE, related_name="residency_policy"
    )
    storage_region = models.CharField(max_length=64)
    allow_cross_border_processing = models.BooleanField(default=False)
    retention_days = models.PositiveIntegerField(default=2555)  # ~7 years default
    backup_region = models.CharField(max_length=64, blank=True, default="")
    encryption_profile = models.CharField(max_length=64, default="aes-256-gcm")
    rules = models.JSONField(default=dict, blank=True)


class PartnerNetworkMember(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    partner_code = models.SlugField(max_length=64, unique=True)
    legal_name = models.CharField(max_length=255)
    partner_type = models.CharField(
        max_length=32
    )  # bank|fintech|university|developer|government|ngo|startup|si
    countries = models.JSONField(default=list)  # ISO codes
    domains = models.JSONField(default=list)  # ecosystem domain codes
    status = models.CharField(max_length=16, default="pending")  # pending|certified|suspended
    certification_tier = models.CharField(max_length=16, blank=True, default="")  # sandbox|gold|…
    contact_email = models.EmailField(blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    certified_at = models.DateTimeField(null=True, blank=True)


class DeveloperSandboxCredential(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    partner = models.ForeignKey(
        PartnerNetworkMember, on_delete=models.CASCADE, related_name="sandbox_credentials"
    )
    api_key_prefix = models.CharField(max_length=16)
    api_key_hash = models.CharField(max_length=128, unique=True)
    scopes = models.JSONField(default=list)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    @staticmethod
    def hash_key(raw: str) -> str:
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    @classmethod
    def issue(cls, *, partner: PartnerNetworkMember, scopes: list | None = None):
        raw = secrets.token_urlsafe(32)
        return (
            cls.objects.create(
                partner=partner,
                api_key_prefix=raw[:12],
                api_key_hash=cls.hash_key(raw),
                scopes=scopes or ["continental.read", "payments.sandbox", "ecosystem.read"],
            ),
            raw,
        )


class RegionalOpsMetric(models.Model):
    date = models.DateField(db_index=True)
    country_code = models.CharField(max_length=2, db_index=True)
    domain_code = models.CharField(max_length=64, blank=True, default="")
    kpi_code = models.CharField(max_length=64)
    value_e2 = models.BigIntegerField(default=0)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["date", "country_code", "domain_code", "kpi_code"],
                name="taifa_continental_unique_regional_kpi",
            )
        ]
