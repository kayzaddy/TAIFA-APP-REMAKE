"""Webhook Processor.

Provider callbacks are persisted first, then matched to a Transaction and
settled via the TransactionEngine (called only from the Payment Orchestrator
for API/webhook entry points). Direct callers in tests may pass an engine.
"""
from __future__ import annotations

from django.db import transaction as db_transaction
from django.utils import timezone

from .engine import TransactionEngine, default_engine
from .models import Transaction, WebhookEvent


def _extract_stk(payload: dict) -> tuple[str, str]:
    stk = (payload or {}).get("Body", {}).get("stkCallback", {})
    return str(stk.get("CheckoutRequestID", "")), str(stk.get("ResultCode", ""))


def process_mpesa_stk_callback(payload: dict, engine: TransactionEngine | None = None) -> WebhookEvent:
    engine = engine or default_engine()
    checkout_id, result_code = _extract_stk(payload)

    event = WebhookEvent.objects.create(
        provider="mpesa",
        event_type="stk_callback",
        provider_ref=checkout_id,
        payload=payload,
    )

    with db_transaction.atomic():
        txn = (
            Transaction.objects.select_for_update()
            .filter(provider_ref=checkout_id)
            .first()
        )
        if txn is None:
            event.result = "unmatched"
        elif result_code == "0":
            engine.settle_success(txn)
            event.result = "succeeded"
        else:
            engine.settle_failure(
                txn,
                reason=(payload.get("Body", {}).get("stkCallback", {}).get("ResultDesc", "")),
            )
            event.result = "failed"

    event.processed = True
    event.processed_at = timezone.now()
    event.save(update_fields=["processed", "result", "processed_at"])
    return event
