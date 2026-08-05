from django.test import TestCase

from payments import ledger
from payments.models import (
    LedgerAccountType,
    Posting,
    Transaction,
    TransactionDirection,
    TransactionType,
)
from payments.money import Currency, Money


class LedgerTests(TestCase):
    def setUp(self):
        self.wallet = ledger.get_account("user:x:wallet:TZS", LedgerAccountType.USER_WALLET, Currency.TZS, "x")
        self.settlement = ledger.get_account("house:settle:TZS", LedgerAccountType.PROVIDER_SETTLEMENT, Currency.TZS)
        self.fees = ledger.get_account("house:fees:TZS", LedgerAccountType.FEE_INCOME, Currency.TZS)
        self.txn = Transaction.objects.create(
            type=TransactionType.SEND_MONEY, direction=TransactionDirection.DEBIT,
            amount_minor=100, currency="TZS", counterparty="t", method_kind="wallet",
            idempotency_key="k-ledger",
        )

    def test_posts_a_balanced_entry(self):
        amount = Money.major(250000, Currency.TZS)
        entry = ledger.post_entry(self.txn, "t", [
            ledger.PostingSpec.debit(self.wallet, amount),
            ledger.PostingSpec.credit(self.settlement, amount),
        ])
        self.assertEqual(entry.postings.count(), 2)

    def test_balanced_transfer_with_fee(self):
        amount = Money.major(100000, Currency.TZS)
        fee = Money.major(500, Currency.TZS)
        entry = ledger.post_entry(self.txn, "t", [
            ledger.PostingSpec.debit(self.wallet, amount + fee),
            ledger.PostingSpec.credit(self.settlement, amount),
            ledger.PostingSpec.credit(self.fees, fee),
        ])
        self.assertEqual(entry.postings.count(), 3)

    def test_rejects_unbalanced_entry(self):
        with self.assertRaises(ledger.UnbalancedLedgerEntry):
            ledger.post_entry(self.txn, "t", [
                ledger.PostingSpec.debit(self.wallet, Money.major(100, Currency.TZS)),
                ledger.PostingSpec.credit(self.settlement, Money.major(90, Currency.TZS)),
            ])
        # Nothing partial was written.
        self.assertEqual(Posting.objects.count(), 0)

    def test_postings_are_append_only(self):
        amount = Money.major(10, Currency.TZS)
        entry = ledger.post_entry(self.txn, "t", [
            ledger.PostingSpec.debit(self.wallet, amount),
            ledger.PostingSpec.credit(self.settlement, amount),
        ])
        posting = entry.postings.first()
        posting.amount_minor = 999999
        with self.assertRaises(ValueError):
            posting.save()

    def test_balance_reflects_postings(self):
        amount = Money.major(150000, Currency.TZS)
        ledger.post_entry(self.txn, "credit wallet", [
            ledger.PostingSpec.debit(self.settlement, amount),
            ledger.PostingSpec.credit(self.wallet, amount),
        ])
        # Wallet is credit-normal: a credit increases its balance.
        self.assertEqual(ledger.balance_of(self.wallet), amount)
