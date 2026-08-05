"""Integration fabric tests — adapters, stub bans, certification evidence."""
from __future__ import annotations

from unittest.mock import MagicMock, patch

from django.core.checks import run_checks
from django.test import SimpleTestCase, TestCase, override_settings
from django.urls import reverse

from integrations.circuit import CircuitBreaker, CircuitOpen
from integrations.http_client import IntegrationHttpClient, IntegrationHttpError
from integrations.certification import build_certification_report
from integrations.catalog import build_catalog
from payments.gateways.factory import default_gateways
from payments.gateways.simulated import OfflineMpesaGateway
from trips.adapters.government import government_adapter


class CircuitBreakerTests(SimpleTestCase):
    def test_opens_after_threshold(self):
        br = CircuitBreaker(name="test.cb", failure_threshold=2, recovery_timeout_s=60)
        br.record_failure()
        br.before_call()  # still closed
        br.record_failure()
        with self.assertRaises(CircuitOpen):
            br.before_call()


class HttpClientTests(SimpleTestCase):
    def test_retries_on_timeout(self):
        session = MagicMock()
        import requests

        session.request.side_effect = [
            requests.Timeout("t1"),
            MagicMock(status_code=200, content=b"{}", json=lambda: {}, text="", headers={}),
        ]
        client = IntegrationHttpClient(
            integration="test.http",
            base_url="https://example.test",
            timeout_s=1,
            max_retries=2,
            session=session,
        )
        resp = client.request("GET", "/ok", operation="ping")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(session.request.call_count, 2)

    def test_missing_base_url_fails_closed(self):
        client = IntegrationHttpClient(integration="test.empty", base_url="")
        with self.assertRaises(IntegrationHttpError):
            client.request("GET", "/")


class StubBanTests(SimpleTestCase):
    @override_settings(TAIFA_ALLOW_STUB_ADAPTERS=False, TAIFA_GOVERNMENT_PROVIDERS={}, MOBILITY_GOVERNMENT_ADAPTERS={})
    def test_government_stub_refused_without_config(self):
        with self.assertRaises(RuntimeError):
            government_adapter("LATRA")

    @override_settings(
        TAIFA_ALLOW_STUB_ADAPTERS=True,
        TAIFA_GOVERNMENT_PROVIDERS={},
        MOBILITY_GOVERNMENT_ADAPTERS={},
    )
    def test_government_stub_allowed_in_dev(self):
        adapter = government_adapter("LATRA")
        result = adapter.submit_transport_statistics(
            period_start="2026-01-01", period_end="2026-01-31", payload={"trips": 1}
        )
        self.assertTrue(result.accepted)
        self.assertIn("STUB", result.reference)

    @override_settings(
        TAIFA_ALLOW_STUB_ADAPTERS=False,
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
    def test_payment_factory_omits_simulated_when_stubs_banned(self):
        gateways = default_gateways()
        self.assertEqual(gateways, [])
        self.assertFalse(any(isinstance(g, OfflineMpesaGateway) for g in gateways))


class CatalogCertificationTests(TestCase):
    def test_catalog_non_empty(self):
        catalog = build_catalog()
        self.assertGreaterEqual(len(catalog), 10)
        ids = {e["id"] for e in catalog}
        self.assertIn("payments.mpesa", ids)
        self.assertIn("identity.federation", ids)
        self.assertIn("ai.inference", ids)

    def test_certification_report_shape(self):
        report = build_certification_report()
        self.assertIn(report["answer"], {"Yes", "No"})
        self.assertIn(report["national_certification"], {"GO", "NO-GO"})
        self.assertIn("uncertified", report)
        self.assertIn("integrations", report)

    def test_api_endpoints(self):
        for name in ("integrations-catalog", "integrations-certification", "integrations-health"):
            resp = self.client.get(reverse(name))
            self.assertEqual(resp.status_code, 200)


class PlatformGateE006Tests(SimpleTestCase):
    @override_settings(
        DEBUG=False,
        RUNNING_TESTS=False,
        SECRET_KEY="x" * 40,
        DATABASES={"default": {"ENGINE": "django.db.backends.postgresql", "NAME": "x"}},
        CELERY_TASK_ALWAYS_EAGER=False,
        CACHES={
            "default": {
                "BACKEND": "django.core.cache.backends.redis.RedisCache",
                "LOCATION": "redis://127.0.0.1:6379/1",
            }
        },
        TAIFA_ALLOW_STUB_ADAPTERS=False,
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
    def test_e006_requires_live_payment_rail(self):
        errors = run_checks()
        ids = {e.id for e in errors}
        self.assertIn("platform.E006", ids)
