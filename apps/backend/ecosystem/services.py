"""Ecosystem services — seed catalog, enable modules, start bound workflows."""
from __future__ import annotations

from django.db import transaction
from django.utils import timezone

from enterprise import workflow as enterprise_workflow
from enterprise.models import WorkflowDefinition

from . import catalog
from .models import (
    AgricultureFarm,
    AgricultureListing,
    AiCapability,
    EcosystemWorkflowBinding,
    IndustryDomain,
    PlatformAuditNote,
    PrincipalModuleEnablement,
    SharedService,
    SuperAppModule,
)


class PlatformError(Exception):
    pass


@transaction.atomic
def seed_ecosystem_catalog() -> dict:
    services = 0
    for row in catalog.SHARED_SERVICES:
        SharedService.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "description": row["description"],
                "api_base": row["api_base"],
                "status": row["status"],
                "owner_team": row["owner_team"],
            },
        )
        services += 1

    domains = 0
    domain_by_code: dict[str, IndustryDomain] = {}
    for row in catalog.DOMAINS:
        obj, _ = IndustryDomain.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "description": row["description"],
                "icon": row["icon"],
                "route": row["route"],
                "api_base": row["api_base"],
                "status": row["status"],
                "sort_order": row["sort_order"],
                "required_services": row["required_services"],
                "capabilities": row["capabilities"],
            },
        )
        domain_by_code[row["code"]] = obj
        domains += 1

    modules = 0
    for row in catalog.MODULES:
        domain = domain_by_code.get(row["domain_code"]) if row.get("domain_code") else None
        SuperAppModule.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "domain": domain,
                "route": row["route"],
                "icon": row["icon"],
                "default_enabled": row["default_enabled"],
                "sort_order": row["sort_order"],
                "category": row["category"],
                "active": True,
            },
        )
        modules += 1

    workflows = 0
    for row in catalog.WORKFLOW_BINDINGS:
        steps = [
            {"code": "submit", "role": "applicant"},
            {"code": "review", "role": "ops"},
            {"code": "approve", "role": "supervisor"},
        ]
        WorkflowDefinition.objects.update_or_create(
            code=row["workflow_definition_code"],
            defaults={"name": row["name"], "steps": steps, "active": True},
        )
        EcosystemWorkflowBinding.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "domain_code": row["domain_code"],
                "workflow_definition_code": row["workflow_definition_code"],
                "description": row["description"],
                "example_resource_type": row["example_resource_type"],
                "active": True,
            },
        )
        workflows += 1

    ai = 0
    for row in catalog.AI_CAPABILITIES:
        AiCapability.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "description": row["description"],
                "status": "available",
                "adapter_path": "ecosystem.ai.StubAiAdapter",
            },
        )
        ai += 1

    return {
        "shared_services": services,
        "domains": domains,
        "modules": modules,
        "workflows": workflows,
        "ai_capabilities": ai,
    }


def ecosystem_blueprint() -> dict:
    return {
        "shared_services": list(
            SharedService.objects.values(
                "code", "name", "status", "api_base", "owner_team", "description"
            )
        ),
        "domains": list(
            IndustryDomain.objects.values(
                "code",
                "name",
                "status",
                "route",
                "api_base",
                "required_services",
                "capabilities",
                "sort_order",
            )
        ),
        "modules": list(
            SuperAppModule.objects.filter(active=True).values(
                "code",
                "name",
                "route",
                "icon",
                "default_enabled",
                "category",
                "sort_order",
                "domain__code",
            )
        ),
        "workflows": list(
            EcosystemWorkflowBinding.objects.filter(active=True).values(
                "code",
                "name",
                "domain_code",
                "workflow_definition_code",
                "description",
            )
        ),
        "ai_capabilities": list(
            AiCapability.objects.values("code", "name", "status", "description")
        ),
        "open_platform": {
            "rest": "/api/v1/",
            "openapi": "/api/schema",
            "docs": "/api/docs",
            "webhooks": "/api/v1/ecosystem/webhooks/",
            "sdks": ["python", "javascript", "flutter"],
            "graphql": "planned — REST is authoritative in v1",
        },
        "model_version": "ecosystem-blueprint-v1",
    }


def list_enabled_modules(*, principal: str) -> list[dict]:
    modules = list(SuperAppModule.objects.filter(active=True).select_related("domain"))
    enablements = {
        e.module_id: e
        for e in PrincipalModuleEnablement.objects.filter(principal=principal)
    }
    rows = []
    for module in modules:
        enablement = enablements.get(module.id)
        if enablement is not None:
            enabled = enablement.enabled
        else:
            enabled = module.default_enabled
        rows.append(
            {
                "code": module.code,
                "name": module.name,
                "route": module.route,
                "icon": module.icon,
                "category": module.category,
                "domain": module.domain.code if module.domain_id else None,
                "enabled": enabled,
                "sort_order": module.sort_order,
            }
        )
    return sorted(rows, key=lambda r: r["sort_order"])


@transaction.atomic
def set_module_enabled(*, principal: str, module_code: str, enabled: bool) -> dict:
    try:
        module = SuperAppModule.objects.get(code=module_code, active=True)
    except SuperAppModule.DoesNotExist as exc:
        raise PlatformError(f"unknown module: {module_code}") from exc
    now = timezone.now()
    row, _ = PrincipalModuleEnablement.objects.update_or_create(
        principal=principal,
        module=module,
        defaults={
            "enabled": enabled,
            "enabled_at": now if enabled else None,
            "disabled_at": None if enabled else now,
        },
    )
    PlatformAuditNote.objects.create(
        actor=principal,
        action="module.enable" if enabled else "module.disable",
        resource_type="super_app_module",
        resource_id=module.code,
        payload={"enabled": enabled},
    )
    return {
        "code": module.code,
        "enabled": row.enabled,
        "route": module.route,
    }


def start_ecosystem_workflow(
    *,
    binding_code: str,
    resource_id: str,
    actor: str,
    context: dict | None = None,
):
    try:
        binding = EcosystemWorkflowBinding.objects.get(code=binding_code, active=True)
    except EcosystemWorkflowBinding.DoesNotExist as exc:
        raise PlatformError(f"unknown workflow binding: {binding_code}") from exc
    inst = enterprise_workflow.start(
        definition_code=binding.workflow_definition_code,
        resource_type=binding.example_resource_type or binding.code,
        resource_id=str(resource_id),
        context={**(context or {}), "actor": actor, "binding": binding.code},
    )
    PlatformAuditNote.objects.create(
        actor=actor,
        action="workflow.start",
        resource_type="workflow_instance",
        resource_id=str(inst.id),
        payload={"binding": binding.code, "definition": binding.workflow_definition_code},
    )
    return inst


def register_farm(
    *,
    owner: str,
    farm_code: str,
    name: str,
    region: str,
    district: str = "",
    crop_types: list | None = None,
    latitude=None,
    longitude=None,
) -> AgricultureFarm:
    farm = AgricultureFarm.objects.create(
        owner_principal=owner,
        farm_code=farm_code,
        name=name,
        region=region,
        district=district,
        crop_types=crop_types or [],
        latitude=latitude,
        longitude=longitude,
    )
    PlatformAuditNote.objects.create(
        actor=owner,
        action="agriculture.farm.register",
        resource_type="agriculture_farm",
        resource_id=str(farm.id),
        payload={"farm_code": farm_code, "region": region},
    )
    return farm


def create_agriculture_listing(
    *,
    owner: str,
    kind: str,
    title: str,
    price_minor: int,
    quantity_e2: int = 0,
    unit: str = "kg",
    region: str = "",
    farm_id=None,
) -> AgricultureListing:
    return AgricultureListing.objects.create(
        owner_principal=owner,
        farm_id=farm_id,
        kind=kind,
        title=title,
        price_minor=price_minor,
        quantity_e2=quantity_e2,
        unit=unit,
        region=region,
        status="open",
    )


def observability_snapshot() -> dict:
    from django.db import connection

    db_ok = True
    try:
        connection.ensure_connection()
    except Exception:
        db_ok = False
    return {
        "service": "taifa-platform",
        "domains_active": IndustryDomain.objects.filter(status="active").count(),
        "modules_active": SuperAppModule.objects.filter(active=True).count(),
        "shared_services": SharedService.objects.count(),
        "ai_capabilities": AiCapability.objects.count(),
        "database": "up" if db_ok else "down",
        "probes": {
            "liveness": "/healthz",
            "readiness": "/readyz",
            "dependencies": "/depsz",
            "metrics": "/metrics",
        },
        "model_version": "ecosystem-observability-v1",
    }
