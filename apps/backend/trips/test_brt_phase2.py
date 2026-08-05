"""Taifa Mobility BRT — Phase 2 tests."""
from __future__ import annotations

from django.core.management import call_command
from django.utils import timezone
from rest_framework.test import APITestCase

from trips.national_models import PublicTransitRoute, TransitScheduledRun


class BrtPhase2ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        self.route = PublicTransitRoute.objects.get(code="dart-kimara-kivukoni")

        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p2-passenger", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-p2-passenger",
        )
        self.owner = reg["owner"]

        dreg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p2-driver", "platform": "test"},
            format="json",
        ).json()
        self.driver_owner = dreg["owner"]
        self.driver_token = dreg["token"]
        self._grant_driver(self.driver_owner)

    def _grant_driver(self, owner: str) -> None:
        from enterprise.models import PlatformPrincipal, PlatformRole

        role = PlatformRole.objects.get(code="transit-driver")
        principal, _ = PlatformPrincipal.objects.get_or_create(
            principal_id=owner,
            defaults={"display_name": "BRT Driver", "mfa_required": False},
        )
        principal.roles.add(role)

    def test_products_list(self):
        res = self.client.get("/api/v1/trips/transit/products")
        self.assertEqual(res.status_code, 200)
        codes = {p["code"] for p in res.data["products"]}
        self.assertIn("brt_single", codes)
        self.assertIn("brt_daily", codes)

    def test_home_includes_products(self):
        res = self.client.get("/api/v1/trips/transit/home", {"region": "Dar es Salaam"})
        self.assertEqual(res.status_code, 200)
        self.assertIn("products", res.data)
        self.assertGreaterEqual(len(res.data["products"]), 2)

    def test_plan_kimara_to_kivukoni(self):
        res = self.client.get(
            "/api/v1/trips/transit/plan",
            {
                "origin_stop": "kimara",
                "destination_stop": "kivukoni",
                "region": "Dar es Salaam",
            },
        )
        self.assertEqual(res.status_code, 200)
        self.assertGreaterEqual(len(res.data["plans"]), 1)
        direct = res.data["plans"][0]
        self.assertEqual(direct["kind"], "direct")
        self.assertEqual(direct["route_code"], "dart-kimara-kivukoni")

    def test_plan_invalid_same_stop(self):
        res = self.client.get(
            "/api/v1/trips/transit/plan",
            {"origin_stop": "kimara", "destination_stop": "kimara"},
        )
        self.assertEqual(res.status_code, 400)

    def test_purchase_daily_pass(self):
        res = self.client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {
                "route_id": str(self.route.id),
                "product_code": "brt_daily",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="brt-daily-pass-1",
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data["product_code"], "brt_daily")
        self.assertEqual(res.data["max_validations"], 10)

    def test_driver_runs_list_and_advance(self):
        run = TransitScheduledRun.objects.create(
            route=self.route,
            driver_owner=self.driver_owner,
            vehicle_label="DART-TEST",
            scheduled_at=timezone.now() + timezone.timedelta(hours=1),
            origin_stop="kimara",
            destination_stop="kivukoni",
            status=TransitScheduledRun.Status.SCHEDULED,
        )
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {self.driver_token}",
            HTTP_X_DEVICE_ID="brt-p2-driver",
        )
        listed = self.client.get("/api/v1/trips/transit/driver/runs")
        self.assertEqual(listed.status_code, 200)
        self.assertTrue(any(r["id"] == str(run.id) for r in listed.data["runs"]))

        boarding = self.client.patch(
            f"/api/v1/trips/transit/driver/runs/{run.id}",
            {"status": "boarding"},
            format="json",
        )
        self.assertEqual(boarding.status_code, 200)
        self.assertEqual(boarding.data["status"], "boarding")

        departed = self.client.patch(
            f"/api/v1/trips/transit/driver/runs/{run.id}",
            {"status": "departed"},
            format="json",
        )
        self.assertEqual(departed.status_code, 200)

        completed = self.client.patch(
            f"/api/v1/trips/transit/driver/runs/{run.id}",
            {"status": "completed"},
            format="json",
        )
        self.assertEqual(completed.status_code, 200)
        self.assertEqual(completed.data["status"], "completed")

    def test_driver_runs_denied_without_role(self):
        nogrant = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p2-no-driver", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {nogrant['token']}",
            HTTP_X_DEVICE_ID="brt-p2-no-driver",
        )
        res = self.client.get("/api/v1/trips/transit/driver/runs")
        self.assertEqual(res.status_code, 403)
