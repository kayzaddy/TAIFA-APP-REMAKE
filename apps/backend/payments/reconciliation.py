"""Ledger reconciliation — prove the books still balance.

Runs as a management command (`reconcile_ledger`) or Celery task. Checks are
read-only; they never mutate the append-only ledger. Provider statement matching
is intentionally out of scope until rail statement APIs are wired.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime

from django.utils import timezone

from .models import (
    LedgerEntry,
    Posting,
    PostingDirection,
    Transaction,
    TransactionStatus,
)

# Last run snapshot for Prometheus scrapes (updated by `run_reconciliation`).
_last_result: "ReconciliationResult | None" = None


@dataclass(frozen=True)
class Issue:
    check: str
    detail: str
    ref: str = ""


@dataclass
class ReconciliationResult:
    ok: bool
    checked_at: datetime
    entries_checked: int
    postings_checked: int
    issues: list[Issue] = field(default_factory=list)

    @property
    def break_count(self) -> int:
        return len(self.issues)

    def by_check(self) -> dict[str, int]:
        counts: dict[str, int] = {}
        for issue in self.issues:
            counts[issue.check] = counts.get(issue.check, 0) + 1
        return counts

    def as_dict(self) -> dict:
        return {
            "ok": self.ok,
            "checked_at": self.checked_at.isoformat(),
            "entries_checked": self.entries_checked,
            "postings_checked": self.postings_checked,
            "break_count": self.break_count,
            "issues": [
                {"check": i.check, "detail": i.detail, "ref": i.ref} for i in self.issues
            ],
        }


def last_reconciliation() -> ReconciliationResult | None:
    return _last_result


def _check_entry_balances(issues: list[Issue]) -> int:
    """Every ledger entry's postings must net to zero per currency."""
    entries = LedgerEntry.objects.prefetch_related("postings").all()
    count = 0
    for entry in entries:
        count += 1
        residuals: dict[str, int] = {}
        postings = list(entry.postings.all())
        if not postings:
            issues.append(
                Issue(
                    check="empty_entry",
                    detail="Ledger entry has no postings",
                    ref=str(entry.id),
                )
            )
            continue
        for posting in postings:
            signed = (
                posting.amount_minor
                if posting.direction == PostingDirection.DEBIT
                else -posting.amount_minor
            )
            residuals[posting.currency] = residuals.get(posting.currency, 0) + signed
        bad = {k: v for k, v in residuals.items() if v != 0}
        if bad:
            issues.append(
                Issue(
                    check="unbalanced_entry",
                    detail=f"Postings do not net to zero: {bad}",
                    ref=str(entry.id),
                )
            )
    return count


def _check_global_balance(issues: list[Issue]) -> int:
    """All postings across the system must net to zero per currency."""
    postings = Posting.objects.all()
    count = postings.count()
    residuals: dict[str, int] = {}
    for posting in postings.iterator(chunk_size=500):
        signed = (
            posting.amount_minor
            if posting.direction == PostingDirection.DEBIT
            else -posting.amount_minor
        )
        residuals[posting.currency] = residuals.get(posting.currency, 0) + signed
    bad = {k: v for k, v in residuals.items() if v != 0}
    if bad:
        issues.append(
            Issue(
                check="global_imbalance",
                detail=f"System-wide postings do not net to zero: {bad}",
            )
        )
    return count


def _check_currency_consistency(issues: list[Issue]) -> None:
    """Posting currency must match its account's currency."""
    for posting in Posting.objects.select_related("account").iterator(chunk_size=500):
        if posting.currency != posting.account.currency:
            issues.append(
                Issue(
                    check="currency_mismatch",
                    detail=(
                        f"Posting currency {posting.currency} != "
                        f"account {posting.account.currency}"
                    ),
                    ref=str(posting.id),
                )
            )


def _check_succeeded_have_ledger(issues: list[Issue]) -> None:
    qs = Transaction.objects.filter(
        status=TransactionStatus.SUCCEEDED,
        ledger_entry__isnull=True,
    ).values_list("id", flat=True)[:100]
    for txn_id in qs:
        issues.append(
            Issue(
                check="succeeded_without_ledger",
                detail="Succeeded transaction has no linked ledger entry",
                ref=str(txn_id),
            )
        )


def _check_ledger_link_consistency(issues: list[Issue]) -> None:
    """Transaction.ledger_entry must point at an entry owned by that transaction."""
    for txn in (
        Transaction.objects.filter(ledger_entry__isnull=False)
        .select_related("ledger_entry")
        .iterator(chunk_size=200)
    ):
        entry = txn.ledger_entry
        if entry is not None and entry.transaction_id != txn.id:
            issues.append(
                Issue(
                    check="orphan_ledger_link",
                    detail=(
                        f"ledger_entry {entry.id} belongs to transaction "
                        f"{entry.transaction_id}"
                    ),
                    ref=str(txn.id),
                )
            )


def run_reconciliation(*, record: bool = True) -> ReconciliationResult:
    """Execute all ledger integrity checks. Optionally store result for metrics."""
    issues: list[Issue] = []
    entries_checked = _check_entry_balances(issues)
    postings_checked = _check_global_balance(issues)
    _check_currency_consistency(issues)
    _check_succeeded_have_ledger(issues)
    _check_ledger_link_consistency(issues)

    result = ReconciliationResult(
        ok=len(issues) == 0,
        checked_at=timezone.now(),
        entries_checked=entries_checked,
        postings_checked=postings_checked,
        issues=issues,
    )
    if record:
        global _last_result
        _last_result = result
    return result
