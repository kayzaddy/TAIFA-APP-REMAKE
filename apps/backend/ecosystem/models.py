"""Digital Ecosystem Platform — domain catalog, enablement, AI, open platform.

Consumes Identity (device auth), Payments/Wallet, Enterprise RBAC/Workflow,
Mobility, Registry, Audit, and Notifications. Does not reimplement them.
"""
from __future__ import annotations

import hashlib
import secrets
import uuid

from django.db import models
from django.utils import timezone


class SharedService(models.Model):
    """Authoritative shared platform capability — domains must consume, not fork."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    api_base = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=16, default="production")  # production|beta|planned
    owner_team = models.CharField(max_length=64, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["code"]


class IndustryDomain(models.Model):
    """Independent industry domain hosted on the ecosystem."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    icon = models.CharField(max_length=64, blank=True, default="")
    route = models.CharField(max_length=128, blank=True, default="")  # Flutter / deep link
    api_base = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=16, default="active")  # active|beta|planned
    sort_order = models.PositiveSmallIntegerField(default=100)
    required_services = models.JSONField(default=list, blank=True)  # SharedService.code list
    capabilities = models.JSONField(default=list, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["sort_order", "code"]


class SuperAppModule(models.Model):
    """Modular Super App surface — one account enables modules."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    domain = models.ForeignKey(
        IndustryDomain,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="modules",
    )
    route = models.CharField(max_length=128)
    icon = models.CharField(max_length=64, blank=True, default="")
    default_enabled = models.BooleanField(default=True)
    sort_order = models.PositiveSmallIntegerField(default=100)
    category = models.CharField(max_length=32, default="service")  # core|service|ops
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["sort_order", "code"]


class PrincipalModuleEnablement(models.Model):
    """Per-principal Super App enablement — one identity, optional services."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, db_index=True)
    module = models.ForeignKey(
        SuperAppModule, on_delete=models.CASCADE, related_name="enablements"
    )
    enabled = models.BooleanField(default=True)
    enabled_at = models.DateTimeField(null=True, blank=True)
    disabled_at = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["principal", "module"],
                name="taifa_ecosystem_unique_principal_module",
            )
        ]


class EcosystemWorkflowBinding(models.Model):
    """Maps business processes to enterprise.WorkflowDefinition codes.

    The workflow engine itself lives in enterprise — this only catalogs reuse.
    """

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    domain_code = models.CharField(max_length=64, db_index=True)
    workflow_definition_code = models.CharField(max_length=64)
    description = models.TextField(blank=True, default="")
    example_resource_type = models.CharField(max_length=64, blank=True, default="")
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)


class AiCapability(models.Model):
    """Shared AI platform capability contracts — implementations are pluggable."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    adapter_path = models.CharField(
        max_length=255,
        blank=True,
        default="ecosystem.ai.StubAiAdapter",
    )
    status = models.CharField(max_length=16, default="available")
    input_schema = models.JSONField(default=dict, blank=True)
    output_schema = models.JSONField(default=dict, blank=True)
    metadata = models.JSONField(default=dict, blank=True)


class AiInvocation(models.Model):
    """Auditable AI invocation log — results are advisory; never mutate ledgers."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    capability = models.ForeignKey(
        AiCapability, on_delete=models.PROTECT, related_name="invocations"
    )
    principal = models.CharField(max_length=128, db_index=True)
    domain_code = models.CharField(max_length=64, blank=True, default="")
    request_payload = models.JSONField(default=dict)
    response_payload = models.JSONField(default=dict)
    model_version = models.CharField(max_length=64, default="stub-v1")
    latency_ms = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)


class WebhookSubscription(models.Model):
    """Open-platform webhook subscriptions over the enterprise event outbox."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner_principal = models.CharField(max_length=128, db_index=True)
    target_url = models.URLField(max_length=512)
    secret_hash = models.CharField(max_length=128)
    secret_prefix = models.CharField(max_length=16)
    event_types = models.JSONField(default=list)  # ["*"] or specific DomainEventType
    domains = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    @staticmethod
    def hash_secret(raw: str) -> str:
        return hashlib.sha256(raw.encode("utf-8")).hexdigest()

    @classmethod
    def issue(cls, *, owner_principal: str, target_url: str, event_types: list | None = None):
        raw = secrets.token_urlsafe(32)
        return (
            cls.objects.create(
                owner_principal=owner_principal,
                target_url=target_url,
                secret_hash=cls.hash_secret(raw),
                secret_prefix=raw[:12],
                event_types=event_types or ["*"],
            ),
            raw,
        )


class PartnerApplication(models.Model):
    """Open platform partner onboarding — verification via ecosystem workflows."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    partner_code = models.SlugField(max_length=64, unique=True)
    legal_name = models.CharField(max_length=255)
    owner_principal = models.CharField(max_length=128, db_index=True)
    domains = models.JSONField(default=list)  # domain codes requested
    status = models.CharField(max_length=16, default="pending")  # pending|approved|rejected
    contact_email = models.EmailField(blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    decided_at = models.DateTimeField(null=True, blank=True)


class AgricultureFarm(models.Model):
    """Agriculture domain farm registry — identity via principal; money via Payments."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner_principal = models.CharField(max_length=128, db_index=True)
    farm_code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=255)
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, blank=True, default="")
    crop_types = models.JSONField(default=list, blank=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    status = models.CharField(max_length=16, default="active")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class AgricultureListing(models.Model):
    """Produce / input marketplace listing — settlement via Taifa Payments refs."""

    class ListingKind(models.TextChoices):
        PRODUCE = "produce"
        INPUT = "input"
        EQUIPMENT = "equipment"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    farm = models.ForeignKey(
        AgricultureFarm, null=True, blank=True, on_delete=models.SET_NULL, related_name="listings"
    )
    owner_principal = models.CharField(max_length=128, db_index=True)
    kind = models.CharField(max_length=16, choices=ListingKind.choices)
    title = models.CharField(max_length=255)
    quantity_e2 = models.PositiveIntegerField(default=0)
    unit = models.CharField(max_length=16, default="kg")
    price_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    region = models.CharField(max_length=128, blank=True, default="")
    status = models.CharField(max_length=16, default="open")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    logistics_shipment_id = models.UUIDField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class PlatformAuditNote(models.Model):
    """Lightweight ecosystem audit trail complementary to payments.AuditRecord."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor = models.CharField(max_length=128, db_index=True)
    action = models.CharField(max_length=64)
    resource_type = models.CharField(max_length=64)
    resource_id = models.CharField(max_length=64)
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(default=timezone.now, db_index=True)
