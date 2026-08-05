"""MAP tests — QR/link/invoice → enterprise capture; no MAP ledger."""
from __future__ import annotations

from django.test import TestCase
from rest_framework.test import APITestCase

from enterprise.models import Merchant, MerchantStatus
from payments.journal import post_opening
from payments.models import (
    Transaction,
    TransactionDirection,
    TransactionStatus,
    TransactionType,
)
from payments.money import Currency, Money

from acceptance import services
from acceptance.models import IntentStatus
from acceptance.security import sign_payload, verify_signature


class MapSecurityTests(TestCase):
    def test_hmac_roundtrip(self):
        sig = sign_payload(["a", 1, None])
        self.assertTrue(verify_signature(["a", 1, None], sig))
        self.assertFalse(verify_signature(["a", 2, None], sig))


class MapPayFlowTests(TestCase):
    def setUp(self):
        self.merchant = Merchant.objects.create(
            code="map-demo-shop",
            legal_name="MAP Demo Shop Ltd",
            status=MerchantStatus.ACTIVE,
            sector="retail",
            fee_bps=0,
            tax_bps=0,
            commission_bps=0,
        )
        self.profile = services.ensure_profile(merchant=self.merchant)
        payer = "customer-map-1"
        txn = Transaction.objects.create(
            owner=payer,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=100_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="map-open-1",
            note="opening",
        )
        post_opening(txn, payer, Money(100_000, Currency.TZS))
        self.payer = payer

    def test_dynamic_qr_pay(self):
        qr, intent = services.issue_qr(
            merchant=self.merchant,
            kind="dynamic",
            amount_minor=5_000,
            description="Coffee",
        )
        self.assertIsNotNone(intent)
        self.assertIn("taifa://pay/", qr.payload)
        intent, receipt = services.pay_intent(
            intent=intent,
            payer_principal=self.payer,
            idempotency_key="map-pay-qr-1",
        )
        self.assertEqual(intent.status, IntentStatus.PAID)
        self.assertTrue(intent.payment_ref)
        self.assertEqual(receipt.amount_minor, 5_000)
        self.assertTrue(Transaction.objects.filter(id=intent.payment_ref).exists())

    def test_payment_link_pay(self):
        link = services.create_payment_link(
            merchant=self.merchant,
            amount_minor=3_000,
            purpose="invoice",
        )
        intent, _ = services.pay_intent(
            intent=link.intent,
            payer_principal=self.payer,
            idempotency_key="map-pay-link-1",
        )
        self.assertEqual(intent.status, IntentStatus.PAID)

    def test_invoice_with_qr(self):
        inv, intent, qr = services.create_invoice(
            merchant=self.merchant,
            invoice_number="INV-100",
            amount_minor=8_000,
            line_items=[{"desc": "Service", "amount_minor": 8000}],
        )
        self.assertEqual(inv.remaining_minor, 8_000)
        self.assertEqual(qr.intent_id, intent.id)
        intent, _ = services.pay_intent(
            intent=intent,
            payer_principal=self.payer,
            idempotency_key="map-pay-inv-1",
        )
        inv.refresh_from_db()
        self.assertEqual(inv.status, IntentStatus.PAID)

    def test_expired_intent_blocked(self):
        from django.utils import timezone
        from datetime import timedelta

        intent = services.create_intent(
            merchant=self.merchant,
            amount_minor=1000,
            channel="dynamic_qr",
            ttl_minutes=1,
        )
        intent.expires_at = timezone.now() - timedelta(minutes=1)
        intent.signature = services._sign_intent(intent)
        intent.save()
        with self.assertRaises(services.MapError):
            services.pay_intent(
                intent=intent,
                payer_principal=self.payer,
                idempotency_key="map-expired",
            )

    def test_idempotent_replay(self):
        intent = services.create_intent(
            merchant=self.merchant,
            amount_minor=2_000,
            channel="payment_link",
        )
        a, _ = services.pay_intent(
            intent=intent,
            payer_principal=self.payer,
            idempotency_key="map-idem-1",
        )
        # Second call same key returns existing txn via enterprise; intent already paid
        with self.assertRaises(services.MapError):
            services.pay_intent(
                intent=a,
                payer_principal=self.payer,
                idempotency_key="map-idem-2",
            )


class MapApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "map-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="map-device-1",
        )

    def test_bootstrap_qr_and_pay(self):
        r = self.client.post(
            "/api/v1/map/bootstrap",
            {"code": "map-api-shop", "legal_name": "MAP API Shop"},
            format="json",
        )
        self.assertEqual(r.status_code, 201)
        mid = r.data["merchant_id"]

        # Fund device wallet
        from enterprise.models import Merchant

        merchant = Merchant.objects.get(id=mid)
        payer = "map-device-1"
        txn = Transaction.objects.create(
            owner=payer,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=50_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="map-api-open",
            note="opening",
        )
        post_opening(txn, payer, Money(50_000, Currency.TZS))

        qr = self.client.post(
            f"/api/v1/map/merchants/{mid}/qr",
            {"kind": "dynamic", "amount_minor": 1500, "description": "Snack"},
            format="json",
        )
        self.assertEqual(qr.status_code, 201)
        code = qr.data["intent"]["public_code"]
        pay = self.client.post(
            f"/api/v1/map/intents/{code}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="map-api-pay-1",
        )
        self.assertEqual(pay.status_code, 200, pay.data)
        self.assertEqual(pay.data["intent"]["status"], "paid")
        self.assertTrue(pay.data["receipt"]["payment_ref"])
