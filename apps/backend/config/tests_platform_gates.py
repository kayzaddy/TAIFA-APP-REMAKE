"""P0 platform gates + outbox delivery evidence tests."""
from __future__ import annotations

from django.core.checks import run_checks
from django.test import SimpleTestCase, TestCase, override_settings

from enterprise import event_bus
from enterprise.models import EventOutbox


class PlatformProductionGateTests(SimpleTestCase):
    @override_settings(
        DEBUG=False,
        RUNNING_TESTS=False,
        SECRET_KEY="x" * 40,
        DATABASES={"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": ":memory:"}},
        CELERY_TASK_ALWAYS_EAGER=True,
        CACHES={
            "default": {
                "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
                "LOCATION": "gate-test",
            }
        },
        TAIFA_ALLOW_STUB_ADAPTERS=True,
        ALLOW_DEMO_WALLET_FUNDING=False,
        ALLOW_DEMO_STK=False,
        WITHDRAWAL_AUTO_APPROVE=False,
        MPESA_WEBHOOK_SHARED_SECRET="secret",
        RISK_PER_TXN_LIMIT_MINOR=1,
        RISK_DAILY_DEBIT_LIMIT_MINOR=1,
        RISK_ALLOW_UNLIMITED=False,
        MPESA={
            "CONSUMER_KEY": "",
            "CONSUMER_SECRET": "",
            "SHORTCODE": "",
            "PASSKEY": "",
            "INITIATOR_NAME": "",
            "SECURITY_CREDENTIAL": "",
            "CALLBACK_BASE_URL": "",
            "ENVIRONMENT": "sandbox",
        },
        AIRTEL_MONEY={"CLIENT_ID": "", "CLIENT_SECRET": "", "BASE_URL": ""},
        SELCOM={"BASE_URL": "", "API_KEY": "", "API_SECRET": "", "VENDOR": ""},
        CARD_ACQUIRER={"BASE_URL": "", "API_KEY": "", "MERCHANT_ID": ""},
    )
    def test_platform_gates_fire_on_unsafe_prod_defaults(self):
        errors = run_checks()
        ids = {e.id for e in errors}
        self.assertIn("platform.E002", ids)
        self.assertIn("platform.E003", ids)
        self.assertIn("platform.E004", ids)
        self.assertIn("platform.E005", ids)
        self.assertIn("platform.E006", ids)


class OutboxDeliveryTests(TestCase):
    def test_drain_marks_published_only_after_delivery_path(self):
        row = EventOutbox.objects.create(
            event_type="test.event",
            aggregate_type="test",
            aggregate_id="1",
            payload={"ok": True},
        )
        n = event_bus.drain_outbox(limit=10)
        self.assertGreaterEqual(n, 1)
        row.refresh_from_db()
        self.assertTrue(row.published)
        self.assertIsNotNone(row.published_at)

    @override_settings(DEBUG=False, RUNNING_TESTS=False, TAIFA_OUTBOX_WEBHOOK_URLS=[])
    def test_prod_without_consumers_does_not_publish(self):
        row = EventOutbox.objects.create(
            event_type="test.event.prod",
            aggregate_type="test",
            aggregate_id="2",
            payload={},
        )
        # Force non-test delivery rules inside deliver_outbox_row
        from django.conf import settings

        # RUNNING_TESTS is True under the test runner — override via monkeypatch
        settings.RUNNING_TESTS = False
        try:
            ok = event_bus.deliver_outbox_row(row)
            self.assertFalse(ok)
            row.refresh_from_db()
            self.assertFalse(row.published)
        finally:
            settings.RUNNING_TESTS = True
