"""Inference gateway — single entry for all domain AI consumption."""
from __future__ import annotations

import time
from importlib import import_module

from django.conf import settings
from django.db import transaction
from django.db.models import F
from django.utils import timezone

from .models import (
    AiDecision,
    CapabilityDefinition,
    FeatureStoreEntry,
    InferenceMetricDaily,
    ModelRegistryEntry,
    SafetyEvent,
)
from .responsible import SafetyError, SafetyViolation, apply_safety


class AiOsError(Exception):
    pass


def _resolve_adapter(model: ModelRegistryEntry | None):
    mapping = getattr(settings, "TAIFA_AI_OS_ADAPTERS", None) or {}
    ai_provider = getattr(settings, "TAIFA_AI_PROVIDER", None) or {}
    if model and model.code in mapping:
        path = mapping[model.code]
    elif model:
        path = model.adapter_path
    elif ai_provider.get("base_url") and ai_provider.get("api_key"):
        path = "integrations.ai.OpenAICompatibleInferenceAdapter"
    else:
        path = "ai_os.adapters.StubInferenceAdapter"
    if "Stub" in path and not getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", True):
        if ai_provider.get("base_url") and ai_provider.get("api_key"):
            path = "integrations.ai.OpenAICompatibleInferenceAdapter"
        else:
            raise AiOsError(
                "stub AI adapters are forbidden in this environment "
                "(set TAIFA_AI_OS_ADAPTERS_JSON or TAIFA_AI_PROVIDER_JSON)"
            )
    module_name, class_name = path.rsplit(".", 1)
    cls = getattr(import_module(module_name), class_name)
    try:
        return cls(model.code if model else None)
    except TypeError:
        return cls()


def _bump_metrics(*, capability_code: str, domain_code: str, latency_ms: int, tokens: int, pending: bool, error: bool):
    day = timezone.localdate()
    row, _ = InferenceMetricDaily.objects.get_or_create(
        date=day,
        capability_code=capability_code,
        domain_code=domain_code or "",
    )
    InferenceMetricDaily.objects.filter(pk=row.pk).update(
        invocations=F("invocations") + 1,
        errors=F("errors") + (1 if error else 0),
        latency_sum_ms=F("latency_sum_ms") + latency_ms,
        token_sum=F("token_sum") + tokens,
        approval_pending=F("approval_pending") + (1 if pending else 0),
    )


def get_features(*, entity_type: str, entity_id: str, feature_set: str) -> dict:
    row = (
        FeatureStoreEntry.objects.filter(
            entity_type=entity_type,
            entity_id=entity_id,
            feature_set=feature_set,
        )
        .order_by("-as_of")
        .first()
    )
    return dict(row.features) if row else {}


def put_features(
    *,
    entity_type: str,
    entity_id: str,
    feature_set: str,
    features: dict,
    model_version: str = "",
) -> FeatureStoreEntry:
    return FeatureStoreEntry.objects.create(
        entity_type=entity_type,
        entity_id=entity_id,
        feature_set=feature_set,
        features=features,
        model_version=model_version,
    )


def infer(
    *,
    capability_code: str,
    principal: str,
    payload: dict | None = None,
    domain_code: str = "",
    agent_code: str = "",
    modality: str = "text",
) -> dict:
    try:
        capability = CapabilityDefinition.objects.select_related("model").get(
            code=capability_code, status="available"
        )
    except CapabilityDefinition.DoesNotExist as exc:
        raise AiOsError(f"unknown or unavailable capability: {capability_code}") from exc

    raw_payload = dict(payload or {})
    started = time.perf_counter()
    try:
        safe_payload, safety_meta = apply_safety(
            principal=principal,
            payload=raw_payload,
            pii_policy=capability.pii_policy,
        )
    except SafetyViolation as exc:
        latency_ms = int((time.perf_counter() - started) * 1000)
        SafetyEvent.objects.create(
            kind=exc.kind,
            severity="high",
            principal=principal,
            detail=exc.detail,
        )
        _bump_metrics(
            capability_code=capability_code,
            domain_code=domain_code,
            latency_ms=latency_ms,
            tokens=0,
            pending=False,
            error=True,
        )
        raise AiOsError(str(exc)) from exc
    except SafetyError as exc:
        latency_ms = int((time.perf_counter() - started) * 1000)
        _bump_metrics(
            capability_code=capability_code,
            domain_code=domain_code,
            latency_ms=latency_ms,
            tokens=0,
            pending=False,
            error=True,
        )
        raise AiOsError(str(exc)) from exc

    return _infer_commit(
        capability=capability,
        principal=principal,
        safe_payload=safe_payload,
        safety_meta=safety_meta,
        domain_code=domain_code,
        agent_code=agent_code,
        modality=modality,
        started=started,
    )


@transaction.atomic
def _infer_commit(
    *,
    capability: CapabilityDefinition,
    principal: str,
    safe_payload: dict,
    safety_meta: dict,
    domain_code: str,
    agent_code: str,
    modality: str,
    started: float,
) -> dict:
    capability_code = capability.code
    entity = safe_payload.get("entity") or {}
    if entity.get("type") and entity.get("id") and entity.get("feature_set"):
        feats = get_features(
            entity_type=str(entity["type"]),
            entity_id=str(entity["id"]),
            feature_set=str(entity["feature_set"]),
        )
        if feats:
            safe_payload = {**safe_payload, "features": feats}

    adapter = _resolve_adapter(capability.model)
    inference = adapter.infer(
        capability_code=capability_code,
        payload=safe_payload,
        modality=modality or (capability.model.modality if capability.model_id else "text"),
    )
    latency_ms = int((time.perf_counter() - started) * 1000)

    requires_approval = bool(capability.requires_human_approval)
    approval_status = "pending" if requires_approval else "not_required"
    workflow_id = None

    if requires_approval and capability.approval_workflow_code:
        try:
            from enterprise import workflow as enterprise_workflow

            inst = enterprise_workflow.start(
                definition_code=capability.approval_workflow_code,
                resource_type="ai_decision",
                resource_id=capability_code,
                context={
                    "principal": principal,
                    "capability": capability_code,
                    "domain_code": domain_code,
                },
            )
            workflow_id = inst.id
        except Exception:
            approval_status = "pending"

    decision = AiDecision.objects.create(
        principal=principal,
        domain_code=domain_code,
        agent_code=agent_code,
        capability_code=capability_code,
        model_version=str(inference.get("model_version") or ""),
        request_payload=safe_payload,
        result=inference.get("result") or {},
        confidence_e4=int(inference.get("confidence_e4") or 0),
        reasoning_summary=str(inference.get("reasoning_summary") or ""),
        evidence=list(inference.get("evidence") or []),
        requires_human_approval=requires_approval,
        approval_status=approval_status,
        workflow_instance_id=workflow_id,
        safety=safety_meta,
        latency_ms=latency_ms,
        token_estimate=int(inference.get("token_estimate") or 0),
    )

    if int(decision.confidence_e4) < 4000:
        SafetyEvent.objects.create(
            kind="hallucination",
            severity="medium",
            principal=principal,
            decision=decision,
            detail={"confidence_e4": decision.confidence_e4},
        )

    _bump_metrics(
        capability_code=capability_code,
        domain_code=domain_code,
        latency_ms=latency_ms,
        tokens=decision.token_estimate,
        pending=requires_approval,
        error=False,
    )

    return {
        "decision_id": str(decision.id),
        "capability": capability_code,
        "agent": agent_code or None,
        "domain_code": domain_code or None,
        "result": decision.result,
        "confidence_e4": decision.confidence_e4,
        "reasoning_summary": decision.reasoning_summary,
        "evidence": decision.evidence,
        "model_version": decision.model_version,
        "requires_human_approval": decision.requires_human_approval,
        "approval_status": decision.approval_status,
        "workflow_instance_id": str(workflow_id) if workflow_id else None,
        "safety": decision.safety,
        "latency_ms": latency_ms,
        "audit_id": str(decision.id),
        "note": (
            "Advisory only. Never bypasses Payments, Identity, Ledger, or Compliance."
            if requires_approval
            else "Advisory output from Taifa AI OS."
        ),
    }


def resolve_approval(*, decision_id, approved: bool, actor: str) -> AiDecision:
    decision = AiDecision.objects.select_for_update().get(pk=decision_id)
    if not decision.requires_human_approval:
        raise AiOsError("decision does not require approval")
    decision.approval_status = "approved" if approved else "denied"
    decision.save(update_fields=["approval_status"])
    if decision.workflow_instance_id:
        try:
            from enterprise import workflow as enterprise_workflow

            enterprise_workflow.advance(
                instance_id=decision.workflow_instance_id,
                actor=actor,
                note="approved" if approved else "denied",
            )
        except Exception:
            pass
    return decision
