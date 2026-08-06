from __future__ import annotations

from django.test import TestCase
from rest_framework.test import APIClient


class MerchantPaymentSprint3Tests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.base = "/api/v1/merchant-app"

    def _bootstrap_with_device(self):
        self.client.post(
            f"{self.base}/auth/signup",
            {"email": "pay@shop.test", "password": "securepass1", "full_name": "Pay"},
            format="json",
        )
        token = self.client.post(
            f"{self.base}/auth/login",
            {"email": "pay@shop.test", "password": "securepass1"},
            format="json",
        ).json()["access_token"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        self.client.post(
            f"{self.base}/merchants/register",
            {"legal_name": "Pay Shop", "city": "Dar"},
            format="json",
        )
        login = self.client.post(
            f"{self.base}/auth/login",
            {"email": "pay@shop.test", "password": "securepass1"},
            format="json",
        ).json()
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login['access_token']}")
        device = self.client.post(
            f"{self.base}/devices",
            {"name": "Tap Phone", "device_type": "android_phone"},
            format="json",
        ).json()
        self.client.post(f"{self.base}/devices/{device['id']}/activate")
        return device

    def test_softpos_qr_link_refund_flow(self):
        device = self._bootstrap_with_device()
        term = self.client.post(f"{self.base}/payments/terminals", {"device_id": device["id"]}, format="json")
        self.assertEqual(term.status_code, 201)
        session = self.client.post(
            f"{self.base}/payments/softpos/sessions",
            {"device_id": device["id"], "amount": "1500.00", "merchant_reference": "INV-1"},
            format="json",
        )
        self.assertEqual(session.status_code, 201)
        tx_id = session.json()["id"]
        confirm = self.client.post(
            f"{self.base}/payments/softpos/{tx_id}/confirm",
            {"nfc_token": "emulated-tap", "wallet_hint": "mpesa"},
            format="json",
        )
        self.assertEqual(confirm.status_code, 200)
        self.assertEqual(confirm.json()["transaction"]["status"], "captured")
        self.assertIn("receipt", confirm.json())

        qr = self.client.post(
            f"{self.base}/payments/qr",
            {"qr_type": "dynamic", "amount": "500.00", "expires_in_seconds": 3600},
            format="json",
        )
        self.assertEqual(qr.status_code, 201)
        qr_pay = self.client.post(f"{self.base}/payments/qr/{qr.json()['id']}/complete")
        self.assertEqual(qr_pay.status_code, 200)

        link = self.client.post(
            f"{self.base}/payments/links",
            {"amount": "2500.00", "description": "Invoice 2"},
            format="json",
        )
        self.assertEqual(link.status_code, 201)
        link_pay = self.client.post(f"{self.base}/payments/links/{link.json()['id']}/complete")
        self.assertEqual(link_pay.status_code, 200)

        list_tx = self.client.get(f"{self.base}/payments/transactions")
        self.assertGreaterEqual(len(list_tx.json()), 3)

        refund = self.client.post(
            f"{self.base}/payments/transactions/{tx_id}/refund",
            {"reason": "customer request", "amount": "1500.00"},
            format="json",
        )
        self.assertEqual(refund.status_code, 200)

        analytics = self.client.get(f"{self.base}/payments/analytics/today")
        self.assertEqual(analytics.status_code, 200)
        self.assertIn("revenue", analytics.json())

    def test_no_settlement_endpoints_in_bff(self):
        joined = " ".join(str(p.pattern) for p in __import__("taifa_merchant.urls", fromlist=["urlpatterns"]).urlpatterns)
        for forbidden in ("settlement", "reconciliation", "fraud-score"):
            self.assertNotIn(forbidden, joined.lower())
