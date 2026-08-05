"""Taifa Mobility — mode expansion (daladala / multi-modal) tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APIClient, APITestCase

from trips.national_models import PublicTransitRoute, TransportTicket


class BrtModeExpansionApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        reg = APIClient().post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-mode-passenger", "platform": "test"},
            format="json",
        ).json()
        self.client = APIClient()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-mode-passenger",
        )
        self.brt_route = PublicTransitRoute.objects.get(code="dart-kimara-kivukoni")
        self.dala_route = PublicTransitRoute.objects.filter(metadata__mode="daladala").first()

    def test_modes_catalog_lists_brt_and_daladala(self):
        res = self.client.get("/api/v1/trips/transit/modes")
        self.assertEqual(res.status_code, 200)
        ids = {row["id"] for row in res.data["modes"]}
        self.assertIn("brt", ids)
        self.assertIn("daladala", ids)
        dala = next(row for row in res.data["modes"] if row["id"] == "daladala")
        self.assertGreaterEqual(dala["routes"], 2)

    def test_list_daladala_routes(self):
        res = self.client.get("/api/v1/trips/transit/routes?mode=daladala")
        self.assertEqual(res.status_code, 200)
        self.assertGreaterEqual(len(res.data["routes"]), 2)
        self.assertTrue(all(r["metadata"]["mode"] == "daladala" for r in res.data["routes"]))

    def test_home_filtered_by_daladala_mode(self):
        res = self.client.get("/api/v1/trips/transit/home?mode=daladala")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["mode"], "daladala")
        self.assertTrue(all(r["metadata"]["mode"] == "daladala" for r in res.data["featured_routes"]))

    def test_purchase_daladala_ticket(self):
        res = self.client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {
                "route_id": str(self.dala_route.id),
                "product_code": "dala_single",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="mode-dala-ticket",
        )
        self.assertEqual(res.status_code, 201)
        ticket = TransportTicket.objects.get(pk=res.data["id"])
        self.assertTrue(ticket.media_code.startswith("DALA-"))

    def test_reject_brt_product_on_daladala_route(self):
        res = self.client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {
                "route_id": str(self.dala_route.id),
                "product_code": "brt_single",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="mode-mismatch",
        )
        self.assertEqual(res.status_code, 400)

    def test_multimodal_plan_sinza_to_kivukoni(self):
        res = self.client.get(
            "/api/v1/trips/transit/plan",
            {"origin_stop": "sinza", "destination_stop": "kivukoni", "region": "Dar es Salaam"},
        )
        self.assertEqual(res.status_code, 200)
        kinds = {p["kind"] for p in res.data["plans"]}
        self.assertIn("transfer", kinds)
