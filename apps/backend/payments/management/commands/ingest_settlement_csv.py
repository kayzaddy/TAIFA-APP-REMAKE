"""Ingest a provider settlement CSV for reconciliation."""
from __future__ import annotations

from django.core.management.base import BaseCommand, CommandError

from payments.provider_reconciliation import ingest_settlement_csv_path, reconcile_batch


class Command(BaseCommand):
    help = "Ingest a settlement CSV and optionally reconcile it against the ledger."

    def add_arguments(self, parser):
        parser.add_argument("path", help="Path to CSV file")
        parser.add_argument("--provider", default="mpesa")
        parser.add_argument("--reconcile", action="store_true")
        parser.add_argument(
            "--full-day",
            action="store_true",
            help="Mark batch as a full-day file (also flags missing internal txns).",
        )

    def handle(self, *args, **options):
        try:
            batch = ingest_settlement_csv_path(options["path"], provider=options["provider"])
        except Exception as exc:  # noqa: BLE001
            raise CommandError(str(exc)) from exc
        if options["full_day"]:
            batch.notes = (batch.notes + " full_day").strip()
            batch.save(update_fields=["notes"])
        self.stdout.write(self.style.SUCCESS(
            f"Ingested batch={batch.id} lines={batch.line_count} provider={batch.provider}"
        ))
        if options["reconcile"]:
            report = reconcile_batch(batch)
            self.stdout.write(
                f"Reconciled matched={report.matched} exceptions={report.exceptions} "
                f"by_code={report.by_code}"
            )
            if report.exceptions:
                raise CommandError(f"Settlement reconciliation found {report.exceptions} exception(s).")
