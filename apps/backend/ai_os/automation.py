"""Automation engine — AI drafts and optional auto-apply for routine work."""
from __future__ import annotations

from .gateway import AiOsError, infer
from .models import AutomationRule, AutomationRun


def run_automation(
    *,
    rule_code: str,
    principal: str,
    event_payload: dict | None = None,
) -> dict:
    try:
        rule = AutomationRule.objects.get(code=rule_code, active=True)
    except AutomationRule.DoesNotExist as exc:
        raise AiOsError(f"unknown automation rule: {rule_code}") from exc

    payload = {
        "text": str((event_payload or {}).get("text") or rule.name),
        "event": rule.trigger_event,
        **(event_payload or {}),
        **(rule.config or {}),
    }
    decision = infer(
        capability_code=rule.capability_code,
        principal=principal,
        payload=payload,
        domain_code=rule.domain_code,
        agent_code="enterprise_ops_agent",
    )
    applied = False
    output = {
        "draft": decision.get("result"),
        "auto_apply": rule.auto_apply,
        "applied": False,
    }
    if rule.auto_apply and not decision.get("requires_human_approval"):
        # Auto-apply means record an operational draft action — never ledger writes.
        output["applied"] = True
        output["action"] = {
            "type": "route_or_tag",
            "label": (decision.get("result") or {}).get("label")
            or (decision.get("result") or {}).get("queue")
            or "processed",
        }
        applied = True

    run = AutomationRun.objects.create(
        rule=rule,
        decision_id=decision.get("decision_id"),
        status="applied" if applied else "drafted",
        output=output,
    )
    return {
        "run_id": str(run.id),
        "rule": rule.code,
        "status": run.status,
        "decision": decision,
        "output": output,
    }
