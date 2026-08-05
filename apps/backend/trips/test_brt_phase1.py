"""Taifa Mobility BRT — Phase 1 tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APITestCase

from trips.national_models import PublicTransitRoute, TransportTicket
from trips.transit_services import validate_transit_ticket


class BrtPhase1ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-passenger-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-passenger-1",
        )
        self.owner = reg["owner"]
        self.route = PublicTransitRoute.objects.get(code="dart-kimara-kivukoni")

        vreg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-validator-1", "platform": "test"},
            format="json",
        ).json()
        self.validator_owner = vreg["owner"]
        self._grant_validator(self.validator_owner)

    def _grant_validator(self, owner: str) -> None:
        from enterprise.models import PlatformPrincipal, PlatformRole

        role = PlatformRole.objects.get(code="transit-validator")
        principal, _ = PlatformPrincipal.objects.get_or_create(
            principal_id=owner,
            defaults={"display_name": "Transit Validator", "mfa_required": False},
        )
        principal.roles.add(role)

    def test_seed_idempotent(self):
        call_command("seed_mobility_brt")
        self.assertTrue(PublicTransitRoute.objects.filter(code="dart-kimara-kivukoni").exists())
        self.assertGreaterEqual(PublicTransitRoute.objects.filter(metadata__mode="daladala").count(), 2)

    def test_transit_home_bundle(self):
        res = self.client.get(
            "/api/v1/trips/transit/home",
            {"lat": "-6.7912", "lng": "39.2089", "region": "Dar es Salaam"},
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("nearby_stations", res.data)
        self.assertIn("featured_routes", res.data)
        self.assertTrue(len(res.data["featured_routes"]) >= 1)

    def test_list_brt_routes(self):
        res = self.client.get(
            "/api/v1/trips/transit/routes",
            {"region": "Dar es Salaam", "mode": "brt"},
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(any(r["code"] == "dart-kimara-kivukoni" for r in res.data["routes"]))

    def test_route_detail_includes_departures(self):
        res = self.client.get(f"/api/v1/trips/transit/routes/{self.route.id}")
        self.assertEqual(res.status_code, 200)
        self.assertIn("departures", res.data)
        self.assertEqual(res.data["metadata"]["brand"], "Mwendokasi")

    def test_search_kariakoo(self):
        res = self.client.get("/api/v1/trips/transit/search", {"q": "Kariakoo"})
        self.assertEqual(res.status_code, 200)
        self.assertTrue(res.data["routes"] or res.data["stops"])

    def test_nearby_stations(self):
        res = self.client.get(
            "/api/v1/trips/transit/stations/nearby",
            {"lat": "-6.7912", "lng": "39.2089"},
        )
        self.assertEqual(res.status_code, 200)
        self.assertTrue(len(res.data["stations"]) >= 1)

    def test_station_detail(self):
        res = self.client.get("/api/v1/trips/transit/stations/ubungo")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["stop_code"], "ubungo")
        self.assertIn("upcoming", res.data)

    def test_purchase_ticket_with_wallet(self):
        res = self.client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {
                "route_id": str(self.route.id),
                "product_code": "brt_single",
                "origin_stop": "kimara",
                "destination_stop": "kivukoni",
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="brt-ticket-1",
        )
        self.assertEqual(res.status_code, 201, res.data)
        self.assertIn("qr", res.data)
        self.assertTrue(res.data["payment_ref"])
        self.assertEqual(res.data["product_code"], "brt_single")

    def test_purchase_idempotent(self):
        self.test_purchase_ticket_with_wallet()
        res = self.client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {"route_id": str(self.route.id), "product_code": "brt_single"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="brt-ticket-1",
        )
        self.assertEqual(res.status_code, 201)
        self.assertEqual(TransportTicket.objects.filter(owner=self.owner).count(), 1)

    def test_my_tickets(self):
        self.test_purchase_ticket_with_wallet()
        res = self.client.get("/api/v1/trips/transit/tickets/mine")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data["tickets"]), 1)

    def test_validate_ticket_success_and_replay(self):
        self.test_purchase_ticket_with_wallet()
        ticket = TransportTicket.objects.filter(owner=self.owner).first()
        self.client.credentials()  # clear passenger
        vreg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-validator-2", "platform": "test"},
            format="json",
        ).json()
        self._grant_validator(vreg["owner"])
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {vreg['token']}",
            HTTP_X_DEVICE_ID="brt-validator-2",
        )
        ok = self.client.post(
            "/api/v1/trips/transit/tickets/validate",
            {"media_code": ticket.media_code, "qr": ticket.media_payload},
            format="json",
        )
        self.assertEqual(ok.status_code, 200)
        self.assertTrue(ok.data["valid"])
        replay = self.client.post(
            "/api/v1/trips/transit/tickets/validate",
            {"media_code": ticket.media_code, "qr": ticket.media_payload},
            format="json",
        )
        self.assertEqual(replay.status_code, 400)

    def test_validate_denied_without_role(self):
        self.test_purchase_ticket_with_wallet()
        ticket = TransportTicket.objects.filter(owner=self.owner).first()
        nogrant = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-no-role", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {nogrant['token']}",
            HTTP_X_DEVICE_ID="brt-no-role",
        )
        res = self.client.post(
            "/api/v1/trips/transit/tickets/validate",
            {"media_code": ticket.media_code},
            format="json",
        )
        self.assertEqual(res.status_code, 403)

    def test_service_validate_marks_used(self):
        from trips.transit_services import purchase_transit_ticket

        ticket = purchase_transit_ticket(
            owner=self.owner,
            actor=self.owner,
            route_id=self.route.id,
            product_code="brt_single",
            idempotency_key="svc-ticket-1",
        )
        validate_transit_ticket(
            media_code=ticket.media_code,
            actor="validator-svc",
            qr_payload=ticket.media_payload,
        )
        ticket.refresh_from_db()
        self.assertEqual(ticket.status, "used")
