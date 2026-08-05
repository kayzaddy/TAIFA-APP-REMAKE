"""Celery tasks for enterprise control-plane work."""
from __future__ import annotations

from celery import shared_task


@shared_task(name="enterprise.drain_outbox")
def drain_outbox_task(limit: int = 100):
    from . import event_bus

    return {"published": event_bus.drain_outbox(limit=limit)}
