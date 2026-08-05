"""Shared AI platform — delegates to Taifa AI OS when available.

Backward-compatible ecosystem.invoke_ai used by existing clients.
"""
from __future__ import annotations

import time
from importlib import import_module
from typing import Protocol

from django.conf import settings
from django.utils import timezone

from .models import AiCapability, AiInvocation

# Map legacy ecosystem capability codes → AI OS capability codes
_LEGACY_MAP = {
    "recommendations": "recommendation",
    "fraud_detection": "fraud_detection",
    "demand_prediction": "demand_forecast",
    "voice_assistant": "natural_language",
    "ocr": "ocr",
    "route_optimization": "optimization",
    "risk_analysis": "risk_scoring",
    "smart_search": "semantic_search",
}


class AiAdapter(Protocol):
    def invoke(self, *, capability_code: str, payload: dict) -> dict: ...


class StubAiAdapter:
    """Legacy stub kept for environments before AI OS seed."""

    def invoke(self, *, capability_code: str, payload: dict) -> dict:
        return {
            "capability": capability_code,
            "generated_at": timezone.now().isoformat(),
            "result": {"echo": payload},
            "model_version": "ecosystem-legacy-stub-v1",
            "confidence_e4": 5000,
            "reasoning_summary": "Legacy stub",
            "evidence": [],
        }


def resolve_adapter(capability: AiCapability) -> AiAdapter:
    mapping = getattr(settings, "TAIFA_AI_ADAPTERS", None) or {}
    path = mapping.get(capability.code) or capability.adapter_path or ""
    ai_provider = getattr(settings, "TAIFA_AI_PROVIDER", None) or {}
    if not path:
        if ai_provider.get("base_url") and ai_provider.get("api_key"):
            path = "integrations.ai.OpenAICompatibleInferenceAdapter"
        else:
            path = "ecosystem.ai.StubAiAdapter"
    if "Stub" in path and not getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", True):
        if ai_provider.get("base_url") and ai_provider.get("api_key"):
            path = "integrations.ai.OpenAICompatibleInferenceAdapter"
        else:
            raise RuntimeError(
                "stub AI adapters are forbidden in this environment "
                "(configure TAIFA_AI_ADAPTERS_JSON or TAIFA_AI_PROVIDER_JSON)"
            )
    module_name, class_name = path.rsplit(".", 1)
    cls = getattr(import_module(module_name), class_name)
    return cls()


def invoke_ai(
    *,
    capability_code: str,
    principal: str,
    payload: dict | None = None,
    domain_code: str = "",
) -> dict:
    """Prefer AI OS gateway; fall back to ecosystem capability adapters."""
    os_code = _LEGACY_MAP.get(capability_code, capability_code)
    try:
        from ai_os.gateway import infer
        from ai_os.services import seed_ai_os
        from ai_os.models import CapabilityDefinition

        if CapabilityDefinition.objects.count() == 0:
            seed_ai_os()
        if CapabilityDefinition.objects.filter(code=os_code, status="available").exists():
            return infer(
                capability_code=os_code,
                principal=principal,
                payload=payload or {},
                domain_code=domain_code,
            )
    except Exception:
        pass

    capability = AiCapability.objects.get(code=capability_code)
    adapter = resolve_adapter(capability)
    started = time.perf_counter()
    response = adapter.invoke(capability_code=capability_code, payload=payload or {})
    latency_ms = int((time.perf_counter() - started) * 1000)
    AiInvocation.objects.create(
        capability=capability,
        principal=principal,
        domain_code=domain_code,
        request_payload=payload or {},
        response_payload=response,
        model_version=str(response.get("model_version") or "stub-v1"),
        latency_ms=latency_ms,
    )
    return response
