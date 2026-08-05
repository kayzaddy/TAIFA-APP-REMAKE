from django.core.management import call_command
from django.core.management.base import CommandError
from django.test import TestCase
from io import StringIO

from payments import ledger
from payments.engine import TransactionEngine
from payments.models import (
    LedgerAccountType,
    LedgerEntry,
    Posting,
    PostingDirection,
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money
from payments.reconciliation import run_reconciliation
from payments.tasks import reconcile_ledger_task


class ReconciliationTests(TestCase):
    def setUp(self):
        self.engine = TransactionEngine()
        self.engine.open_wallet("amani", Money.major(100_000, Currency.TZS))

    def test_healthy_books_pass(self):
        result = run_reconciliation()
        self.assertTrue(result.ok)
        self.assertEqual(result.break_count, 0)
        self.assertGreater(result.entries_checked, 0)
        self.assertGreater(result.postings_checked, 0)

    def test_detects_succeeded_without_ledger(self):
        Transaction.objects.create(
            owner="amani",
            type=TransactionType.SEND_MONEY,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.DEBIT,
            amount_minor=1000,
            currency="TZS",
            counterparty="x",
            method_kind="wallet",
            idempotency_key="orphan-success",
        )
        result = run_reconciliation()
        self.assertFalse(result.ok)
        self.assertIn("succeeded_without_ledger", result.by_check())

    def test_detects_unbalanced_entry(self):
        txn = Transaction.objects.create(
            owner="amani",
            type=TransactionType.TOP_UP,
            status=TransactionStatus.PROCESSING,
            direction=TransactionDirection.CREDIT,
            amount_minor=500,
            currency="TZS",
            counterparty="x",
            method_kind="mobile_money",
            idempotency_key="unbalanced-entry",
        )
        wallet = ledger.get_account(
            "user:amani:wallet:TZS", LedgerAccountType.USER_WALLET, Currency.TZS, "amani"
        )
        entry = LedgerEntry.objects.create(transaction=txn, description="broken")
        Posting.objects.create(
            entry=entry,
            account=wallet,
            direction=PostingDirection.CREDIT,
            amount_minor=500,
            currency="TZS",
        )
        result = run_reconciliation()
        self.assertFalse(result.ok)
        checks = result.by_check()
        self.assertIn("unbalanced_entry", checks)
        self.assertIn("global_imbalance", checks)

    def test_detects_currency_mismatch(self):
        txn = Transaction.objects.create(
            owner="amani",
            type=TransactionType.TOP_UP,
            status=TransactionStatus.PROCESSING,
            direction=TransactionDirection.CREDIT,
            amount_minor=100,
            currency="TZS",
            counterparty="x",
            method_kind="mobile_money",
            idempotency_key="currency-mismatch",
        )
        wallet = ledger.get_account(
            "user:amani:wallet:TZS", LedgerAccountType.USER_WALLET, Currency.TZS, "amani"
        )
        settlement = ledger.get_account(
            "house:provider-settlement:TZS",
            LedgerAccountType.PROVIDER_SETTLEMENT,
            Currency.TZS,
        )
        entry = LedgerEntry.objects.create(transaction=txn, description="fx bug")
        Posting.objects.create(
            entry=entry,
            account=wallet,
            direction=PostingDirection.CREDIT,
            amount_minor=100,
            currency="USD",  # wrong vs account TZS
        )
        Posting.objects.create(
            entry=entry,
            account=settlement,
            direction=PostingDirection.DEBIT,
            amount_minor=100,
            currency="USD",
        )
        result = run_reconciliation()
        self.assertFalse(result.ok)
        self.assertIn("currency_mismatch", result.by_check())

    def test_management_command_exits_nonzero_on_breaks(self):
        Transaction.objects.create(
            owner="amani",
            type=TransactionType.SEND_MONEY,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.DEBIT,
            amount_minor=1,
            currency="TZS",
            counterparty="x",
            method_kind="wallet",
            idempotency_key="cmd-fail",
        )
        out = StringIO()
        with self.assertRaises(CommandError):
            call_command("reconcile_ledger", "--quiet", stdout=out)

    def test_celery_task_returns_summary(self):
        payload = reconcile_ledger_task()
        self.assertTrue(payload["ok"])
        self.assertEqual(payload["break_count"], 0)
