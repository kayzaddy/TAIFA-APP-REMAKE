"""Pluggable inference adapters — cloud/on-prem/hybrid swap via model registry."""
from __future__ import annotations

from typing import Protocol

from django.utils import timezone


class InferenceAdapter(Protocol):
    def infer(self, *, capability_code: str, payload: dict, modality: str = "text") -> dict: ...


class StubInferenceAdapter:
    """Deterministic multimodal stub for environments without GPU/LLM backends."""

    def infer(self, *, capability_code: str, payload: dict, modality: str = "text") -> dict:
        now = timezone.now().isoformat()
        text = str(payload.get("text") or payload.get("query") or payload.get("prompt") or "")
        handlers = {
            "natural_language": lambda: {
                "reply": _citizen_reply(text, payload.get("locale", "sw-TZ")),
                "locale": payload.get("locale", "sw-TZ"),
            },
            "computer_vision": lambda: {
                "labels": [{"label": payload.get("hint", "object"), "score_e4": 8200}],
                "boxes": [],
            },
            "ocr": lambda: {
                "text": payload.get("hint") or "EXTRACTED_TEXT",
                "fields": payload.get("expected_fields") or {},
                "pages": 1,
            },
            "speech_recognition": lambda: {
                "transcript": payload.get("hint") or text or "habari",
                "locale": payload.get("locale", "sw-TZ"),
            },
            "speech_synthesis": lambda: {
                "audio_ref": "stub://tts/v1",
                "text": text or "Karibu Taifa",
                "locale": payload.get("locale", "sw-TZ"),
            },
            "recommendation": lambda: {
                "items": [
                    {"id": "mobility", "score_e4": 9100, "reason": "commute_pattern"},
                    {"id": "commerce", "score_e4": 7400, "reason": "nearby_merchants"},
                ]
            },
            "fraud_detection": lambda: {
                "risk_band": "low",
                "score_e4": 1400,
                "signals": ["device_trusted", "velocity_ok"],
                "note": "Advisory — payments risk engine is authoritative for holds",
            },
            "risk_scoring": lambda: {
                "band": "moderate",
                "score_e4": 4200,
                "factors": payload.get("factors") or ["history_limited"],
            },
            "forecasting": lambda: {
                "horizon": payload.get("horizon", "7d"),
                "point_forecast": float(payload.get("baseline", 100)) * 1.08,
                "interval": {"low": 0.9, "high": 1.2},
            },
            "optimization": lambda: {
                "objective": payload.get("objective", "minimize_cost"),
                "suggestion": payload.get("candidates") or [],
                "estimated_improvement_e4": 1200,
            },
            "classification": lambda: {
                "label": payload.get("candidates", ["general"])[0]
                if payload.get("candidates")
                else "general",
                "scores": {"general": 0.62, "urgent": 0.21},
            },
            "semantic_search": lambda: {"query": text, "note": "use knowledge.search for citations"},
            "knowledge_graph_query": lambda: {
                "nodes": [{"id": "payments", "rel": "depends_on", "to": "identity"}],
                "edges": 1,
            },
            "embeddings": lambda: {
                "vector": _hash_embed(text or "empty", dims=32),
                "dims": 32,
            },
            "translation": lambda: {
                "source": payload.get("source_lang", "sw"),
                "target": payload.get("target_lang", "en"),
                "text": _translate_stub(text),
            },
            "document_intelligence": lambda: {
                "doc_type": payload.get("doc_type", "generic"),
                "fields": payload.get("expected_fields") or {"title": text[:80]},
                "summary": (text or "document")[:240],
            },
            "aml_monitoring": lambda: {
                "alert_band": "none",
                "score_e4": 800,
                "patterns": [],
                "note": "Advisory — compliance officers decide filings",
            },
            "credit_scoring": lambda: {
                "score_e4": 6500,
                "band": "pass",
                "drivers": ["repayment_history", "wallet_tenure"],
            },
            "liquidity_forecast": lambda: {
                "horizon_days": int(payload.get("horizon_days", 7)),
                "projected_balance_minor": int(payload.get("baseline_minor", 0) * 1.02),
            },
            "demand_forecast": lambda: {
                "horizon_minutes": int(payload.get("horizon_minutes", 60)),
                "predicted_requests": int(float(payload.get("baseline", 20)) * 1.15),
            },
            "eta_prediction": lambda: {
                "eta_seconds": int(payload.get("baseline_seconds", 600) * 1.05),
                "traffic_factor_e4": 10500,
            },
            "dispatch_optimize": lambda: {
                "ranked_driver_ids": payload.get("driver_ids") or [],
                "strategy": "load_balance",
            },
            "clinical_doc_assist": lambda: {
                "draft_note": "SOAP draft (non-diagnostic): " + (text[:200] or "no input"),
                "disclaimer": "Not a diagnosis",
            },
            "prescription_verify_support": lambda: {
                "flags": [],
                "completeness_e4": 8800,
                "disclaimer": "Pharmacist verification required",
            },
            "inventory_forecast": lambda: {
                "sku": payload.get("sku", "unknown"),
                "suggested_reorder": int(payload.get("baseline", 10)),
            },
            "pricing_optimize": lambda: {
                "suggested_price_minor": int(payload.get("price_minor", 1000)),
                "elasticity_note": "stub",
            },
            "permit_triage": lambda: {
                "queue": "standard",
                "completeness_e4": 7000,
                "missing_fields": payload.get("missing") or [],
            },
            "personalized_learning": lambda: {
                "next_modules": ["numeracy-1", "civic-basics"],
                "pace": "adaptive",
            },
            "crop_planning": lambda: {
                "crops": payload.get("crops") or ["maize"],
                "window": "seasonal_stub",
                "weather_note": payload.get("weather") or "use local met office",
            },
            "disease_image_recognition": lambda: {
                "disease": payload.get("hint", "healthy"),
                "confidence_e4": 7600,
                "action": "monitor",
            },
            "architecture_assist": lambda: {
                "advice": "Prefer shared Payments/Identity; add domain modules via ecosystem catalog.",
            },
            "code_review_assist": lambda: {
                "findings": [{"severity": "info", "note": "Ensure AI never mutates ledger"}],
            },
            "incident_analysis": lambda: {
                "likely_cause": payload.get("symptoms") or "unknown",
                "next_steps": ["check /depsz", "review Celery", "inspect audit trail"],
            },
        }
        body = handlers.get(capability_code, lambda: {"echo": payload, "modality": modality})()
        confidence = int(payload.get("force_confidence_e4") or _default_confidence(capability_code))
        reasoning = _reasoning(capability_code, body)
        evidence = _evidence(capability_code, payload)
        return {
            "capability": capability_code,
            "generated_at": now,
            "result": body,
            "confidence_e4": confidence,
            "reasoning_summary": reasoning,
            "evidence": evidence,
            "model_version": f"stub-{modality}-v1",
            "token_estimate": max(16, len(text) // 4 + 32),
        }


def _default_confidence(code: str) -> int:
    if code in {"fraud_detection", "aml_monitoring", "credit_scoring", "risk_scoring"}:
        return 6800
    if code in {"ocr", "document_intelligence", "classification"}:
        return 8000
    return 7500


def _reasoning(code: str, body: dict) -> str:
    if code == "fraud_detection":
        return f"Heuristic risk band={body.get('risk_band')} from device and velocity signals."
    if code == "demand_forecast":
        return "Seasonal uplift applied to baseline demand for the requested horizon."
    if code == "natural_language":
        return "Template citizen assistant response with locale awareness."
    return f"Stub inference for capability '{code}' using deterministic heuristics."


def _evidence(code: str, payload: dict) -> list:
    evidence = [{"type": "capability", "ref": code}]
    if payload.get("features"):
        evidence.append({"type": "feature_store", "ref": "inline_features"})
    if payload.get("document_id"):
        evidence.append({"type": "document", "ref": str(payload["document_id"])})
    if payload.get("gps"):
        evidence.append({"type": "gps_context", "ref": "client_gps"})
    return evidence


def _hash_embed(text: str, dims: int = 32) -> list[float]:
    vals = []
    for i in range(dims):
        acc = 0
        for ch in text:
            acc = (acc * 31 + ord(ch) + i * 17) % 10_007
        vals.append((acc / 10_007.0) * 2 - 1)
    return vals


def _citizen_reply(text: str, locale: str) -> str:
    lower = text.lower()
    if any(w in lower for w in ("wallet", "pesa", "malipo")):
        return (
            "Unaweza kuona salio kwenye Wallet. Malipo yanashughulikiwa na Taifa Payments."
            if locale.startswith("sw")
            else "Check your balance in Wallet. All money movement uses Taifa Payments."
        )
    if any(w in lower for w in ("ride", "boda", "safari")):
        return (
            "Fungua Mobility kuomba safari. AI inashauri; usambazaji unafanywa na injini ya mobility."
            if locale.startswith("sw")
            else "Open Mobility to request a ride. AI advises; dispatch remains the mobility engine."
        )
    if locale.startswith("sw"):
        return "Karibu Taifa AI OS. Ninaweza kukusaidia kuhusu wallet, mobility, serikali, au biashara."
    return "Welcome to Taifa AI OS. I can help with wallet, mobility, government, or business topics."


def _translate_stub(text: str) -> str:
    if not text:
        return ""
    return f"[en] {text}"
