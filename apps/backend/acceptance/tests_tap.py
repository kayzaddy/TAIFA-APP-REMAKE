"""Tap & Pay tests — session → auth → pay_intent → ledger capture."""
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

from acceptance import tap as tap_services
from acceptance.models import TapSessionStatus


class TapPayFlowTests(TestCase):
    def setUp(self):
        self.merchant = Merchant.objects.create(
            code="tap-demo-shop",
            legal_name="Tap Demo Shop",
            status=MerchantStatus.ACTIVE,
            sector="retail",
            fee_bps=0,
            tax_bps=0,
            commission_bps=0,
        )
        self.payer = "tap-customer-1"
        txn = Transaction.objects.create(
            owner=self.payer,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=100_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="tap-open-1",
            note="opening",
        )
        post_opening(txn, self.payer, Money(100_000, Currency.TZS))

    def test_funding_prefs_default(self):
        prefs = tap_services.get_or_create_funding_prefs(owner_principal=self.payer)
        self.assertTrue(prefs.priority)
        self.assertEqual(prefs.priority[0]["kind"], "wallet")

    def test_tap_auth_confirm_ledger(self):
        # Force auth for low amount
        tap_services.update_funding_prefs(
            owner_principal=self.payer,
            auth_policy="always",
            require_confirmation=True,
        )
        session = tap_services.start_tap(
            merchant=self.merchant,
            amount_minor=4_000,
            payer_principal=self.payer,
            channel="nfc",
        )
        self.assertEqual(session.status, TapSessionStatus.AUTH_REQUIRED)
        self.assertTrue(session.intent_id)

        with self.assertRaises(tap_services.TapError):
            tap_services.confirm_tap(session=session, idempotency_key="tap-early")

        session = tap_services.authenticate_tap(session=session, method="biometric")
        session = tap_services.confirm_tap(session=session, idempotency_key="tap-pay-1")
        self.assertEqual(session.status, TapSessionStatus.SUCCEEDED)
        self.assertTrue(session.payment_ref)
        self.assertTrue(Transaction.objects.filter(id=session.payment_ref).exists())

    def test_insufficient_funds_fallback(self):
        poor = "tap-poor"
        session = tap_services.start_tap(
            merchant=self.merchant,
            amount_minor=5_000,
            payer_principal=poor,
            channel="softpos",
        )
        tap_services.update_funding_prefs(
            owner_principal=poor, auth_policy="low_friction", low_risk_threshold_minor=99_999
        )
        session.auth_required = False
        session.auth_completed = True
        session.save()
        with self.assertRaises(tap_services.TapError):
            tap_services.confirm_tap(session=session, idempotency_key="tap-poor-1")
        session.refresh_from_db()
        self.assertEqual(session.status, TapSessionStatus.FALLBACK)


class TapApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "tap-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="tap-device-1",
        )
        boot = self.client.post(
            "/api/v1/map/bootstrap",
            {"code": "tap-api-shop", "legal_name": "Tap API Shop"},
            format="json",
        )
        self.mid = boot.data["merchant_id"]
        Merchant.objects.filter(id=self.mid).update(fee_bps=0, tax_bps=0, commission_bps=0)
        payer = "tap-device-1"
        txn = Transaction.objects.create(
            owner=payer,
            type=TransactionType.TOP_UP,
            status=TransactionStatus.SUCCEEDED,
            direction=TransactionDirection.CREDIT,
            amount_minor=80_000,
            fee_minor=0,
            currency="TZS",
            counterparty="opening",
            method_kind="opening",
            idempotency_key="tap-api-open",
            note="opening",
        )
        post_opening(txn, payer, Money(80_000, Currency.TZS))

    def test_api_tap_flow(self):
        prefs = self.client.put(
            "/api/v1/map/funding/prefs",
            {"auth_policy": "always", "require_confirmation": True},
            format="json",
        )
        self.assertEqual(prefs.status_code, 200)

        start = self.client.post(
            f"/api/v1/map/merchants/{self.mid}/tap",
            {"amount_minor": 3500, "channel": "nfc", "terminal_code": "POS-NFC-1"},
            format="json",
        )
        self.assertEqual(start.status_code, 201, start.data)
        code = start.data["session"]["public_code"]

        auth = self.client.post(
            f"/api/v1/map/tap/{code}/auth",
            {"method": "fingerprint"},
            format="json",
        )
        self.assertEqual(auth.status_code, 200)

        confirm = self.client.post(
            f"/api/v1/map/tap/{code}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="tap-api-confirm-1",
        )
        self.assertEqual(confirm.status_code, 200, confirm.data)
        self.assertEqual(confirm.data["status"], "succeeded")
        self.assertTrue(confirm.data["payment_ref"])
