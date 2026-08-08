"""Standing orders — scheduling math + the execution loop Celery beat drives.

Kept separate from the views/model so the beat task, a management command, and
tests can all call `run_due_recurring_payments` without importing DRF.
"""
from __future__ import annotations

from dataclasses import dataclass

from dateutil.relativedelta import relativedelta
from django.db import transaction as db_transaction
from django.utils import timezone

from .models import RecurringInterval, RecurringPayment, RecurringPaymentStatus
from .money import Currency, Money
from .orchestrator import OrchestratorContext, default_orchestrator

_DELTA = {
    RecurringInterval.DAILY: relativedelta(days=1),
    RecurringInterval.WEEKLY: relativedelta(weeks=1),
    RecurringInterval.MONTHLY: relativedelta(months=1),
}


def next_run_after(when, interval: str):
    """Month-safe advance (relativedelta clamps day-of-month overflow, e.g.
    Jan 31 + 1 month → Feb 28/29, not an invalid date or a rollover to March)."""
    return when + _DELTA[RecurringInterval(interval)]


@dataclass
class RunOutcome:
    id: str
    status: str  # "succeeded" | "failed" | "paused"


def _run_one(rp: RecurringPayment) -> RunOutcome:
    occurrence_key = f"recurring-{rp.id}-{rp.next_run_at.isoformat()}"
    ctx = OrchestratorContext(actor="system:recurring", device_id="", ip=None)
    amount = Money(rp.amount_minor, Currency.from_code(rp.currency))
    outcome = default_orchestrator().initiate_p2p(
        ctx=ctx,
        payer=rp.owner,
        payee=rp.payee,
        amount=amount,
        idempotency_key=occurrence_key,
        note=rp.note or "Standing order",
        counterparty_label=rp.payee,
    )
    txn = outcome.transaction

    with db_transaction.atomic():
        locked = RecurringPayment.objects.select_for_update().get(pk=rp.pk)
        locked.last_run_at = timezone.now()
        locked.last_transaction = txn
        locked.next_run_at = next_run_after(locked.next_run_at, locked.interval)
        if txn.status == "succeeded":
            locked.consecutive_failures = 0
            status_out = "succeeded"
        else:
            locked.consecutive_failures += 1
            status_out = "failed"
            if locked.consecutive_failures >= locked.max_consecutive_failures:
                locked.status = RecurringPaymentStatus.PAUSED
                status_out = "paused"
        locked.save(
            update_fields=[
                "last_run_at", "last_transaction", "next_run_at",
                "consecutive_failures", "status", "updated_at",
            ]
        )
    return RunOutcome(id=str(rp.id), status=status_out)


def run_due_recurring_payments(*, now=None, limit: int = 500) -> list[RunOutcome]:
    """Execute every ACTIVE standing order whose `next_run_at` has passed.
    Safe to call repeatedly (each occurrence has its own idempotency key, and
    `next_run_at` only advances after a completed attempt)."""
    now = now or timezone.now()
    due = RecurringPayment.objects.filter(
        status=RecurringPaymentStatus.ACTIVE, next_run_at__lte=now
    ).order_by("next_run_at")[:limit]
    return [_run_one(rp) for rp in due]
