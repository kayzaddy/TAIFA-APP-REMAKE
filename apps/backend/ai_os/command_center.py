"""AI Command Center aggregations."""
from __future__ import annotations

from django.db.models import Sum
from django.utils import timezone

from .models import (
    AgentDefinition,
    AiDecision,
    CapabilityDefinition,
    InferenceMetricDaily,
    KnowledgeDocument,
    ModelRegistryEntry,
    SafetyEvent,
)


def command_center() -> dict:
    today = timezone.localdate()
    metrics = InferenceMetricDaily.objects.filter(date=today)
    inv = metrics.aggregate(
        invocations=Sum("invocations"),
        errors=Sum("errors"),
        latency=Sum("latency_sum_ms"),
        tokens=Sum("token_sum"),
        pending=Sum("approval_pending"),
    )
    total_inv = inv["invocations"] or 0
    latency_avg = int((inv["latency"] or 0) / total_inv) if total_inv else 0
    recent_safety = list(
        SafetyEvent.objects.order_by("-created_at")[:20].values(
            "id", "kind", "severity", "principal", "created_at"
        )
    )
    models = list(
        ModelRegistryEntry.objects.values(
            "code", "name", "version", "status", "modality", "deployment", "metrics"
        )
    )
    by_capability = list(
        metrics.values("capability_code")
        .annotate(
            invocations=Sum("invocations"),
            errors=Sum("errors"),
            tokens=Sum("token_sum"),
        )
        .order_by("-invocations")[:20]
    )
    decisions_today = AiDecision.objects.filter(created_at__date=today).count()
    low_conf = AiDecision.objects.filter(
        created_at__date=today, confidence_e4__lt=4000
    ).count()
    return {
        "generated_at": timezone.now().isoformat(),
        "health": {
            "models_active": ModelRegistryEntry.objects.filter(status="active").count(),
            "capabilities": CapabilityDefinition.objects.filter(status="available").count(),
            "agents": AgentDefinition.objects.filter(active=True).count(),
            "knowledge_docs": KnowledgeDocument.objects.filter(active=True).count(),
            "status": "healthy" if (inv["errors"] or 0) == 0 else "degraded",
        },
        "today": {
            "invocations": total_inv,
            "errors": inv["errors"] or 0,
            "avg_latency_ms": latency_avg,
            "token_estimate": inv["tokens"] or 0,
            "approval_pending": inv["pending"] or 0,
            "decisions": decisions_today,
            "low_confidence": low_conf,
        },
        "by_capability": by_capability,
        "models": models,
        "safety_events": [
            {
                **row,
                "id": str(row["id"]),
                "created_at": row["created_at"].isoformat(),
            }
            for row in recent_safety
        ],
        "cost_stub": {
            "currency": "USD",
            "estimated_daily": round((inv["tokens"] or 0) * 0.000002, 4),
            "note": "Replace with provider billing when live adapters are configured",
        },
        "model_version": "ai-os-command-center-v1",
    }


def decision_detail(decision_id) -> dict:
    d = AiDecision.objects.get(pk=decision_id)
    return {
        "decision_id": str(d.id),
        "principal": d.principal,
        "domain_code": d.domain_code,
        "agent_code": d.agent_code,
        "capability_code": d.capability_code,
        "confidence_e4": d.confidence_e4,
        "reasoning_summary": d.reasoning_summary,
        "evidence": d.evidence,
        "result": d.result,
        "requires_human_approval": d.requires_human_approval,
        "approval_status": d.approval_status,
        "workflow_instance_id": str(d.workflow_instance_id) if d.workflow_instance_id else None,
        "safety": d.safety,
        "latency_ms": d.latency_ms,
        "model_version": d.model_version,
        "created_at": d.created_at.isoformat(),
    }
