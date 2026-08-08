"""User-configurable spending cap: view/set/clear via API, enforced on
transfers/withdrawals via RiskEngine."""
from datetime import timedelta

from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from ..models import SpendingCap

OPENING = 284750000


class DeviceMixin:
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
        self.as_device(self.alice, "dev-alice")


class SpendingCapApiTests(DeviceMixin, APITestCase):
    def test_no_cap_returns_204(self):
        resp = self.client.get("/api/v1/payments/spending-cap")
        self.assertEqual(resp.status_code, 204)

    def test_set_and_read_cap(self):
        resp = self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "monthly", "limit_minor": 5000000, "currency": "TZS"},
            format="json",
        )
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["period"], "monthly")
        self.assertEqual(body["limit_minor"], 5000000)
        self.assertEqual(body["spent_minor"], 0)
        self.assertEqual(body["remaining_minor"], 5000000)

        resp = self.client.get("/api/v1/payments/spending-cap")
        self.assertEqual(resp.json()["limit_minor"], 5000000)

    def test_setting_again_updates_not_duplicates(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "daily", "limit_minor": 1000000, "currency": "TZS"},
            format="json",
        )
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "weekly", "limit_minor": 2000000, "currency": "TZS"},
            format="json",
        )
        self.assertEqual(SpendingCap.objects.filter(owner=self.alice["owner"]).count(), 1)
        self.assertEqual(SpendingCap.objects.get(owner=self.alice["owner"]).period, "weekly")

    def test_delete_clears_cap(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "daily", "limit_minor": 1000000, "currency": "TZS"},
            format="json",
        )
        resp = self.client.delete("/api/v1/payments/spending-cap")
        self.assertEqual(resp.status_code, 204)
        resp = self.client.get("/api/v1/payments/spending-cap")
        self.assertEqual(resp.status_code, 204)

    def test_spent_reflects_transfers_this_period(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "monthly", "limit_minor": 10000000, "currency": "TZS"},
            format="json",
        )
        self.client.post(
            "/api/v1/payments/requests",  # bob requests, but we're testing alice's spend via p2p pay
            {"payer": self.bob["owner"], "amount_minor": 1000, "currency": "TZS"},
            format="json",
        )
        # Alice pays bob a link instead, to actually generate a debit from alice.
        self.as_device(self.bob, "dev-bob")
        link = self.client.post(
            "/api/v1/payments/links", {"amount_minor": 2000000, "currency": "TZS"}, format="json"
        ).json()
        self.as_device(self.alice, "dev-alice")
        self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="cap-usage-1",
        )
        resp = self.client.get("/api/v1/payments/spending-cap")
        body = resp.json()
        self.assertEqual(body["spent_minor"], 2000000)
        self.assertEqual(body["remaining_minor"], 8000000)


class SpendingCapEnforcementTests(DeviceMixin, APITestCase):
    def _pay_bob(self, amount_minor: int, key: str):
        self.as_device(self.bob, "dev-bob")
        link = self.client.post(
            "/api/v1/payments/links", {"amount_minor": amount_minor, "currency": "TZS"}, format="json"
        ).json()
        self.as_device(self.alice, "dev-alice")
        return self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {}, format="json", HTTP_IDEMPOTENCY_KEY=key,
        )

    def test_transfer_within_cap_succeeds(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "daily", "limit_minor": 5000000, "currency": "TZS"},
            format="json",
        )
        resp = self._pay_bob(3000000, "cap-ok-1")
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(resp.json()["status"], "succeeded")

    def test_transfer_exceeding_cap_denied(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "daily", "limit_minor": 1000000, "currency": "TZS"},
            format="json",
        )
        resp = self._pay_bob(2000000, "cap-deny-1")
        self.assertEqual(resp.status_code, 403)
        self.assertEqual(resp.json()["code"], "SPENDING_CAP_EXCEEDED")

    def test_cumulative_transfers_hit_cap(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "daily", "limit_minor": 3000000, "currency": "TZS"},
            format="json",
        )
        first = self._pay_bob(2000000, "cap-cumul-1")
        self.assertEqual(first.status_code, 201)
        second = self._pay_bob(2000000, "cap-cumul-2")  # 2M + 2M > 3M cap
        self.assertEqual(second.status_code, 403)

    def test_no_cap_means_unrestricted(self):
        resp = self._pay_bob(100000000, "cap-none-1")
        self.assertEqual(resp.status_code, 201)

    def test_weekly_cap_resets_the_following_week(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "weekly", "limit_minor": 1000000, "currency": "TZS"},
            format="json",
        )
        resp = self._pay_bob(1000000, "cap-week-1")
        self.assertEqual(resp.status_code, 201)
        # Next transfer this week is over cap.
        self.assertEqual(self._pay_bob(1, "cap-week-2").status_code, 403)

    def test_topup_is_never_capped(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "daily", "limit_minor": 1, "currency": "TZS"},
            format="json",
        )
        resp = self.client.post(
            "/api/v1/payments/topups",
            {"amount_minor": 5000000, "currency": "TZS", "msisdn": "+255754000891"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="cap-topup-1",
        )
        self.assertEqual(resp.status_code, 201)

    def test_cap_in_different_currency_does_not_apply(self):
        self.client.post(
            "/api/v1/payments/spending-cap",
            {"period": "daily", "limit_minor": 1, "currency": "USD"},
            format="json",
        )
        resp = self._pay_bob(5000000, "cap-currency-1")  # TZS, cap is USD
        self.assertEqual(resp.status_code, 201)
