"""Domain AI agents — orchestrate capabilities with knowledge citations."""
from __future__ import annotations

from .gateway import AiOsError, infer
from .knowledge import semantic_search
from .models import AgentDefinition


def run_agent(
    *,
    agent_code: str,
    principal: str,
    message: str = "",
    capability_code: str | None = None,
    payload: dict | None = None,
) -> dict:
    try:
        agent = AgentDefinition.objects.get(code=agent_code, active=True)
    except AgentDefinition.DoesNotExist as exc:
        raise AiOsError(f"unknown agent: {agent_code}") from exc

    caps = list(agent.capabilities or [])
    chosen = capability_code or (caps[0] if caps else "natural_language")
    if chosen not in caps and chosen not in {"natural_language", "semantic_search"}:
        raise AiOsError(f"agent {agent_code} cannot use capability {chosen}")

    body = dict(payload or {})
    if message:
        body.setdefault("text", message)
        body.setdefault("prompt", message)
        body.setdefault("query", message)

    citations = []
    if chosen in {"natural_language", "semantic_search", "permit_triage"} or message:
        citations = semantic_search(
            query=message or str(body.get("query") or body.get("text") or agent.name),
            domain_code=agent.domain_code,
            limit=3,
        )
        body["knowledge_hits"] = citations

    decision = infer(
        capability_code=chosen,
        principal=principal,
        payload=body,
        domain_code=agent.domain_code,
        agent_code=agent.code,
        modality="text",
    )
    decision["agent"] = {
        "code": agent.code,
        "name": agent.name,
        "domain_code": agent.domain_code,
        "system_prompt": agent.system_prompt,
    }
    decision["citations"] = citations
    return decision
