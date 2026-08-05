from django.test import TestCase, override_settings

from payments.engine import RefundError, InvalidTransition
from payments.models import LedgerEntryKind, TransactionStatus, TransactionType
from payments.money import Currency, Money
from payments.reconciliation import run_reconciliation

from .fakes import build_test_engine


class WithdrawalTests(TestCase):
    def setUp(self):
        self.engine = build_test_engine()
        self.engine.open_wallet("amani", Money.major(1_000_000, Currency.TZS))

    @override_settings(WITHDRAWAL_AUTO_APPROVE=False)
    def test_withdrawal_hold_then_settle(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        amount = Money.major(100_000, Currency.TZS)
        outcome = self.engine.initiate_withdrawal(
            owner="amani",
            amount=amount,
            method_kind="mobile_money",
            method_ref="+255754000891",
            operator="airtel_money",
            idempotency_key="wd-1",
            auto_approve=False,
        )
        txn = outcome.transaction
        self.assertEqual(txn.status, TransactionStatus.PENDING)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)

        self.engine.approve_withdrawal(txn)
        txn.refresh_from_db()
        self.assertEqual(txn.status, TransactionStatus.APPROVED)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start - amount)
        self.assertTrue(txn.ledger_entries.filter(kind=LedgerEntryKind.HOLD).exists())

        self.engine.process_withdrawal(txn)
        txn.refresh_from_db()
        self.assertEqual(txn.status, TransactionStatus.SUCCEEDED)
        self.assertIsNotNone(txn.ledger_entry_id)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start - amount)
        self.assertTrue(run_reconciliation().ok)

    @override_settings(WITHDRAWAL_AUTO_APPROVE=False)
    def test_reject_after_hold_releases_funds(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        amount = Money.major(50_000, Currency.TZS)
        txn = self.engine.initiate_withdrawal(
            owner="amani", amount=amount, method_kind="mobile_money",
            method_ref="+255754000891", operator="airtel_money",
            idempotency_key="wd-reject", auto_approve=False,
        ).transaction
        self.engine.approve_withdrawal(txn)
        self.engine.reject_withdrawal(txn, reason="ops deny")
        txn.refresh_from_db()
        self.assertEqual(txn.status, TransactionStatus.REJECTED)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)
        self.assertTrue(txn.ledger_entries.filter(kind=LedgerEntryKind.RELEASE).exists())
        self.assertTrue(run_reconciliation().ok)

    def test_withdrawal_auto_approve_idempotent(self):
        amount = Money.major(25_000, Currency.TZS)
        first = self.engine.initiate_withdrawal(
            owner="amani", amount=amount, method_kind="mobile_money",
            method_ref="+255754000891", operator="airtel_money",
            idempotency_key="wd-dupe", auto_approve=True,
        )
        after = self.engine.wallet_balance("amani", Currency.TZS)
        second = self.engine.initiate_withdrawal(
            owner="amani", amount=amount, method_kind="mobile_money",
            method_ref="+255754000891", operator="airtel_money",
            idempotency_key="wd-dupe", auto_approve=True,
        )
        self.assertTrue(second.replayed)
        self.assertEqual(first.transaction.id, second.transaction.id)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), after)


class RefundTests(TestCase):
    def setUp(self):
        self.engine = build_test_engine()
        self.engine.open_wallet("amani", Money.major(1_000_000, Currency.TZS))

    def test_partial_and_full_refund_of_transfer(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        send = self.engine.initiate_transfer(
            owner="amani", amount=Money.major(200_000, Currency.TZS),
            method_kind="mobile_money", method_ref="+255754000891",
            operator="airtel_money", counterparty="Juma",
            idempotency_key="rf-send",
        ).transaction
        partial = Money.major(50_000, Currency.TZS)
        r1 = self.engine.initiate_refund(
            owner="amani", original=send, amount=partial,
            idempotency_key="rf-1",
        ).transaction
        self.assertEqual(r1.type, TransactionType.REFUND)
        self.assertEqual(r1.status, TransactionStatus.SUCCEEDED)
        self.assertEqual(r1.parent_id, send.id)
        mid = self.engine.wallet_balance("amani", Currency.TZS)
        self.assertEqual(mid, start - Money.major(200_000, Currency.TZS) + partial)

        r2 = self.engine.initiate_refund(
            owner="amani", original=send, amount=Money.major(150_000, Currency.TZS),
            idempotency_key="rf-2",
        ).transaction
        self.assertEqual(r2.status, TransactionStatus.SUCCEEDED)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)
        self.assertTrue(run_reconciliation().ok)

    def test_refund_cap_enforced(self):
        send = self.engine.initiate_transfer(
            owner="amani", amount=Money.major(10_000, Currency.TZS),
            method_kind="mobile_money", method_ref="+255754000891",
            operator="airtel_money", counterparty="Juma",
            idempotency_key="rf-cap-send",
        ).transaction
        with self.assertRaises(RefundError):
            self.engine.initiate_refund(
                owner="amani", original=send,
                amount=Money.major(10_001, Currency.TZS),
                idempotency_key="rf-cap",
            )


class ReversalTests(TestCase):
    def setUp(self):
        self.engine = build_test_engine()
        self.engine.open_wallet("amani", Money.major(1_000_000, Currency.TZS))

    def test_reversal_restores_balance_and_marks_original(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        send = self.engine.initiate_transfer(
            owner="amani", amount=Money.major(75_000, Currency.TZS),
            method_kind="mobile_money", method_ref="+255754000891",
            operator="airtel_money", counterparty="Juma",
            idempotency_key="rev-send",
        ).transaction
        rev = self.engine.reverse_transaction(
            owner="amani", original=send, idempotency_key="rev-1",
        ).transaction
        self.assertEqual(rev.type, TransactionType.REVERSAL)
        send.refresh_from_db()
        self.assertEqual(send.status, TransactionStatus.REVERSED)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)
        self.assertTrue(rev.ledger_entry.reverses_id == send.ledger_entry_id)
        self.assertTrue(run_reconciliation().ok)

    def test_cannot_reverse_twice(self):
        send = self.engine.initiate_transfer(
            owner="amani", amount=Money.major(10_000, Currency.TZS),
            method_kind="mobile_money", method_ref="+255754000891",
            operator="airtel_money", counterparty="Juma",
            idempotency_key="rev-twice-send",
        ).transaction
        self.engine.reverse_transaction(
            owner="amani", original=send, idempotency_key="rev-a",
        )
        with self.assertRaises(InvalidTransition):
            self.engine.reverse_transaction(
                owner="amani", original=send, idempotency_key="rev-b",
            )
