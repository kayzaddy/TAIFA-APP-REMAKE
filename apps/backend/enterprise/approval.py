"""Maker-checker approval engine."""
from __future__ import annotations

from django.db import transaction
from django.utils import timezone

from payments.models import DomainEventType

from . import event_bus
from .models import ApprovalRequest, ApprovalStatus


class ApprovalError(Exception):
    pass


def request_approval(
    *,
    action: str,
    resource_type: str,
    resource_id: str,
    maker: str,
    amount_minor: int = 0,
    threshold_minor: int = 0,
    payload: dict | None = None,
) -> ApprovalRequest:
    """Create approval when amount >= threshold (or threshold==0 always requires)."""
    if threshold_minor > 0 and amount_minor < threshold_minor:
        # Auto-approved path — no row needed; caller proceeds.
        raise ApprovalError("below_threshold")
    req = ApprovalRequest.objects.create(
        action=action,
        resource_type=resource_type,
        resource_id=str(resource_id),
        maker=maker,
        amount_minor=amount_minor,
        threshold_minor=threshold_minor,
        payload=payload or {},
    )
    event_bus.publish(
        DomainEventType.APPROVAL_REQUESTED,
        aggregate_type="approval",
        aggregate_id=str(req.id),
        owner=maker,
        payload={"action": action, "amount_minor": amount_minor},
    )
    return req


@transaction.atomic
def decide(*, request_id, checker: str, approve: bool, reason: str = "") -> ApprovalRequest:
    req = ApprovalRequest.objects.select_for_update().get(pk=request_id)
    if req.status != ApprovalStatus.PENDING:
        raise ApprovalError(f"not pending: {req.status}")
    if req.maker == checker:
        raise ApprovalError("maker cannot checker own request")
    req.checker = checker
    req.status = ApprovalStatus.APPROVED if approve else ApprovalStatus.DENIED
    req.reason = reason
    req.decided_at = timezone.now()
    req.save()
    event_bus.publish(
        DomainEventType.APPROVAL_GRANTED if approve else DomainEventType.APPROVAL_DENIED,
        aggregate_type="approval",
        aggregate_id=str(req.id),
        owner=checker,
        payload={"action": req.action, "approve": approve},
    )
    return req
