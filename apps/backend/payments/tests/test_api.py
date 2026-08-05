from unittest.mock import MagicMock, patch

from rest_framework.test import APITestCase

from .fakes import build_test_engine, build_test_orchestrator


class DeviceAuthTests(APITestCase):
    def test_register_returns_bound_token_and_funded_wallet(self):
        resp = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "device-abc-123", "platform": "android"},
            format="json",
        )
        self.assertEqual(resp.status_code, 201)
        body = resp.json()
        self.assertTrue(body["token"])
        self.assertEqual(body["device_id"], "device-abc-123")
        self.assertEqual(body["balance_minor"], 284750000)  # TSh 2,847,500

    def test_reregister_rotates_token_keeps_owner(self):
        first = self.client.post(
            "/api/v1/auth/device/register", {"device_id": "dev-x"}, format="json"
        ).json()
        second = self.client.post(
            "/api/v1/auth/device/register", {"device_id": "dev-x"}, format="json"
        ).json()
        self.assertNotEqual(first["token"], second["token"])
        self.assertEqual(first["owner"], second["owner"])

    def test_wallet_requires_device_token(self):
        resp = self.client.get("/api/v1/payments/wallet")
        self.assertEqual(resp.status_code, 401)


class PaymentApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "device-test-1", "platform": "test"},
            format="json",
        ).json()
        self.token = reg["token"]
        self.owner = reg["owner"]
        # Bind the token to the device on every subsequent request.
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {self.token}",
            HTTP_X_DEVICE_ID="device-test-1",
        )

    def test_wallet_endpoint_reports_funded_balance(self):
        resp = self.client.get("/api/v1/payments/wallet")
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["balance_minor"], 284750000)
        self.assertEqual(body["owner"], self.owner)
        self.assertIsInstance(body["transactions"], list)

    def test_topup_requires_idempotency_key(self):
        resp = self.client.post(
            "/api/v1/payments/topups",
            {"amount_minor": 10000000, "currency": "TZS", "msisdn": "+255754000891"},
            format="json",
        )
        self.assertEqual(resp.status_code, 400)

    @patch("payments.views.default_orchestrator", side_effect=build_test_orchestrator)
    def test_topup_then_webhook_resolves(self, _orch):
        # 1) Initiate STK-push top-up.
        resp = self.client.post(
            "/api/v1/payments/topups",
            {"amount_minor": 10000000, "currency": "TZS", "msisdn": "+255754000891"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="api-topup-1",
        )
        self.assertEqual(resp.status_code, 201)
        body = resp.json()
        self.assertEqual(body["status"], "processing")
        checkout_id = body["provider_ref"]
        self.assertTrue(checkout_id)

        # 2) Daraja calls our webhook with a success result.
        callback = {
            "Body": {"stkCallback": {"CheckoutRequestID": checkout_id, "ResultCode": 0, "ResultDesc": "ok"}}
        }
        wh = self.client.post("/api/v1/payments/webhooks/mpesa/stk", callback, format="json")
        self.assertEqual(wh.status_code, 200)
        self.assertEqual(wh.json()["ResultCode"], 0)

        # 3) The transaction is now settled and scoped to this device's owner.
        detail = self.client.get(f"/api/v1/payments/transactions/{body['id']}")
        self.assertEqual(detail.status_code, 200)
        self.assertEqual(detail.json()["status"], "succeeded")
        self.assertIsNotNone(detail.json()["ledger_entry"])

    @patch("payments.views.default_orchestrator", side_effect=build_test_orchestrator)
    def test_topup_then_demo_complete_settles(self, _orch):
        resp = self.client.post(
            "/api/v1/payments/topups",
            {"amount_minor": 10000000, "currency": "TZS", "msisdn": "+255754000891"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="api-topup-demo-1",
        )
        self.assertEqual(resp.status_code, 201)
        body = resp.json()
        self.assertEqual(body["status"], "processing")
        txn_id = body["id"]

        with self.settings(ALLOW_DEMO_STK=True):
            done = self.client.post(f"/api/v1/payments/topups/{txn_id}/demo-complete", format="json")
        self.assertEqual(done.status_code, 200)
        self.assertEqual(done.json()["status"], "succeeded")
        self.assertIsNotNone(done.json()["ledger_entry"])

        wallet = self.client.get("/api/v1/payments/wallet")
        self.assertEqual(wallet.status_code, 200)
        # Opening 2,847,500 + top-up 100,000
        self.assertEqual(wallet.json()["balance_minor"], 284750000 + 10000000)

    @patch("payments.views.default_orchestrator", side_effect=build_test_orchestrator)
    @patch("payments.views.live_mpesa_gateway")
    def test_topup_then_poll_status_settles(self, live_gw, _orch):
        from payments.gateways.base import PaymentAccepted, PaymentProvider

        gw = MagicMock()
        gw.status.return_value = PaymentAccepted(PaymentProvider.MPESA, provider_ref="ws_CO_poll")
        live_gw.return_value = gw

        resp = self.client.post(
            "/api/v1/payments/topups",
            {"amount_minor": 5000000, "currency": "TZS", "msisdn": "+255754000891"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="api-topup-poll-1",
        )
        self.assertEqual(resp.status_code, 201)
        txn_id = resp.json()["id"]
        # Offline gateway sets a provider_ref; ensure poll can match it.
        self.assertTrue(resp.json()["provider_ref"])

        done = self.client.post(f"/api/v1/payments/topups/{txn_id}/poll-status", format="json")
        self.assertEqual(done.status_code, 200)
        self.assertEqual(done.json()["status"], "succeeded")
        gw.status.assert_called_once()

    @patch("payments.views.live_mpesa_gateway", return_value=None)
    @patch("payments.views.default_orchestrator", side_effect=build_test_orchestrator)
    def test_poll_status_without_live_daraja_returns_503(self, _orch, _live):
        resp = self.client.post(
            "/api/v1/payments/topups",
            {"amount_minor": 1000000, "currency": "TZS", "msisdn": "+255754000891"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="api-topup-poll-503",
        )
        self.assertEqual(resp.status_code, 201)
        txn_id = resp.json()["id"]
        polled = self.client.post(f"/api/v1/payments/topups/{txn_id}/poll-status", format="json")
        self.assertEqual(polled.status_code, 503)

    def test_demo_complete_disabled_returns_403(self):
        with self.settings(ALLOW_DEMO_STK=False):
            resp = self.client.post(
                "/api/v1/payments/topups/00000000-0000-0000-0000-000000000001/demo-complete",
                format="json",
            )
        self.assertEqual(resp.status_code, 403)

    @patch("payments.views.default_orchestrator", side_effect=build_test_orchestrator)
    def test_transfer_via_api(self, _orch):
        resp = self.client.post(
            "/api/v1/payments/transfers",
            {
                "amount_minor": 25000000, "currency": "TZS", "counterparty": "Juma Ally",
                "method_kind": "mobile_money", "method_ref": "+255655000043", "operator": "airtel_money",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="api-xfer-1",
        )
        self.assertEqual(resp.status_code, 201)
        self.assertEqual(resp.json()["status"], "succeeded")
