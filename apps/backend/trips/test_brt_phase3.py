"""Taifa Mobility BRT — Phase 3 AVL / live map tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APITestCase

from trips.national_models import PublicTransitRoute, TransitAvlVehicle


class BrtPhase3ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        self.route = PublicTransitRoute.objects.get(code="dart-kimara-kivukoni")
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p3-passenger", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-p3-passenger",
        )

        dreg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p3-driver", "platform": "test"},
            format="json",
        ).json()
        self.driver_token = dreg["token"]
        self._grant_driver(dreg["owner"])

    def _grant_driver(self, owner: str) -> None:
        from enterprise.models import PlatformPrincipal, PlatformRole

        role = PlatformRole.objects.get(code="transit-driver")
        principal, _ = PlatformPrincipal.objects.get_or_create(
            principal_id=owner,
            defaults={"display_name": "BRT Driver", "mfa_required": False},
        )
        principal.roles.add(role)

    def test_live_map_snapshot(self):
        res = self.client.get(
            "/api/v1/trips/transit/map",
            {"region": "Dar es Salaam"},
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("routes", res.data)
        self.assertIn("stations", res.data)
        self.assertGreaterEqual(len(res.data["vehicles"]), 3)
        self.assertTrue(any(v["vehicle_label"] == "DART-201" for v in res.data["vehicles"]))

    def test_live_map_route_filter(self):
        res = self.client.get(
            "/api/v1/trips/transit/map",
            {"route_id": str(self.route.id)},
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data["routes"]), 1)
        self.assertEqual(res.data["routes"][0]["code"], "dart-kimara-kivukoni")
        polyline = res.data["routes"][0]["polyline"]
        self.assertGreaterEqual(len(polyline), 6)

    def test_driver_avl_ping_updates_vehicle(self):
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {self.driver_token}",
            HTTP_X_DEVICE_ID="brt-p3-driver",
        )
        res = self.client.post(
            "/api/v1/trips/transit/avl/ping",
            {
                "vehicle_label": "DART-201",
                "route_id": str(self.route.id),
                "latitude": -6.7500,
                "longitude": 39.2100,
                "speed_kmh": 40,
                "next_stop_code": "ubungo",
                "eta_next_stop_seconds": 120,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 200, res.data)
        self.assertEqual(res.data["vehicle_label"], "DART-201")
        vehicle = TransitAvlVehicle.objects.get(vehicle_label="DART-201")
        self.assertAlmostEqual(float(vehicle.latitude), -6.7500, places=3)

    def test_avl_ping_denied_without_driver_role(self):
        res = self.client.post(
            "/api/v1/trips/transit/avl/ping",
            {
                "vehicle_label": "DART-201",
                "route_id": str(self.route.id),
                "latitude": -6.75,
                "longitude": 39.21,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 403)
