"""Seed and maintenance for Taifa AI OS."""
from __future__ import annotations

from django.db import transaction

from . import catalog
from .knowledge import index_all_active
from .models import (
    AgentDefinition,
    AutomationRule,
    CapabilityDefinition,
    DatasetRegistryEntry,
    KnowledgeDocument,
    ModelRegistryEntry,
)


@transaction.atomic
def seed_ai_os() -> dict:
    models = 0
    model_by_family = {}
    for row in catalog.MODELS:
        obj, _ = ModelRegistryEntry.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "modality": row["modality"],
                "version": row["version"],
                "status": "active",
                "adapter_path": "ai_os.adapters.StubInferenceAdapter",
                "deployment": "hybrid",
                "metrics": {"accuracy_e4": 7800, "latency_p50_ms": 40},
            },
        )
        model_by_family[row["modality"]] = obj
        models += 1

    family_model = {
        "nlp": model_by_family.get("text"),
        "vision": model_by_family.get("vision"),
        "speech": model_by_family.get("speech"),
        "reco": model_by_family.get("text"),
        "risk": model_by_family.get("tabular"),
        "forecast": model_by_family.get("tabular"),
        "optimize": model_by_family.get("tabular"),
        "search": model_by_family.get("text"),
        "dev": model_by_family.get("text"),
    }

    caps = 0
    for row in catalog.CAPABILITIES:
        CapabilityDefinition.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "family": row["family"],
                "description": row["name"],
                "model": family_model.get(row["family"]) or model_by_family.get("text"),
                "requires_human_approval": bool(row.get("approval")),
                "approval_workflow_code": row.get("workflow") or "",
                "pii_policy": "redact",
                "status": "available",
            },
        )
        caps += 1

    agents = 0
    for row in catalog.AGENTS:
        AgentDefinition.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "domain_code": row["domain_code"],
                "description": row["name"],
                "capabilities": row["capabilities"],
                "system_prompt": row["system_prompt"],
                "active": True,
            },
        )
        agents += 1

    knowledge = 0
    for row in catalog.KNOWLEDGE_SEED:
        KnowledgeDocument.objects.update_or_create(
            code=row["code"],
            defaults={
                "title": row["title"],
                "category": row["category"],
                "domain_code": row["domain_code"],
                "body": row["body"],
                "citation": row["citation"],
                "active": True,
            },
        )
        knowledge += 1

    automations = 0
    for row in catalog.AUTOMATIONS:
        AutomationRule.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "domain_code": row["domain_code"],
                "trigger_event": row["trigger_event"],
                "capability_code": row["capability_code"],
                "auto_apply": row["auto_apply"],
                "active": True,
            },
        )
        automations += 1

    DatasetRegistryEntry.objects.update_or_create(
        code="mobility-demand-synth",
        defaults={
            "name": "Synthetic mobility demand",
            "domain_code": "mobility",
            "purpose": "training",
            "pii_class": "none",
            "row_count": 100_000,
        },
    )
    DatasetRegistryEntry.objects.update_or_create(
        code="payments-fraud-eval",
        defaults={
            "name": "Payments fraud evaluation set",
            "domain_code": "enterprise",
            "purpose": "eval",
            "pii_class": "masked",
            "row_count": 25_000,
        },
    )

    indexed = index_all_active()
    return {
        "models": models,
        "capabilities": caps,
        "agents": agents,
        "knowledge": knowledge,
        "automations": automations,
        "indexed_vectors": indexed,
    }
