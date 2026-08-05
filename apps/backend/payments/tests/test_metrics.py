"""Prometheus /metrics endpoint tests."""
from __future__ import annotations

from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from payments.models import Device


class MetricsEndpointTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_metrics_exposes_taifa_gauges(self):
        Device.objects.create(
            device_id="metrics-device-1",
            platform="test",
            token_hash="a" * 64,
            owner="owner-metrics-1",
        )
        resp = self.client.get("/metrics")
        self.assertEqual(resp.status_code, 200)
        self.assertIn("text/plain", resp["Content-Type"])
        body = resp.content.decode("utf-8")
        self.assertIn("taifa_transactions{", body)
        self.assertIn('taifa_transactions{status="succeeded"}', body)
        self.assertIn("taifa_webhook_events{", body)
        self.assertIn("taifa_pending_transactions_older_than_seconds{", body)
        self.assertIn("taifa_devices_total", body)
        self.assertIn("taifa_app_info{", body)
        self.assertIn("taifa_devices_total 1.0", body)

        from payments.reconciliation import run_reconciliation

        run_reconciliation(record=True)
        body2 = self.client.get("/metrics").content.decode("utf-8")
        self.assertIn("taifa_ledger_reconciliation_ok", body2)
        self.assertIn("taifa_ledger_reconciliation_breaks{", body2)
        self.assertIn("taifa_ledger_reconciliation_checked_at_seconds", body2)

    @override_settings(METRICS_ALLOWED_IPS=["203.0.113.10"])
    def test_metrics_rejects_disallowed_ip(self):
        resp = self.client.get("/metrics", REMOTE_ADDR="198.51.100.1")
        self.assertEqual(resp.status_code, 403)
