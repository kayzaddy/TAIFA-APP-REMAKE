"""Payment lifecycle state machine.

Illegal transitions are rejected. Money never moves on an illegal path — the
orchestrator / engine must call `assert_transition` before mutating status.
"""
from __future__ import annotations

from .models import TransactionStatus

# Terminal statuses: no further money-moving transitions (except reverse → reversed
# is modeled as a transition from succeeded only).
_TERMINAL = {
    TransactionStatus.REJECTED,
    TransactionStatus.FAILED,
    TransactionStatus.CANCELLED,
    TransactionStatus.REVERSED,
}

# from_status → allowed to_status
ALLOWED: dict[str, frozenset[str]] = {
    TransactionStatus.PENDING: frozenset({
        TransactionStatus.APPROVED,
        TransactionStatus.REJECTED,
        TransactionStatus.PROCESSING,
        TransactionStatus.FAILED,
        TransactionStatus.CANCELLED,
        TransactionStatus.SUCCEEDED,  # sync wallet transfer / auto paths
    }),
    TransactionStatus.APPROVED: frozenset({
        TransactionStatus.PROCESSING,
        TransactionStatus.REJECTED,
        TransactionStatus.FAILED,
        TransactionStatus.SUCCEEDED,
        TransactionStatus.CANCELLED,
    }),
    TransactionStatus.PROCESSING: frozenset({
        TransactionStatus.SUCCEEDED,
        TransactionStatus.FAILED,
        TransactionStatus.CANCELLED,
        TransactionStatus.PROCESSING,  # idempotent re-entry
    }),
    TransactionStatus.SUCCEEDED: frozenset({
        TransactionStatus.REVERSED,
        TransactionStatus.SUCCEEDED,  # idempotent settle
    }),
    TransactionStatus.REJECTED: frozenset({TransactionStatus.REJECTED}),
    TransactionStatus.FAILED: frozenset({TransactionStatus.FAILED}),
    TransactionStatus.CANCELLED: frozenset({TransactionStatus.CANCELLED}),
    TransactionStatus.REVERSED: frozenset({TransactionStatus.REVERSED}),
}


class IllegalStateTransition(Exception):
    def __init__(self, current: str, target: str):
        self.current = current
        self.target = target
        super().__init__(f"Illegal payment transition {current!r} → {target!r}")


def can_transition(current: str, target: str) -> bool:
    if current == target:
        return True
    allowed = ALLOWED.get(current, frozenset())
    return target in allowed


def assert_transition(current: str, target: str) -> None:
    if not can_transition(current, target):
        raise IllegalStateTransition(current, target)


def is_terminal(status: str) -> bool:
    return status in _TERMINAL
