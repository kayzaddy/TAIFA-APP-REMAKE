"""Merchant-tier fees on payment links: platform takes a cut, P2P stays free."""
from django.test import override_settings
from rest_framework.test import APITestCase

from ..models import PaymentLink

OPENING = 284750000


class TwoDeviceMixin:
    def register(self, device_id: str) -> dict:
        return self.client.post(
            "/api/v1/auth/device/register", {"device_id": device_id}, format="json"
        ).json()

    def as_device(self, reg: dict, device_id: str) -> None:
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}", HTTP_X_DEVICE_ID=device_id
        )

    def balance_of(self, reg: dict, device_id: str) -> int:
        self.as_device(reg, device_id)
        return self.client.get("/api/v1/payments/wallet").json()["balance_minor"]

    def setUp(self):
        self.alice = self.register("dev-alice")  # customer
        self.bob = self.register("dev-bob")  # merchant


class MerchantOptInTests(TwoDeviceMixin, APITestCase):
    def test_enable_and_disable(self):
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post("/api/v1/auth/device/merchant", {"enable": True}, format="json")
        self.assertEqual(resp.status_code, 200)
        self.assertTrue(resp.json()["is_merchant"])
        self.assertEqual(resp.json()["fee_bps"], 150)

        resp = self.client.post("/api/v1/auth/device/merchant", {"enable": False}, format="json")
        self.assertFalse(resp.json()["is_merchant"])
        self.assertEqual(resp.json()["fee_bps"], 0)


@override_settings(PAYMENTS_MERCHANT_FEE_BPS=150)  # 1.5%
class MerchantLinkFeeTests(TwoDeviceMixin, APITestCase):
    def _bob_goes_merchant(self):
        self.as_device(self.bob, "dev-bob")
        self.client.post("/api/v1/auth/device/merchant", {"enable": True}, format="json")

    def test_merchant_link_snapshots_fee_bps(self):
        self._bob_goes_merchant()
        resp = self.client.post(
            "/api/v1/payments/links",
            {"amount_minor": 1000000, "currency": "TZS", "note": "Coffee"},
            format="json",
        )
        self.assertEqual(resp.json()["fee_bps"], 150)

    def test_plain_link_has_no_fee(self):
        # bob never opts in
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            "/api/v1/payments/links", {"amount_minor": 1000000, "currency": "TZS"}, format="json"
        )
        self.assertEqual(resp.json()["fee_bps"], 0)

    def test_paying_merchant_link_charges_customer_full_price_but_merchant_gets_net(self):
        self._bob_goes_merchant()
        link = self.client.post(
            "/api/v1/payments/links",
            {"amount_minor": 1000000, "currency": "TZS", "note": "Coffee"},  # TSh 10,000
            format="json",
        ).json()

        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="merch-pay-1",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        payer_txn = resp.json()
        # Customer pays exactly the sticker price — fee is invisible to them.
        self.assertEqual(payer_txn["amount_minor"], 1000000)
        self.assertEqual(payer_txn["fee_minor"], 15000)  # 1.5% of 1,000,000
        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING - 1000000)

        # Merchant receives amount minus fee.
        self.as_device(self.bob, "dev-bob")
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 985000)
        wallet = self.client.get("/api/v1/payments/wallet").json()
        recv = wallet["transactions"][0]
        self.assertEqual(recv["type"], "receive_money")
        self.assertEqual(recv["amount_minor"], 985000)
        self.assertEqual(recv["fee_minor"], 15000)

    def test_ledger_balances_after_fee_payment(self):
        self._bob_goes_merchant()
        link = self.client.post(
            "/api/v1/payments/links", {"amount_minor": 777700, "currency": "TZS"}, format="json"
        ).json()
        self.as_device(self.alice, "dev-alice")
        self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="merch-pay-recon",
        )
        from ..reconciliation import run_reconciliation
        result = run_reconciliation(record=False)
        self.assertTrue(result.ok, result.by_check())

    def test_p2p_between_two_merchants_is_still_free(self):
        # Fee only applies to *links*; a plain money request between two
        # merchants (or anyone) never carries a fee.
        self._bob_goes_merchant()
        self.as_device(self.alice, "dev-alice")
        self.client.post("/api/v1/auth/device/merchant", {"enable": True}, format="json")
        resp = self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": 500000, "currency": "TZS"},
            format="json",
        )
        req_id = resp.json()["id"]
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            f"/api/v1/payments/requests/{req_id}/pay",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="merch-p2p-1",
        )
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING + 500000)

    def test_toggling_merchant_off_does_not_retroactively_change_existing_link(self):
        self._bob_goes_merchant()
        link = self.client.post(
            "/api/v1/payments/links", {"amount_minor": 1000000, "currency": "TZS"}, format="json"
        ).json()
        self.client.post("/api/v1/auth/device/merchant", {"enable": False}, format="json")

        db_link = PaymentLink.objects.get(slug=link["slug"])
        self.assertEqual(db_link.fee_bps, 150)  # unchanged

        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="merch-pay-after-optout",
        )
        self.assertEqual(resp.json()["fee_minor"], 15000)  # still fee'd

    def test_qr_receive_link_also_carries_merchant_fee(self):
        self._bob_goes_merchant()
        qr = self.client.get("/api/v1/payments/wallet/qr").json()
        self.assertEqual(qr["fee_bps"], 150)
