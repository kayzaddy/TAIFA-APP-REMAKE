"""Push notifications fire on money events (request created/paid, bill
share, link payment) and land in the recipient's inbox. CELERY_TASK_ALWAYS_EAGER
defaults to True in tests, so `.delay()` runs inline — no broker needed."""
from rest_framework.test import APITestCase

from ..models import PushNotification


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


class MoneyRequestNotificationTests(TwoDeviceMixin, APITestCase):
    def test_creating_request_notifies_payer(self):
        self.as_device(self.alice, "dev-alice")
        self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": 5000, "currency": "TZS", "emoji": "🍕"},
            format="json",
        )
        notes = PushNotification.objects.filter(owner=self.bob["owner"])
        self.assertEqual(notes.count(), 1)
        self.assertIn("requested", notes.first().body)

    def test_paying_request_notifies_requester(self):
        self.as_device(self.alice, "dev-alice")
        req = self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": 5000, "currency": "TZS"},
            format="json",
        ).json()
        PushNotification.objects.all().delete()  # clear the "requested" note

        self.as_device(self.bob, "dev-bob")
        self.client.post(
            f"/api/v1/payments/requests/{req['id']}/pay",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="notif-pay-1",
        )
        notes = PushNotification.objects.filter(owner=self.alice["owner"])
        self.assertEqual(notes.count(), 1)
        self.assertIn("paid", notes.first().body)

    def test_notification_endpoint_lists_and_marks_read(self):
        self.as_device(self.alice, "dev-alice")
        self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": 5000, "currency": "TZS"},
            format="json",
        )
        self.as_device(self.bob, "dev-bob")
        resp = self.client.get("/api/v1/payments/notifications")
        body = resp.json()
        self.assertEqual(body["unread_count"], 1)
        self.assertEqual(len(body["notifications"]), 1)
        note_id = body["notifications"][0]["id"]

        resp = self.client.post(f"/api/v1/payments/notifications/{note_id}/read")
        self.assertTrue(resp.json()["read"])
        resp = self.client.get("/api/v1/payments/notifications")
        self.assertEqual(resp.json()["unread_count"], 0)

    def test_cannot_read_someone_elses_notification(self):
        self.as_device(self.alice, "dev-alice")
        self.client.post(
            "/api/v1/payments/requests",
            {"payer": self.bob["owner"], "amount_minor": 5000, "currency": "TZS"},
            format="json",
        )
        note = PushNotification.objects.get(owner=self.bob["owner"])
        resp = self.client.post(f"/api/v1/payments/notifications/{note.id}/read")  # still auth'd as alice
        self.assertEqual(resp.status_code, 404)


class PaymentLinkNotificationTests(TwoDeviceMixin, APITestCase):
    def test_paying_a_link_notifies_the_owner(self):
        self.as_device(self.bob, "dev-bob")
        link = self.client.post(
            "/api/v1/payments/links",
            {"amount_minor": 20000, "currency": "TZS", "emoji": "🍟"},
            format="json",
        ).json()

        self.as_device(self.alice, "dev-alice")
        self.client.post(
            f"/api/v1/payments/pay/{link['slug']}/confirm",
            {}, format="json", HTTP_IDEMPOTENCY_KEY="notif-link-1",
        )
        notes = PushNotification.objects.filter(owner=self.bob["owner"])
        self.assertEqual(notes.count(), 1)
        self.assertIn("received", notes.first().body.lower())

    def test_replayed_payment_does_not_double_notify(self):
        self.as_device(self.bob, "dev-bob")
        link = self.client.post(
            "/api/v1/payments/links", {"amount_minor": 20000, "currency": "TZS"}, format="json"
        ).json()
        self.as_device(self.alice, "dev-alice")
        for _ in range(2):
            self.client.post(
                f"/api/v1/payments/pay/{link['slug']}/confirm",
                {}, format="json", HTTP_IDEMPOTENCY_KEY="notif-link-replay",
            )
        self.assertEqual(PushNotification.objects.filter(owner=self.bob["owner"]).count(), 1)


class BillSplitNotificationTests(TwoDeviceMixin, APITestCase):
    def test_creating_split_notifies_every_participant(self):
        carol = self.register("dev-carol")
        self.as_device(self.alice, "dev-alice")
        self.client.post(
            "/api/v1/payments/bills",
            {
                "title": "Dinner", "total_amount_minor": 9000, "split_type": "even",
                "participants": [{"payer": self.bob["owner"]}, {"payer": carol["owner"]}],
            },
            format="json",
        )
        self.assertEqual(PushNotification.objects.filter(owner=self.bob["owner"]).count(), 1)
        self.assertEqual(PushNotification.objects.filter(owner=carol["owner"]).count(), 1)
        note = PushNotification.objects.get(owner=self.bob["owner"])
        self.assertIn("Dinner", note.body)
