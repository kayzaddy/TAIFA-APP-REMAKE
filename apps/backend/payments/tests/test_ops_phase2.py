"""Phase 2 ops probes and structured logging tests."""
from __future__ import annotations

import json

from django.test import SimpleTestCase, TestCase, override_settings
from rest_framework.test import APIClient

from config.logging_json import JsonLogFormatter, redact_value
from config.middleware import normalize_path


class HealthProbeTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_liveness(self):
        resp = self.client.get("/healthz")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["probe"], "liveness")

    def test_readiness(self):
        resp = self.client.get("/readyz")
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertEqual(body["probe"], "readiness")
        self.assertIn("database", body["checks"])
        self.assertEqual(body["checks"]["database"]["status"], "ok")

    def test_startup(self):
        resp = self.client.get("/startupz")
        self.assertEqual(resp.status_code, 200)
        self.assertEqual(resp.json()["probe"], "startup")
        self.assertEqual(resp.json()["checks"]["migrations"]["status"], "ok")

    def test_dependencies(self):
        resp = self.client.get("/depsz")
        self.assertEqual(resp.status_code, 200)
        body = resp.json()
        self.assertIn("ledger", body["checks"])
        self.assertIn("risk_engine", body["checks"])
        self.assertIn("payment_engine", body["checks"])


class LoggingRedactionTests(SimpleTestCase):
    def test_redacts_secrets(self):
        self.assertEqual(redact_value("password", "hunter2"), "[REDACTED]")
        self.assertEqual(redact_value("pin", "1234"), "[REDACTED]")
        self.assertIn("[REDACTED_CARD]", redact_value("note", "card 4111111111111111"))

    def test_json_formatter_emits_required_fields(self):
        import logging

        record = logging.LogRecord(
            name="payments.test",
            level=logging.INFO,
            pathname=__file__,
            lineno=1,
            msg="hello",
            args=(),
            exc_info=None,
        )
        record.request_id = "abc123"
        line = JsonLogFormatter().format(record)
        payload = json.loads(line)
        for key in (
            "timestamp",
            "severity",
            "message",
            "service",
            "environment",
            "request_id",
            "trace_id",
            "correlation_id",
        ):
            self.assertIn(key, payload)


class MetricsOpsTests(TestCase):
    def test_http_metrics_and_slo_gauges(self):
        client = APIClient()
        client.get("/healthz")
        client.get("/api/v1/payments/wallet")  # 401 — still counted if not skipped
        body = client.get("/metrics").content.decode("utf-8")
        self.assertIn("taifa_http_requests_total", body)
        self.assertIn("taifa_http_request_duration_seconds", body)
        self.assertIn("taifa_slo_target", body)
        self.assertIn("taifa_celery_queue_depth", body)


class PathNormalizeTests(SimpleTestCase):
    def test_uuid_collapsed(self):
        path = normalize_path("/api/v1/payments/topups/6c4546ec-4ba0-47b0-bf8c-3c0d0db25eb4/poll-status")
        self.assertEqual(path, "/api/v1/payments/topups/{id}/poll-status")


@override_settings(TAIFA_LOG_JSON=True)
class JsonLoggingSettingsSmoke(SimpleTestCase):
    def test_formatter_importable(self):
        from config.logging_json import JsonLogFormatter

        self.assertTrue(callable(JsonLogFormatter))
