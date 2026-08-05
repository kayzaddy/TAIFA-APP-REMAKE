"""Run ledger reconciliation: python manage.py reconcile_ledger."""
from __future__ import annotations

from django.core.management.base import BaseCommand, CommandError

from payments.reconciliation import run_reconciliation


class Command(BaseCommand):
    help = (
        "Check ledger integrity (balanced entries, global conservation, "
        "succeeded↔ledger links). Exit 1 on any break."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--json",
            action="store_true",
            help="Print the full result as JSON.",
        )
        parser.add_argument(
            "--quiet",
            action="store_true",
            help="Only print a one-line summary (or JSON with --json).",
        )

    def handle(self, *args, **options):
        result = run_reconciliation(record=True)

        if options["json"]:
            import json

            self.stdout.write(json.dumps(result.as_dict(), indent=2))
        elif options["quiet"]:
            status = "OK" if result.ok else "BREAKS"
            self.stdout.write(
                f"{status} entries={result.entries_checked} "
                f"postings={result.postings_checked} breaks={result.break_count}"
            )
        else:
            style = self.style.SUCCESS if result.ok else self.style.ERROR
            self.stdout.write(
                style(
                    f"Ledger reconciliation {'OK' if result.ok else 'FAILED'} · "
                    f"entries={result.entries_checked} · "
                    f"postings={result.postings_checked} · "
                    f"breaks={result.break_count}"
                )
            )
            for issue in result.issues:
                ref = f" ref={issue.ref}" if issue.ref else ""
                self.stdout.write(
                    self.style.WARNING(f"  [{issue.check}] {issue.detail}{ref}")
                )

        if not result.ok:
            raise CommandError(
                f"Ledger reconciliation found {result.break_count} break(s)."
            )
