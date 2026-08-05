from django.test import TestCase

from payments.models import Transaction, TransactionStatus
from payments.money import Currency, Money
from payments.webhooks import process_mpesa_stk_callback

from .fakes import build_test_engine


def stk_callback(checkout_id: str, result_code: int) -> dict:
    return {
        "Body": {
            "stkCallback": {
                "MerchantRequestID": "m-1",
                "CheckoutRequestID": checkout_id,
                "ResultCode": result_code,
                "ResultDesc": "ok" if result_code == 0 else "cancelled",
            }
        }
    }


class TopUpWebhookTests(TestCase):
    def setUp(self):
        self.engine = build_test_engine()
        self.engine.open_wallet("amani", Money.major(2847500, Currency.TZS))

    def test_topup_is_pending_then_resolved_by_webhook(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)

        outcome = self.engine.initiate_topup(
            owner="amani", amount=Money.major(100000, Currency.TZS),
            msisdn="+255754000891", idempotency_key="topup-1",
        )
        txn = outcome.transaction
        # STK push accepted → pending, no money moved yet.
        self.assertEqual(txn.status, TransactionStatus.PROCESSING)
        self.assertTrue(txn.provider_ref)
        self.assertIsNone(txn.ledger_entry_id)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)

        # Customer approves → Daraja calls our webhook.
        event = process_mpesa_stk_callback(stk_callback(txn.provider_ref, 0), engine=self.engine)
        self.assertEqual(event.result, "succeeded")

        txn.refresh_from_db()
        self.assertEqual(txn.status, TransactionStatus.SUCCEEDED)
        self.assertIsNotNone(txn.ledger_entry_id)
        self.assertEqual(
            self.engine.wallet_balance("amani", Currency.TZS),
            start + Money.major(100000, Currency.TZS),
        )

    def test_failed_stk_leaves_balance_untouched(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        outcome = self.engine.initiate_topup(
            owner="amani", amount=Money.major(100000, Currency.TZS),
            msisdn="+255754000891", idempotency_key="topup-2",
        )
        process_mpesa_stk_callback(stk_callback(outcome.transaction.provider_ref, 1032), engine=self.engine)
        outcome.transaction.refresh_from_db()
        self.assertEqual(outcome.transaction.status, TransactionStatus.FAILED)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)


class TransferTests(TestCase):
    def setUp(self):
        self.engine = build_test_engine()
        self.engine.open_wallet("amani", Money.major(2847500, Currency.TZS))

    def test_transfer_debits_and_posts_ledger(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        amount = Money.major(250000, Currency.TZS)
        outcome = self.engine.initiate_transfer(
            owner="amani", amount=amount, method_kind="mobile_money",
            method_ref="+255754000891", operator="airtel_money",
            counterparty="Juma Ally", idempotency_key="xfer-1",
        )
        txn = outcome.transaction
        # Airtel (simulated) accepts synchronously → settled.
        self.assertEqual(txn.status, TransactionStatus.SUCCEEDED)
        self.assertIsNotNone(txn.ledger_entry_id)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start - amount)

    def test_transfer_is_idempotent(self):
        amount = Money.major(250000, Currency.TZS)
        first = self.engine.initiate_transfer(
            owner="amani", amount=amount, method_kind="mobile_money",
            method_ref="+255754000891", operator="airtel_money",
            counterparty="Juma Ally", idempotency_key="xfer-dupe",
        )
        after_first = self.engine.wallet_balance("amani", Currency.TZS)

        second = self.engine.initiate_transfer(
            owner="amani", amount=amount, method_kind="mobile_money",
            method_ref="+255754000891", operator="airtel_money",
            counterparty="Juma Ally", idempotency_key="xfer-dupe",
        )
        self.assertTrue(second.replayed)
        self.assertEqual(first.transaction.id, second.transaction.id)
        # Money moved exactly once.
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), after_first)
        self.assertEqual(Transaction.objects.filter(idempotency_key="xfer-dupe").count(), 1)

    def test_insufficient_balance_is_rejected(self):
        start = self.engine.wallet_balance("amani", Currency.TZS)
        too_much = start + Money.major(1, Currency.TZS)
        outcome = self.engine.initiate_transfer(
            owner="amani", amount=too_much, method_kind="mobile_money",
            method_ref="+255754000891", operator="mpesa",
            counterparty="Juma Ally", idempotency_key="xfer-broke",
        )
        self.assertEqual(outcome.transaction.status, TransactionStatus.FAILED)
        self.assertEqual(self.engine.wallet_balance("amani", Currency.TZS), start)
