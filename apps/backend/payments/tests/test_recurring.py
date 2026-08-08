"""Standing orders: API surface + the beat-driven execution loop."""
from datetime import datetime, timedelta, timezone as dt_timezone

from django.utils import timezone
from rest_framework.test import APITestCase

from ..models import RecurringPayment, RecurringPaymentStatus
from ..recurring import next_run_after, run_due_recurring_payments

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
        self.alice = self.register("dev-alice")
        self.bob = self.register("dev-bob")


class NextRunAfterTests(APITestCase):
    def test_daily_and_weekly_are_exact(self):
        start = datetime(2026, 1, 15, 9, 0, tzinfo=dt_timezone.utc)
        self.assertEqual(next_run_after(start, "daily"), start + timedelta(days=1))
        self.assertEqual(next_run_after(start, "weekly"), start + timedelta(weeks=1))

    def test_monthly_clamps_end_of_month_safely(self):
        jan31 = datetime(2026, 1, 31, 9, 0, tzinfo=dt_timezone.utc)
        feb = next_run_after(jan31, "monthly")
        self.assertEqual((feb.year, feb.month, feb.day), (2026, 2, 28))  # 2026 not a leap year
        mar = next_run_after(feb, "monthly")
        self.assertEqual((mar.year, mar.month, mar.day), (2026, 3, 28))


class RecurringPaymentApiTests(TwoDeviceMixin, APITestCase):
    def test_create_and_list(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/recurring",
            {
                "payee": self.bob["owner"], "amount_minor": 500000, "currency": "TZS",
                "interval": "monthly", "note": "Rent share", "emoji": "🏠",
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        body = resp.json()
        self.assertEqual(body["status"], "active")
        self.assertEqual(body["consecutive_failures"], 0)

        listing = self.client.get("/api/v1/payments/recurring").json()
        self.assertEqual(len(listing["recurring_payments"]), 1)

    def test_cannot_target_self(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/recurring",
            {"payee": self.alice["owner"], "amount_minor": 1000, "currency": "TZS", "interval": "daily"},
            format="json",
        )
        self.assertEqual(resp.status_code, 422)

    def test_needs_payee_or_phone(self):
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/recurring",
            {"amount_minor": 1000, "currency": "TZS", "interval": "daily"},
            format="json",
        )
        self.assertEqual(resp.status_code, 400)

    def test_create_by_phone(self):
        self.as_device(self.bob, "dev-bob")
        self.client.post("/api/v1/auth/device/profile", {"phone_number": "+255711000111"}, format="json")
        self.as_device(self.alice, "dev-alice")
        resp = self.client.post(
            "/api/v1/payments/recurring",
            {
                "payee_phone": "+255711000111", "amount_minor": 1000, "currency": "TZS",
                "interval": "weekly",
            },
            format="json",
        )
        self.assertEqual(resp.status_code, 201, resp.content)
        self.assertEqual(resp.json()["payee"], self.bob["owner"])

    def test_pause_resume_cancel_lifecycle(self):
        self.as_device(self.alice, "dev-alice")
        rp = self.client.post(
            "/api/v1/payments/recurring",
            {"payee": self.bob["owner"], "amount_minor": 1000, "currency": "TZS", "interval": "daily"},
            format="json",
        ).json()

        resp = self.client.post(f"/api/v1/payments/recurring/{rp['id']}/pause")
        self.assertEqual(resp.json()["status"], "paused")
        resp = self.client.post(f"/api/v1/payments/recurring/{rp['id']}/pause")
        self.assertEqual(resp.status_code, 409)  # already paused

        resp = self.client.post(f"/api/v1/payments/recurring/{rp['id']}/resume")
        self.assertEqual(resp.json()["status"], "active")

        resp = self.client.post(f"/api/v1/payments/recurring/{rp['id']}/cancel")
        self.assertEqual(resp.json()["status"], "cancelled")
        resp = self.client.post(f"/api/v1/payments/recurring/{rp['id']}/resume")
        self.assertEqual(resp.status_code, 409)  # cancelled is terminal

    def test_strangers_cannot_control_others_orders(self):
        self.as_device(self.alice, "dev-alice")
        rp = self.client.post(
            "/api/v1/payments/recurring",
            {"payee": self.bob["owner"], "amount_minor": 1000, "currency": "TZS", "interval": "daily"},
            format="json",
        ).json()
        self.as_device(self.bob, "dev-bob")
        resp = self.client.post(f"/api/v1/payments/recurring/{rp['id']}/pause")
        self.assertEqual(resp.status_code, 404)


class RecurringExecutionTests(TwoDeviceMixin, APITestCase):
    def _make_due(self, amount_minor: int, interval: str = "monthly") -> RecurringPayment:
        return RecurringPayment.objects.create(
            owner=self.alice["owner"],
            payee=self.bob["owner"],
            amount_minor=amount_minor,
            currency="TZS",
            interval=interval,
            next_run_at=timezone.now() - timedelta(minutes=1),  # already due
        )

    def test_due_payment_executes_and_reschedules(self):
        rp = self._make_due(1000000)
        outcomes = run_due_recurring_payments()
        self.assertEqual(len(outcomes), 1)
        self.assertEqual(outcomes[0].status, "succeeded")

        rp.refresh_from_db()
        self.assertIsNotNone(rp.last_run_at)
        self.assertIsNotNone(rp.last_transaction)
        self.assertTrue(rp.next_run_at > timezone.now())  # advanced into the future
        self.assertEqual(rp.consecutive_failures, 0)

        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING - 1000000)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 1000000)

    def test_not_yet_due_payment_is_skipped(self):
        rp = RecurringPayment.objects.create(
            owner=self.alice["owner"], payee=self.bob["owner"], amount_minor=1000,
            currency="TZS", interval="daily", next_run_at=timezone.now() + timedelta(days=1),
        )
        outcomes = run_due_recurring_payments()
        self.assertEqual(outcomes, [])
        rp.refresh_from_db()
        self.assertIsNone(rp.last_run_at)

    def test_paused_and_cancelled_orders_never_run(self):
        for status_ in (RecurringPaymentStatus.PAUSED, RecurringPaymentStatus.CANCELLED):
            rp = self._make_due(1000)
            rp.status = status_
            rp.save(update_fields=["status"])
        outcomes = run_due_recurring_payments()
        self.assertEqual(outcomes, [])

    def test_insufficient_funds_counts_as_failure_without_moving_money(self):
        rp = self._make_due(OPENING * 100)  # far more than alice has
        outcomes = run_due_recurring_payments()
        self.assertEqual(outcomes[0].status, "failed")
        rp.refresh_from_db()
        self.assertEqual(rp.consecutive_failures, 1)
        self.assertEqual(rp.status, RecurringPaymentStatus.ACTIVE)  # below threshold still
        self.assertEqual(self.balance_of(self.alice, "dev-alice"), OPENING)
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING)

    def test_auto_pauses_after_max_consecutive_failures(self):
        rp = self._make_due(OPENING * 100, interval="daily")
        for i in range(1, 4):
            run_due_recurring_payments()
            rp.refresh_from_db()
            if i < 3:
                self.assertEqual(rp.status, RecurringPaymentStatus.ACTIVE)
            rp.next_run_at = timezone.now() - timedelta(minutes=1)  # force due again
            rp.save(update_fields=["next_run_at"])
        self.assertEqual(rp.status, RecurringPaymentStatus.PAUSED)
        self.assertEqual(rp.consecutive_failures, 3)

    def test_success_resets_failure_streak(self):
        rp = self._make_due(OPENING * 100, interval="daily")  # will fail
        run_due_recurring_payments()
        rp.refresh_from_db()
        self.assertEqual(rp.consecutive_failures, 1)

        rp.amount_minor = 1000  # now affordable
        rp.next_run_at = timezone.now() - timedelta(minutes=1)
        rp.save(update_fields=["amount_minor", "next_run_at"])
        run_due_recurring_payments()
        rp.refresh_from_db()
        self.assertEqual(rp.consecutive_failures, 0)
        self.assertEqual(rp.status, RecurringPaymentStatus.ACTIVE)

    def test_double_run_at_same_due_time_is_idempotent(self):
        """Guards against a beat misfire (two workers picking up the same
        tick): the occurrence key is derived from next_run_at, so replaying
        the exact same due state must not move money twice."""
        rp = self._make_due(1000000)
        due_at = rp.next_run_at
        run_due_recurring_payments()
        rp.refresh_from_db()
        # Simulate a duplicate beat tick still holding the pre-run due time.
        rp.next_run_at = due_at
        rp.save(update_fields=["next_run_at"])
        run_due_recurring_payments()
        self.assertEqual(self.balance_of(self.bob, "dev-bob"), OPENING + 1000000)
