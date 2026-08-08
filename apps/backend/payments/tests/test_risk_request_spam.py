"""Anti-abuse guard on MoneyRequest creation: caps unsolicited requests so a
stranger can't flood someone's inbox (money-request creation moves no money,
so this sits alongside RiskEngine rather than inside its debit/credit gate)."""
from django.test import override_settings
from rest_framework.test import APITestCase

from ..models import MoneyRequestStatus


class TwoDeviceMixin:
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


@override_settings(RISK_MAX_PENDING_REQUESTS_PER_PAYER=3, RISK_MAX_PENDING_REQUESTS_TOTAL=100)
class PerPayerSpamTests(TwoDeviceMixin, APITestCase):
    def _request(self, amount=1000):
        self.as_device(self.alice, "dev-alice")
        return self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": amount, "currency": "TZS"},
            format="json",
        )

    def test_blocks_after_limit_to_same_payer(self):
        for _ in range(3):
            resp = self._request()
            self.assertEqual(resp.status_code, 201, resp.content)
        blocked = self._request()
        self.assertEqual(blocked.status_code, 429)
        self.assertEqual(blocked.json()["code"], "REQUEST_SPAM_PER_PAYER")

    def test_paying_one_down_frees_a_slot(self):
        ids = [self._request().json()["id"] for _ in range(3)]
        self.assertEqual(self._request().status_code, 429)

        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            f"/api/v1/payments/requests/{ids[0]}/decline"
        )
        self.assertEqual(resp.json()["status"], MoneyRequestStatus.DECLINED)

        resp = self._request()
        self.assertEqual(resp.status_code, 201, resp.content)

    def test_different_payers_are_independent(self):
        carol = self.register("dev-carol")
        for _ in range(3):
            self.assertEqual(self._request().status_code, 201)
        self.assertEqual(self._request().status_code, 429)

        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/requests",
            {"payer": carol["owner"], "amount_minor": 1000, "currency": "TZS"},
            format="json",
        )
        self.assertEqual(resp.status_code, 201, resp.content)


@override_settings(RISK_MAX_PENDING_REQUESTS_PER_PAYER=0, RISK_MAX_PENDING_REQUESTS_TOTAL=2)
class TotalOutstandingSpamTests(TwoDeviceMixin, APITestCase):
    def test_blocks_after_total_outstanding_limit(self):
        carol = self.register("dev-carol")
        dave = self.register("dev-dave")
        self.as_device(self.alice, "dev-alice")
        r1 = self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": 1000, "currency": "TZS"},
            format="json",
        )
        r2 = self.client.post(
            "/api/v1/payments/requests",
            {"payer": carol["owner"], "amount_minor": 1000, "currency": "TZS"},
            format="json",
        )
        r3 = self.client.post(
            "/api/v1/payments/requests",
            {"payer": dave["owner"], "amount_minor": 1000, "currency": "TZS"},
            format="json",
        )
        self.assertEqual([r1.status_code, r2.status_code], [201, 201])
        self.assertEqual(r3.status_code, 429)
        self.assertEqual(r3.json()["code"], "REQUEST_SPAM_TOTAL")


@override_settings(RISK_MAX_PENDING_REQUESTS_PER_PAYER=1, RISK_MAX_PENDING_REQUESTS_TOTAL=100)
class BillSplitSpamTests(TwoDeviceMixin, APITestCase):
    def test_split_bill_blocked_if_a_participant_already_has_pending_requests(self):
        self.as_device(self.alice, "dev-alice")
        # Alice already has one pending request to bob (uses up the per-payer=1 slot).
        self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": 1000, "currency": "TZS"},
            format="json",
        )
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Dinner", "total_amount_minor": 2000, "split_type": "even",
                "participants": [{"payer": self.bob["owner"]}],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 429)
        self.assertEqual(resp.json()["code"], "REQUEST_SPAM_PER_PAYER")
        # And no shares should have been created (all-or-nothing check).
        from ..models import BillSplit
        self.assertEqual(BillSplit.objects.count(), 0)
