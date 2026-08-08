"""Spending analytics: GET /api/v1/payments/analytics/spending."""
from django.utils import timezone
from rest_framework.test import APITestCase

from ..models import Transaction, TransactionDirection, TransactionStatus, TransactionType


class SpendingAnalyticsTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register", {"device_id": "dev-analytics-1"}, format="json"
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}", HTTP_X_DEVICE_ID="dev-analytics-1"
        )
        self.owner = reg["owner"]
        # Opening balance already gives one CREDIT/top_up this month.

    def _txn(self, **overrides):
        defaults = dict(
            owner=self.owner,
            type=TransactionType.SEND_MONEY,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.DEBIT,
            amount_minor=100000,
            currency="TZS",
            counterparty="test",
            method_kind="wallet",
            idempotency_key=f"analytics-{Transaction.objects.count()}",
        )
        defaults.update(overrides)
        return Transaction.objects.create(**defaults)

    def test_default_range_includes_current_month_opening_balance(self):
        resp = self.client.get("/api/v1/payments/analytics/spending")
        body = resp.json()
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(len(body["months"]), 6)
        this_month = body["months"][-1]
        self.assertEqual(this_month["total_in_minor"], 284750000)  # the opening balance

    def test_debit_and_credit_bucketed_correctly(self):
        self._txn(direction=TransactionDirection.DEBIT, amount_minor=50000, type=TransactionType.SEND_MONEY)
        self._txn(direction=TransactionDirection.CREDIT, amount_minor=30000, type=TransactionType.TOP_UP)
        resp = self.client.get("/api/v1/payments/analytics/spending?months=1")
        body = resp.json()["months"][0]
        self.assertEqual(body["total_out_minor"], 50000)
        self.assertEqual(body["total_in_minor"], 284750000 + 30000)
        self.assertEqual(body["net_minor"], body["total_in_minor"] - 50000)

    def test_by_type_breakdown(self):
        self._txn(direction=TransactionDirection.DEBIT, amount_minor=20000, type=TransactionType.SEND_MONEY)
        self._txn(direction=TransactionDirection.DEBIT, amount_minor=15000, type=TransactionType.BILL_PAYMENT)
        self._txn(direction=TransactionDirection.DEBIT, amount_minor=5000, type=TransactionType.SEND_MONEY)
        resp = self.client.get("/api/v1/payments/analytics/spending?months=1")
        by_type = resp.json()["months"][0]["by_type"]
        self.assertEqual(by_type["send_money"], 25000)
        self.assertEqual(by_type["bill_payment"], 15000)

    def test_pending_and_failed_transactions_excluded(self):
        self._txn(status=TransactionStatus.PENDING, amount_minor=999999)
        self._txn(status=TransactionStatus.FAILED, amount_minor=888888)
        resp = self.client.get("/api/v1/payments/analytics/spending?months=1")
        self.assertEqual(resp.json()["months"][0]["total_out_minor"], 0)

    def test_old_transaction_outside_range_excluded(self):
        old = self._txn(direction=TransactionDirection.DEBIT, amount_minor=77777)
        old_time = timezone.now() - timezone.timedelta(days=400)
        Transaction.objects.filter(pk=old.pk).update(created_at=old_time)
        resp = self.client.get("/api/v1/payments/analytics/spending?months=6")
        total_out = sum(m["total_out_minor"] for m in resp.json()["months"])
        self.assertEqual(total_out, 0)

    def test_summary_matches_sum_of_months(self):
        self._txn(direction=TransactionDirection.DEBIT, amount_minor=10000)
        resp = self.client.get("/api/v1/payments/analytics/spending?months=3")
        body = resp.json()
        self.assertEqual(body["summary"]["total_out_minor"], sum(m["total_out_minor"] for m in body["months"]))
        self.assertEqual(body["summary"]["total_in_minor"], sum(m["total_in_minor"] for m in body["months"]))

    def test_months_out_of_range_rejected(self):
        resp = self.client.get("/api/v1/payments/analytics/spending?months=25")
        self.assertEqual(resp.status_code, 400)
        resp = self.client.get("/api/v1/payments/analytics/spending?months=0")
        self.assertEqual(resp.status_code, 400)

    def test_scoped_to_own_transactions_only(self):
        other = self.client.post(
            "/api/v1/auth/device/register", {"device_id": "dev-analytics-2"}, format="json"
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {other['token']}", HTTP_X_DEVICE_ID="dev-analytics-2"
        )
        resp = self.client.get("/api/v1/payments/analytics/spending?months=1")
        # Only their own opening balance, not the setUp owner's.
        self.assertEqual(resp.json()["months"][0]["total_in_minor"], 284750000)
