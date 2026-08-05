"""Provider settlement-file reconciliation.

Compares ingested provider statement lines to internal transactions (by
provider_ref) and records exceptions. Does not mutate the ledger.
"""
from __future__ import annotations

import csv
import io
from dataclasses import dataclass, field
from datetime import timedelta
from pathlib import Path

from django.db import transaction as db_transaction
from django.utils import timezone
from django.utils.dateparse import parse_datetime

from .models import (
    ReconciliationException,
    ReconciliationExceptionCode,
    SettlementBatch,
    SettlementBatchStatus,
    SettlementLine,
    SettlementMatchStatus,
    Transaction,
    TransactionStatus,
)


@dataclass
class ReconReport:
    batch_id: str
    matched: int = 0
    exceptions: int = 0
    by_code: dict[str, int] = field(default_factory=dict)

    def as_dict(self) -> dict:
        return {
            "batch_id": self.batch_id,
            "matched": self.matched,
            "exceptions": self.exceptions,
            "by_code": self.by_code,
        }


def ingest_settlement_csv(
    *,
    provider: str,
    filename: str,
    content: str | bytes,
) -> SettlementBatch:
    """Ingest a CSV with columns: provider_ref,amount_minor,currency,direction[,external_id,settled_at]."""
    text = content.decode("utf-8") if isinstance(content, bytes) else content
    reader = csv.DictReader(io.StringIO(text))
    required = {"provider_ref", "amount_minor", "currency", "direction"}
    if not reader.fieldnames or not required.issubset(set(reader.fieldnames)):
        raise ValueError(f"CSV must include columns {sorted(required)}")

    with db_transaction.atomic():
        batch = SettlementBatch.objects.create(provider=provider, filename=filename)
        count = 0
        for row in reader:
            settled_raw = (row.get("settled_at") or "").strip()
            settled_at = parse_datetime(settled_raw) if settled_raw else None
            SettlementLine.objects.create(
                batch=batch,
                provider_ref=str(row["provider_ref"]).strip(),
                external_id=str(row.get("external_id") or "").strip(),
                amount_minor=int(row["amount_minor"]),
                currency=str(row["currency"]).strip().upper(),
                direction=str(row["direction"]).strip().lower(),
                settled_at=settled_at,
            )
            count += 1
        batch.line_count = count
        batch.save(update_fields=["line_count"])
    return batch


def ingest_settlement_csv_path(path: str | Path, *, provider: str) -> SettlementBatch:
    p = Path(path)
    return ingest_settlement_csv(provider=provider, filename=p.name, content=p.read_text(encoding="utf-8"))


def reconcile_batch(batch: SettlementBatch, *, late_after_hours: int = 48) -> ReconReport:
    """Match each line to an internal transaction; emit exceptions."""
    report = ReconReport(batch_id=str(batch.id))
    seen_refs: dict[str, int] = {}
    late_cutoff = timezone.now() - timedelta(hours=late_after_hours)

    with db_transaction.atomic():
        ReconciliationException.objects.filter(batch=batch).delete()
        for line in batch.lines.select_for_update().all():
            seen_refs[line.provider_ref] = seen_refs.get(line.provider_ref, 0) + 1
            if seen_refs[line.provider_ref] > 1:
                _exception(
                    batch,
                    ReconciliationExceptionCode.DUPLICATE_SETTLEMENT,
                    line.provider_ref,
                    f"Duplicate settlement line for {line.provider_ref}",
                    report,
                )
                line.match_status = SettlementMatchStatus.DUPLICATE
                line.save(update_fields=["match_status"])
                continue

            txns = list(Transaction.objects.filter(provider_ref=line.provider_ref))
            if not txns:
                _exception(
                    batch,
                    ReconciliationExceptionCode.UNKNOWN_TRANSACTION,
                    line.provider_ref,
                    "No internal transaction for provider_ref",
                    report,
                )
                line.match_status = SettlementMatchStatus.UNEXPECTED
                line.save(update_fields=["match_status"])
                continue

            txn = txns[0]
            line.transaction = txn
            if txn.currency != line.currency:
                _exception(
                    batch,
                    ReconciliationExceptionCode.CURRENCY_MISMATCH,
                    line.provider_ref,
                    f"currency file={line.currency} txn={txn.currency}",
                    report,
                    txn=txn,
                )
                line.match_status = SettlementMatchStatus.CURRENCY_MISMATCH
            elif txn.amount_minor != line.amount_minor:
                _exception(
                    batch,
                    ReconciliationExceptionCode.AMOUNT_MISMATCH,
                    line.provider_ref,
                    f"amount file={line.amount_minor} txn={txn.amount_minor}",
                    report,
                    txn=txn,
                )
                line.match_status = SettlementMatchStatus.AMOUNT_MISMATCH
            else:
                line.match_status = SettlementMatchStatus.MATCHED
                report.matched += 1
                if line.settled_at and txn.created_at and line.settled_at < txn.created_at - timedelta(hours=1):
                    pass
                if txn.status == TransactionStatus.SUCCEEDED and line.settled_at and line.settled_at > late_cutoff:
                    # settled recently relative to now — not late; late = txn old, file new
                    pass
                if (
                    txn.status == TransactionStatus.SUCCEEDED
                    and txn.updated_at < late_cutoff
                    and (line.settled_at is None or line.settled_at > txn.updated_at + timedelta(hours=late_after_hours))
                ):
                    _exception(
                        batch,
                        ReconciliationExceptionCode.LATE_SETTLEMENT,
                        line.provider_ref,
                        "Provider settlement arrived late vs internal settle",
                        report,
                        txn=txn,
                    )
                    line.match_status = SettlementMatchStatus.LATE
            line.save(update_fields=["match_status", "transaction"])

        # Optional full-day file: flag succeeded txns for this provider absent from the file.
        if "full_day" in (batch.notes or "").lower():
            file_refs = set(batch.lines.values_list("provider_ref", flat=True))
            missing = Transaction.objects.filter(
                status=TransactionStatus.SUCCEEDED,
                provider_ref__gt="",
            ).exclude(provider_ref__in=file_refs)[:200]
            for txn in missing:
                provider = (txn.provider or "").lower()
                if batch.provider.lower() not in provider and provider not in batch.provider.lower():
                    if batch.provider.lower() not in {"mpesa", "all"}:
                        continue
                _exception(
                    batch,
                    ReconciliationExceptionCode.MISSING_SETTLEMENT,
                    txn.provider_ref,
                    "Succeeded internal txn missing from settlement file",
                    report,
                    txn=txn,
                )

        batch.matched_count = report.matched
        batch.exception_count = report.exceptions
        batch.status = SettlementBatchStatus.RECONCILED
        batch.reconciled_at = timezone.now()
        batch.save(
            update_fields=["matched_count", "exception_count", "status", "reconciled_at"]
        )
    return report


def _exception(batch, code, provider_ref, detail, report: ReconReport, txn=None) -> None:
    ReconciliationException.objects.create(
        batch=batch,
        code=code,
        provider_ref=provider_ref,
        detail=detail,
        transaction=txn,
    )
    report.exceptions += 1
    report.by_code[code] = report.by_code.get(code, 0) + 1
