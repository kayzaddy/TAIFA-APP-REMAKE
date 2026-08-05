"""Domain event store — immutable business history (not money truth)."""
from __future__ import annotations

from .models import DomainEvent, DomainEventType, Transaction


def emit(
    event_type: str,
    *,
    transaction: Transaction | None = None,
    owner: str = "",
    payload: dict | None = None,
) -> DomainEvent:
    return DomainEvent.objects.create(
        event_type=event_type,
        transaction=transaction,
        owner=owner or (transaction.owner if transaction else ""),
        payload=payload or {},
    )


def payment_settled(txn: Transaction) -> DomainEvent:
    return emit(
        DomainEventType.PAYMENT_SETTLED,
        transaction=txn,
        payload={"status": txn.status, "type": txn.type, "amount_minor": txn.amount_minor},
    )


def for_status(txn: Transaction, previous: str) -> DomainEvent | None:
    """Map a status transition to a domain event (best-effort taxonomy)."""
    mapping = {
        ("pending", "approved"): DomainEventType.PAYMENT_AUTHORIZED,
        ("pending", "processing"): DomainEventType.PAYMENT_CAPTURED,
        ("approved", "processing"): DomainEventType.PAYMENT_CAPTURED,
        ("processing", "succeeded"): DomainEventType.PAYMENT_SETTLED,
        ("approved", "succeeded"): DomainEventType.PAYMENT_SETTLED,
        ("pending", "succeeded"): DomainEventType.PAYMENT_SETTLED,
        ("pending", "failed"): DomainEventType.PAYMENT_FAILED,
        ("processing", "failed"): DomainEventType.PAYMENT_FAILED,
        ("pending", "rejected"): DomainEventType.PAYMENT_REJECTED,
        ("approved", "rejected"): DomainEventType.PAYMENT_REJECTED,
        ("pending", "cancelled"): DomainEventType.PAYMENT_CANCELLED,
        ("succeeded", "reversed"): DomainEventType.REVERSAL_COMPLETED,
    }
    if txn.type == "withdrawal":
        wd = {
            ("pending", "approved"): DomainEventType.WITHDRAWAL_APPROVED,
            ("processing", "succeeded"): DomainEventType.WITHDRAWAL_COMPLETED,
            ("approved", "succeeded"): DomainEventType.WITHDRAWAL_COMPLETED,
            ("pending", "rejected"): DomainEventType.WITHDRAWAL_REJECTED,
            ("approved", "rejected"): DomainEventType.WITHDRAWAL_REJECTED,
        }
        mapping.update(wd)
    if txn.type == "refund" and txn.status == "succeeded":
        return emit(
            DomainEventType.REFUND_COMPLETED,
            transaction=txn,
            payload={"parent": str(txn.parent_id), "amount_minor": txn.amount_minor},
        )
    et = mapping.get((previous, txn.status))
    if not et:
        return None
    return emit(et, transaction=txn, payload={"from": previous, "to": txn.status})
