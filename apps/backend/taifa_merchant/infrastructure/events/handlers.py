from __future__ import annotations

import logging

from taifa_merchant.domain.events import DomainEvent
from taifa_merchant.infrastructure.events.dispatcher import register_handler
from taifa_merchant.infrastructure.models import AuditLog, Merchant, MerchantActivity, Merchant

logger = logging.getLogger(__name__)


def _audit_from_event(event: DomainEvent) -> None:
    merchant_id = event.payload.get("merchant_id")
    if not merchant_id:
        return
    try:
        merchant = Merchant.objects.get(pk=merchant_id)
    except Merchant.DoesNotExist:
        return
    AuditLog.objects.create(
        merchant=merchant,
        actor_identity_user_id=event.payload.get("actor_id"),
        action=event.name,
        resource_type=event.payload.get("resource_type", ""),
        resource_id=str(event.aggregate_id),
        metadata=event.payload,
    )
    MerchantActivity.objects.create(
        merchant=merchant,
        actor_identity_user_id=event.payload.get("actor_id"),
        activity_type=event.name,
        summary=event.name.replace(".", " ").title(),
        metadata=event.payload,
    )


register_handler(_audit_from_event)
