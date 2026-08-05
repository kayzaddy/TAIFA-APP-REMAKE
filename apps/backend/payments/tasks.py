"""Celery tasks for async payment work.

In production the webhook endpoint persists the raw event and offloads
processing here (keeping the HTTP response fast and retries durable). In
dev/tests `CELERY_TASK_ALWAYS_EAGER` runs them inline.
"""
from __future__ import annotations

from celery import shared_task


@shared_task(bind=True, max_retries=5, default_retry_delay=10)
def process_mpesa_stk_callback_task(self, payload: dict):
    from .webhooks import process_mpesa_stk_callback

    event = process_mpesa_stk_callback(payload)
    return {"event_id": str(event.id), "result": event.result}


@shared_task(name="payments.reconcile_ledger")
def reconcile_ledger_task():
    """Daily (or on-demand) ledger integrity check. Updates Prometheus gauges."""
    from .reconciliation import run_reconciliation

    result = run_reconciliation(record=True)
    return {
        "ok": result.ok,
        "break_count": result.break_count,
        "entries_checked": result.entries_checked,
        "postings_checked": result.postings_checked,
        "by_check": result.by_check(),
    }


@shared_task(name="payments.ops_heartbeat")
def ops_heartbeat_task():
    """Periodic ops heartbeat — proves beat + worker path is alive."""
    import logging

    from django.utils import timezone

    logging.getLogger("payments.ops").info(
        "ops_heartbeat ok at %s", timezone.now().isoformat()
    )
    return {"ok": True, "at": timezone.now().isoformat()}

