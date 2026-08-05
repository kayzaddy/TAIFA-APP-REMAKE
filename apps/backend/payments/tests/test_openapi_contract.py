"""OpenAPI contract gates — keep the committed schema generative and the
REST surfaces the mobile client depends on present and stable."""
from __future__ import annotations

import tempfile
from pathlib import Path

from django.core.management import call_command
from django.test import SimpleTestCase, TestCase
from django.urls import reverse

try:
    import yaml
except ImportError:  # pragma: no cover
    yaml = None

BACKEND_ROOT = Path(__file__).resolve().parents[2]
OPENAPI_PATH = BACKEND_ROOT / "openapi.yaml"

# Paths the Flutter Rest* repositories call today (under /api/v1/).
REQUIRED_API_PATHS = {
    "/api/v1/auth/device/register",
    "/api/v1/payments/wallet",
    "/api/v1/payments/topups",
    "/api/v1/payments/topups/{txn_id}/demo-complete",
    "/api/v1/payments/topups/{txn_id}/poll-status",
    "/api/v1/payments/transfers",
    "/api/v1/payments/withdrawals",
    "/api/v1/payments/withdrawals/{txn_id}/approve",
    "/api/v1/payments/withdrawals/{txn_id}/reject",
    "/api/v1/payments/withdrawals/{txn_id}/process",
    "/api/v1/payments/refunds",
    "/api/v1/payments/transactions/{txn_id}",
    "/api/v1/payments/transactions/{txn_id}/reverse",
    "/api/v1/payments/webhooks/mpesa/stk",
    "/api/v1/trips/",
    "/api/v1/trips/{trip_id}",
    "/api/v1/commerce/food-orders",
    "/api/v1/commerce/food-orders/{order_id}",
    "/api/v1/commerce/stay-bookings",
    "/api/v1/commerce/stay-bookings/{booking_id}",
    "/api/v1/commerce/flight-bookings",
    "/api/v1/commerce/flight-bookings/{booking_id}",
    "/api/v1/commerce/tour-bookings",
    "/api/v1/commerce/tour-bookings/{booking_id}",
    "/api/v1/commerce/winga-orders",
    "/api/v1/commerce/winga-orders/{order_id}",
    "/api/v1/commerce/winga-service-bookings",
    "/api/v1/commerce/winga-shops",
    "/api/v1/commerce/gov-requests",
    "/api/v1/commerce/gov-requests/{request_id}",
    "/api/v1/commerce/health-appointments",
    "/api/v1/commerce/health-appointments/{appointment_id}",
    "/api/v1/commerce/edu-payments",
    "/api/v1/commerce/edu-payments/{payment_id}",
    "/api/v1/commerce/housing-inquiries",
    "/api/v1/commerce/housing-inquiries/{inquiry_id}",
    "/api/v1/commerce/wealth-contributions",
    "/api/v1/commerce/wealth-contributions/{contribution_id}",
    "/api/v1/commerce/job-assignments",
    "/api/v1/commerce/job-assignments/{assignment_id}",
    "/api/v1/commerce/insurance-policies",
    "/api/v1/commerce/insurance-policies/{policy_id}",
    "/api/v1/commerce/family-transfers",
    "/api/v1/commerce/family-transfers/{transfer_id}",
    "/api/v1/commerce/huduma-bookings",
    "/api/v1/commerce/huduma-bookings/{booking_id}",
    "/api/v1/commerce/merchant-orders",
    "/api/v1/commerce/merchant-orders/{order_id}",
    "/api/v1/commerce/driver-jobs",
    "/api/v1/commerce/driver-jobs/{job_id}",
    "/api/v1/commerce/chat-threads",
    "/api/v1/commerce/chat-threads/{thread_id}",
    "/api/v1/commerce/chat-threads/{thread_id}/messages",
    "/api/v1/commerce/admin-cases",
    "/api/v1/commerce/admin-cases/{case_id}",
}


class OpenApiGenerationTests(SimpleTestCase):
    def test_spectacular_generates_without_warnings(self):
        from drf_spectacular.drainage import GENERATOR_STATS

        GENERATOR_STATS.reset()
        with tempfile.NamedTemporaryFile(suffix=".yaml", delete=False) as tmp:
            out = Path(tmp.name)
        try:
            call_command("spectacular", file=str(out))
            self.assertTrue(out.exists())
            self.assertGreater(out.stat().st_size, 500)
            self.assertFalse(
                GENERATOR_STATS._warn_cache,
                f"OpenAPI warnings: {list(GENERATOR_STATS._warn_cache)[:5]}",
            )
        finally:
            out.unlink(missing_ok=True)


class OpenApiContractTests(TestCase):
    def test_committed_openapi_lists_required_api_paths(self):
        self.assertTrue(OPENAPI_PATH.exists(), f"Missing {OPENAPI_PATH}")
        if yaml is None:
            self.skipTest("PyYAML not installed")
        schema = yaml.safe_load(OPENAPI_PATH.read_text(encoding="utf-8"))
        paths = set(schema.get("paths", {}))
        missing = REQUIRED_API_PATHS - paths
        self.assertFalse(missing, f"OpenAPI missing paths: {sorted(missing)}")

    def test_demo_complete_route_resolves(self):
        url = reverse(
            "payments:topup-demo-complete",
            kwargs={"txn_id": "00000000-0000-0000-0000-000000000001"},
        )
        self.assertEqual(
            url,
            "/api/v1/payments/topups/00000000-0000-0000-0000-000000000001/demo-complete",
        )

    def test_poll_status_route_resolves(self):
        url = reverse(
            "payments:topup-poll-status",
            kwargs={"txn_id": "00000000-0000-0000-0000-000000000001"},
        )
        self.assertEqual(
            url,
            "/api/v1/payments/topups/00000000-0000-0000-0000-000000000001/poll-status",
        )

    def test_commerce_and_trips_routes_resolve(self):
        self.assertEqual(reverse("trips:list-create"), "/api/v1/trips/")
        self.assertEqual(
            reverse(
                "trips:detail",
                kwargs={"trip_id": "00000000-0000-0000-0000-000000000001"},
            ),
            "/api/v1/trips/00000000-0000-0000-0000-000000000001",
        )
        self.assertEqual(reverse("commerce:food-orders"), "/api/v1/commerce/food-orders")
        self.assertEqual(reverse("commerce:stay-bookings"), "/api/v1/commerce/stay-bookings")
        self.assertEqual(
            reverse("commerce:flight-bookings"),
            "/api/v1/commerce/flight-bookings",
        )
        self.assertEqual(reverse("commerce:tour-bookings"), "/api/v1/commerce/tour-bookings")
        self.assertEqual(reverse("commerce:winga-orders"), "/api/v1/commerce/winga-orders")
        self.assertEqual(
            reverse("commerce:winga-service-bookings"),
            "/api/v1/commerce/winga-service-bookings",
        )
        self.assertEqual(reverse("commerce:winga-shops"), "/api/v1/commerce/winga-shops")
        self.assertEqual(reverse("commerce:gov-requests"), "/api/v1/commerce/gov-requests")
        self.assertEqual(
            reverse("commerce:health-appointments"),
            "/api/v1/commerce/health-appointments",
        )
        self.assertEqual(reverse("commerce:edu-payments"), "/api/v1/commerce/edu-payments")
        self.assertEqual(
            reverse("commerce:housing-inquiries"),
            "/api/v1/commerce/housing-inquiries",
        )
        self.assertEqual(
            reverse("commerce:wealth-contributions"),
            "/api/v1/commerce/wealth-contributions",
        )
        self.assertEqual(
            reverse("commerce:job-assignments"),
            "/api/v1/commerce/job-assignments",
        )
        self.assertEqual(
            reverse("commerce:insurance-policies"),
            "/api/v1/commerce/insurance-policies",
        )
        self.assertEqual(
            reverse("commerce:family-transfers"),
            "/api/v1/commerce/family-transfers",
        )
        self.assertEqual(
            reverse("commerce:huduma-bookings"),
            "/api/v1/commerce/huduma-bookings",
        )
        self.assertEqual(
            reverse("commerce:merchant-orders"),
            "/api/v1/commerce/merchant-orders",
        )
        self.assertEqual(
            reverse("commerce:driver-jobs"),
            "/api/v1/commerce/driver-jobs",
        )
        self.assertEqual(reverse("commerce:chat-threads"), "/api/v1/commerce/chat-threads")
        self.assertEqual(reverse("commerce:admin-cases"), "/api/v1/commerce/admin-cases")
