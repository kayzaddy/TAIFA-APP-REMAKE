"""Split bills: organizer paid, friends each owe a share."""
from rest_framework.test import APITestCase

from ..models import BillSplitStatus, MoneyRequestStatus

OPENING = 284750000


class ThreeDeviceMixin:
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
        self.alice = self.register("dev-alice")  # organizer
        self.bob = self.register("dev-bob")
        self.carol = self.register("dev-carol")


class EvenSplitTests(ThreeDeviceMixin, APITestCase):
    def _create_bill(self, **overrides):
        self.as_device(self.alice, "dev-alice")
        payload = {
            "title": "Dinner at Slipway",
            "emoji": "🍽️",
            "currency": "TZS",
            "total_amount_minor": 9000000,  # 90,000 across 3 people (alice+bob+carol)
            "split_type": "even",
            "participants": [{"payer": self.bob["owner"]}, {"payer": self.carol["owner"]}],
        }
        payload.update(overrides)
        resp = self.client.post("/api/v1/payments/bills", payload, format="json")
        assert resp.status_code == 201, resp.content
        return resp.json()

    def test_even_split_creates_equal_shares_summing_to_total(self):
        bill = self._create_bill()
        self.assertEqual(bill["status"], "open")
        self.assertEqual(len(bill["shares"]), 2)
        amounts = [s["amount_minor"] for s in bill["shares"]]
        self.assertEqual(amounts, [3000000, 3000000])
        # organizer's implicit third share (3,000,000) + two requested shares == total.
        self.assertEqual(sum(amounts) + 3000000, bill["total_amount_minor"])

    def test_uneven_total_distributes_remainder_without_losing_a_cent(self):
        # 100 minor units / 3 people = 33,33,34 (or similar) — must sum exactly.
        bill = self._create_bill(total_amount_minor=100, participants=[
            {"payer": self.bob["owner"]}, {"payer": self.carol["owner"]},
        ])
        shares = [s["amount_minor"] for s in bill["shares"]]
        organizer_implicit = 100 - sum(shares)
        self.assertEqual(sum(shares) + organizer_implicit, 100)
        self.assertTrue(all(s in (33, 34) for s in shares + [organizer_implicit]))

    def test_bill_appears_in_organizer_and_participant_listings(self):
        self._create_bill()
        self.as_device(self.alice, "dev-alice")
        mine = self.client.get("/api/v1/payments/bills").json()
        self.assertEqual(len(mine["organized"]), 1)
        self.assertEqual(len(mine["owing"]), 0)

        self.as_device(self.bob, "dev-bob")
        bobs = self.client.get("/api/v1/payments/bills").json()
        self.assertEqual(len(bobs["organized"]), 0)
        self.assertEqual(len(bobs["owing"]), 1)

    def test_paying_all_shares_settles_the_bill(self):
        bill = self._create_bill()
        bob_share = next(s for s in bill["shares"] if s["payer"] == self.bob["owner"])
        carol_share = next(s for s in bill["shares"] if s["payer"] == self.carol["owner"])

        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            f"/api/v1/payments/requests/{bob_share['id']}/pay",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="bill-pay-bob",
        )
        self.assertEqual(resp.status_code, 200, resp.content)

        # Not settled yet — carol hasn't paid.
        self.as_device(self.alice, "dev-alice")
        mid = self.client.get(f"/api/v1/payments/bills/{bill['id']}").json()
        self.assertEqual(mid["status"], "open")

        self.as_device(self.carol, "dev-carol")
        resp = self.client.post(
            f"/api/v1/payments/requests/{carol_share['id']}/pay",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="bill-pay-carol",
        )
        self.assertEqual(resp.status_code, 200, resp.content)

        self.as_device(self.alice, "dev-alice")
        done = self.client.get(f"/api/v1/payments/bills/{bill['id']}").json()
        self.assertEqual(done["status"], "settled")
        self.assertEqual(done["paid_amount_minor"], 6000000)
        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING + 6000000)

    def test_duplicate_participant_rejected(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Oops", "total_amount_minor": 1000, "split_type": "even",
                "participants": [{"payer": self.bob["owner"]}, {"payer": self.bob["owner"]}],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 422)

    def test_cannot_split_with_self(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Oops", "total_amount_minor": 1000, "split_type": "even",
                "participants": [{"payer": self.alice["owner"]}],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 422)

    def test_unknown_participant_404(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Oops", "total_amount_minor": 1000, "split_type": "even",
                "participants": [{"payer": "nobody-here"}],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 404)


class CustomSplitTests(ThreeDeviceMixin, APITestCase):
    def test_custom_amounts_used_verbatim(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Uneven dinner", "total_amount_minor": 10000000, "split_type": "custom",
                "participants": [
                    {"payer": self.bob["owner"], "amount_minor": 2000000},
                    {"payer": self.carol["owner"], "amount_minor": 5000000},
                ],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        amounts = sorted(s["amount_minor"] for s in resp.json()["shares"])
        self.assertEqual(amounts, [2000000, 5000000])

    def test_custom_shares_cannot_exceed_total(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Bad math", "total_amount_minor": 1000000, "split_type": "custom",
                "participants": [{"payer": self.bob["owner"], "amount_minor": 2000000}],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 400)

    def test_custom_split_requires_amount_per_participant(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Missing amount", "total_amount_minor": 1000000, "split_type": "custom",
                "participants": [{"payer": self.bob["owner"]}],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 400)


class CancelBillTests(ThreeDeviceMixin, APITestCase):
    def test_organizer_cancels_pending_shares(self):
        self.as_device(self.alice, "dev-alice")
        bill = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Cancelled trip", "total_amount_minor": 6000000, "split_type": "even",
                "participants": [{"payer": self.bob["owner"]}, {"payer": self.carol["owner"]}],
            },
            format="json",
        ).json()
        resp = self.client.post(f"/api/v1/payments/bills/{bill['id']}/cancel")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["status"], BillSplitStatus.CANCELLED)
        for share in resp.json()["shares"]:
            self.assertEqual(share["status"], MoneyRequestStatus.CANCELLED)

    def test_non_organizer_cannot_cancel(self):
        self.as_device(self.alice, "dev-alice")
        bill = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Not yours", "total_amount_minor": 2000000, "split_type": "even",
                "participants": [{"payer": self.bob["owner"]}],
            },
            format="json",
        ).json()
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(f"/api/v1/payments/bills/{bill['id']}/cancel")
        self.assertEqual(resp.status_code, 404)

    def test_cancelled_share_cannot_be_paid(self):
        self.as_device(self.alice, "dev-alice")
        bill = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Cancel then pay", "total_amount_minor": 2000000, "split_type": "even",
                "participants": [{"payer": self.bob["owner"]}],
            },
            format="json",
        ).json()
        share_id = bill["shares"][0]["id"]
        self.client.post(f"/api/v1/payments/bills/{bill['id']}/cancel")

        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(
            f"/api/v1/payments/requests/{share_id}/pay",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="pay-cancelled-share",
        )
        self.assertEqual(resp.status_code, 409)


class SplitByPhoneTests(ThreeDeviceMixin, APITestCase):
    def test_split_participants_by_phone(self):
        self.as_device(self.bob, "dev-bob")
        self.client.post("/api/v1/auth/device/profile", {"phone_number": "+255700000002"}, format="json")

        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Phone split", "total_amount_minor": 4000000, "split_type": "even",
                "participants": [{"phone_number": "+255 700 000 002"}],
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(resp.json()["shares"][0]["payer"], self.bob["owner"])
