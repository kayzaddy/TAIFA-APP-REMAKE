"""Ziina-style social payments: payment links, money requests, receive-QR."""
from rest_framework.test import APITestCase

from ..models import MoneyRequestStatus, PaymentLink, PaymentLinkStatus

OPENING = 284750000  # demo opening balance, minor units


class TwoDeviceMixin:
    """Registers two funded wallets (alice pays bob unless stated otherwise)."""

    def register(self, device_id: str) -> dict:
        return self.client.post(
            "/api/v1/auth/device/register", {"device_id": device_id}, format="json"
        ).json()

    def as_device(self, reg: dict, device_id: str) -> None:
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}", HTTP_X_DEVICE_ID=device_id
        )

    def setUp(self):
        self.alice = self.register("dev-alice")
        self.bob = self.register("dev-bob")

    def balance_of(self, reg: dict, device_id: str) -> int:
        self.as_device(reg, device_id)
        return self.client.get("/api/v1/payments/wallet").json()["balance_minor"]


class PaymentLinkTests(TwoDeviceMixin, APITestCase):
    def _create_link(self, **overrides) -> dict:
        self.as_device(self.bob, "dev-bob")
        payload = {"amount_minor": 5000000, "currency": "TZS", "note": "Lunch", "emoji": "🍕"}
        payload.update(overrides)
        resp = self.client.post("/api/v1/payments/links", payload, format="json")
        assert resp.status_code == 201, resp.content
        return resp.json()

    def test_create_and_list_links(self):
        link = self._create_link()
        self.assertTrue(link["slug"])
        self.assertEqual(link["status"], "active")
        listing = self.client.get("/api/v1/payments/links").json()
        self.assertEqual(len(listing["links"]), 1)

    def test_public_info_needs_no_auth(self):
        link = self._create_link()
        self.client.credentials()  # drop auth
        resp = self.client.get(f"/api/v1/payments/pay/{link['slug']}")
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["amount_minor"], 5000000)
        self.assertEqual(body["emoji"], "🍕")
        self.assertNotIn("total_paid_minor", body)

    def test_pay_fixed_link_moves_money(self):
        link = self._create_link()
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-1",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(resp.json()["status"], "succeeded")
        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING - 5000000)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 5000000)
        # Receiver sees a receive_money transaction.
        wallet = self.client.get("/api/v1/payments/wallet").json()
        self.assertEqual(wallet["transactions"][0]["type"], "receive_money")

    def test_pay_replay_is_idempotent(self):
        link = self._create_link()
        self.as_device(self.alice, "dev-alice")
        for expected in (201, 200):
            resp = self.client.post(
                f"/api/v1/payments/pay/{link['slug']}/confirm",
                {},
                format="json",
                HTTP_IDEMPOTENCY_KEY="pay-replay",
            )
            self.assertEqual(resp.status_code, expected, resp.content)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 5000000)
        db_link = PaymentLink.objects.get(slug=link["slug"])
        self.assertEqual(db_link.payment_count, 1)

    def test_open_amount_link_requires_amount(self):
        link = self._create_link(amount_minor=None)
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-open-1",
        )
        self.assertEqual(resp.status_code, 422)
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {"amount_minor": 1234500},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-open-2",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 1234500)

    def test_single_use_link_completes(self):
        link = self._create_link(single_use=True)
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-single",
        )
        self.assertEqual(resp.status_code, 201)
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-single-2",
        )
        self.assertEqual(resp.status_code, 409)
        self.assertEqual(
            PaymentLink.objects.get(slug=link["slug"]).status, PaymentLinkStatus.COMPLETED
        )

    def test_cannot_pay_own_link(self):
        link = self._create_link()  # bob's link; stay as bob
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-self",
        )
        self.assertEqual(resp.status_code, 422)

    def test_insufficient_funds_fails_cleanly(self):
        link = self._create_link(amount_minor=OPENING * 10)
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-broke",
        )
        # Engine records a failed transaction; no money moves either side.
        self.assertEqual(resp.json().get("status"), "failed")
        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING)

    def test_pause_resume(self):
        link = self._create_link()
        resp = self.client.post(f"/api/v1/payments/links/{link['id']}/pause")
        self.assertEqual(resp.json()["status"], "paused")
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="pay-paused",
        )
        self.assertEqual(resp.status_code, 409)
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(f"/api/v1/payments/links/{link['id']}/resume")
        self.assertEqual(resp.json()["status"], "active")


class MoneyRequestTests(TwoDeviceMixin, APITestCase):
    def _request_from_alice(self, **overrides) -> dict:
        """Bob asks alice for money."""
        self.as_device(self.bob, "dev-bob")
        payload = {
            "payer": self.alice["owner"],
            "amount_minor": 2000000,
            "currency": "TZS",
            "note": "Rent split",
            "emoji": "🏠",
        }
        payload.update(overrides)
        resp = self.client.post("/api/v1/payments/requests", payload, format="json")
        assert resp.status_code == 201, resp.content
        return resp.json()

    def test_create_and_inbox(self):
        req = self._request_from_alice()
        self.assertEqual(req["status"], "pending")
        self.as_device(self.alice, "dev-alice")
        inbox = self.client.get("/api/v1/payments/requests").json()
        self.assertEqual(len(inbox["received"]), 1)
        self.assertEqual(inbox["received"][0]["emoji"], "🏠")

    def test_unknown_payer_404(self):
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            "/api/v1/payments/requests",
            {"payer": "nobody-here", "amount_minor": 1000, "currency": "TZS"},
            format="json",
        )
        self.assertEqual(resp.status_code, 404)

    def test_pay_request_settles_and_links_transaction(self):
        req = self._request_from_alice()
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/requests/{req['id']}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="req-pay-1",
        )
        self.assertEqual(resp.status_code, 200, resp.content)
        body = resp.json()
        self.assertEqual(body["status"], MoneyRequestStatus.PAID)
        self.assertTrue(body["transaction_id"])
        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING - 2000000)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 2000000)

    def test_only_payer_can_pay_or_decline(self):
        req = self._request_from_alice()  # bob is requester, still authed as bob
        resp = self.client.post(
            f"/api/v1/payments/requests/{req['id']}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="req-pay-wrong",
        )
        self.assertEqual(resp.status_code, 403)
        resp = self.client.post(f"/api/v1/payments/requests/{req['id']}/decline")
        self.assertEqual(resp.status_code, 403)

    def test_decline_and_cancel(self):
        req = self._request_from_alice()
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(f"/api/v1/payments/requests/{req['id']}/decline")
        self.assertEqual(resp.json()["status"], MoneyRequestStatus.DECLINED)

        req2 = self._request_from_alice()
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(f"/api/v1/payments/requests/{req2['id']}/cancel")
        self.assertEqual(resp.json()["status"], MoneyRequestStatus.CANCELLED)
        # A cancelled request can no longer be paid.
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/requests/{req2['id']}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="req-pay-cancelled",
        )
        self.assertEqual(resp.status_code, 409)

    def test_strangers_cannot_see_requests(self):
        req = self._request_from_alice()
        mallory = self.register("dev-mallory")
        self.as_device(mallory, "dev-mallory")
        resp = self.client.post(f"/api/v1/payments/requests/{req['id']}/decline")
        self.assertEqual(resp.status_code, 404)


class ReceiveQrTests(TwoDeviceMixin, APITestCase):
    def test_qr_is_stable_and_payable(self):
        self.as_device(self.bob, "dev-bob")
        first = self.client.get("/api/v1/payments/wallet/qr").json()
        second = self.client.get("/api/v1/payments/wallet/qr").json()
        self.assertEqual(first["slug"], second["slug"])
        self.assertEqual(first["qr_payload"], f"taifa://pay/{first['slug']}")
        # Alice scans → pays an amount of her choosing.
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            f"/api/v1/payments/pay/{first['slug']}/confirm",
            {"amount_minor": 750000},
            format="json",
            HTTP_IDEMPOTENCY_KEY="qr-pay-1",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 750000)
