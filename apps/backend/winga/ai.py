"""Winga AI assistance — recommendations only; never authorizes payments."""
from __future__ import annotations

from django.conf import settings


class WingaAiError(Exception):
    pass


def assist(*, capability: str, principal: str, payload: dict | None = None) -> dict:
    """Delegate to Taifa AI OS / ecosystem. Hard-blocks payment authorization."""
    blocked = {
        "authorize_payment",
        "capture_payment",
        "settle_commission",
        "transfer_funds",
        "approve_payout",
    }
    if capability in blocked:
        raise WingaAiError("AI must never authorize payments or settlements")

    payload = dict(payload or {})
    payload["winga_assist"] = True
    try:
        from ecosystem.ai import invoke_ai

        result = invoke_ai(
            capability_code=capability,
            principal=principal,
            payload=payload,
            domain_code="winga",
        )
        return {"capability": capability, "result": result, "payment_authorized": False}
    except Exception as exc:
        if getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", True):
            return {
                "capability": capability,
                "result": {
                    "suggestions": payload.get("hints") or [],
                    "note": "fallback assist",
                    "error": str(exc)[:200],
                },
                "payment_authorized": False,
            }
        raise WingaAiError(str(exc)) from exc
