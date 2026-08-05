"""Configurable workflow engine — step sequences without hardcoded business processes."""
from __future__ import annotations

from django.db import transaction
from django.utils import timezone

from payments.models import DomainEventType

from . import event_bus
from .models import WorkflowDefinition, WorkflowInstance


class WorkflowError(Exception):
    pass


def start(*, definition_code: str, resource_type: str, resource_id: str, context: dict | None = None) -> WorkflowInstance:
    definition = WorkflowDefinition.objects.get(code=definition_code, active=True)
    inst = WorkflowInstance.objects.create(
        definition=definition,
        resource_type=resource_type,
        resource_id=str(resource_id),
        context=context or {},
        status="running",
        current_step=0,
    )
    event_bus.publish(
        DomainEventType.WORKFLOW_STARTED,
        aggregate_type="workflow",
        aggregate_id=str(inst.id),
        payload={"definition": definition_code, "resource_type": resource_type},
    )
    return inst


@transaction.atomic
def advance(*, instance_id, actor: str, note: str = "") -> WorkflowInstance:
    inst = WorkflowInstance.objects.select_for_update().select_related("definition").get(pk=instance_id)
    if inst.status != "running":
        raise WorkflowError(f"workflow not running: {inst.status}")
    steps = inst.definition.steps or []
    inst.current_step += 1
    ctx = dict(inst.context or {})
    history = list(ctx.get("history", []))
    history.append({"actor": actor, "note": note, "step": inst.current_step})
    ctx["history"] = history
    inst.context = ctx
    if inst.current_step >= len(steps):
        inst.status = "completed"
        inst.completed_at = timezone.now()
        event_bus.publish(
            DomainEventType.WORKFLOW_COMPLETED,
            aggregate_type="workflow",
            aggregate_id=str(inst.id),
            payload={"definition": inst.definition.code},
        )
    inst.save()
    return inst
