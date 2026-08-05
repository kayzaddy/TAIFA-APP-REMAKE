"""Taifa Mobility BRT — Phase 5 control center, analytics, NFC, admin tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APIClient, APITestCase

from enterprise.models import PlatformPrincipal, PlatformRole
from trips.national_models import PublicTransitRoute, TransitTicketProduct, TransportTicket
from trips.transit_services import validate_transit_ticket


class BrtPhase5ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        self.ops_client = APIClient()
        self.passenger_client = APIClient()
        self.validator_client = APIClient()

        reg = self.ops_client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p5-ops", "platform": "test"},
            format="json",
        ).json()
        self.owner = reg["owner"]
        self.ops_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-p5-ops",
        )
        self._grant_ops(self.owner)
        self.route = PublicTransitRoute.objects.get(code="dart-kimara-kivukoni")

        preg = self.passenger_client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p5-passenger", "platform": "test"},
            format="json",
        ).json()
        self.passenger_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {preg['token']}",
            HTTP_X_DEVICE_ID="brt-p5-passenger",
        )
        self.passenger_owner = preg["owner"]

        vreg = self.validator_client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p5-validator", "platform": "test"},
            format="json",
        ).json()
        self.validator_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {vreg['token']}",
            HTTP_X_DEVICE_ID="brt-p5-validator",
        )
        self._grant_validator(vreg["owner"])

    def _grant_ops(self, owner: str) -> None:
        role, _ = PlatformRole.objects.get_or_create(
            code="mobility-ops-p5",
            defaults={"name": "Mobility Ops", "permissions": ["mobility.operations"]},
        )
        principal, _ = PlatformPrincipal.objects.get_or_create(
            principal_id=owner,
            defaults={"display_name": "Ops", "mfa_required": False},
        )
        principal.roles.add(role)

    def _grant_validator(self, owner: str) -> None:
        role = PlatformRole.objects.get(code="transit-validator")
        principal, _ = PlatformPrincipal.objects.get_or_create(
            principal_id=owner,
            defaults={"display_name": "Validator", "mfa_required": False},
        )
        principal.roles.add(role)

    def test_transit_analytics_requires_ops(self):
        denied = self.passenger_client.get("/api/v1/trips/transit/analytics")
        self.assertEqual(denied.status_code, 403)
        allowed = self.ops_client.get(
            "/api/v1/trips/transit/analytics",
            {"region": "Dar es Salaam", "days": 7},
        )
        self.assertEqual(allowed.status_code, 200)
        self.assertIn("daily", allowed.data)
        self.assertIn("ops", allowed.data)

    def test_city_ops_includes_transit_kpis(self):
        res = self.ops_client.get(
            "/api/v1/trips/city/operations",
            {"region": "Dar es Salaam"},
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("transit", res.data["kpis"])
        self.assertIn("tickets_issued_today", res.data["kpis"]["transit"])

    def test_national_command_center_includes_transit(self):
        res = self.ops_client.get("/api/v1/trips/national/command-center")
        self.assertEqual(res.status_code, 200)
        self.assertIn("transit", res.data["national"])

    def test_admin_route_patch(self):
        res = self.ops_client.patch(
            f"/api/v1/trips/transit/admin/routes/{self.route.id}",
            {"name": "Kimara — Kivukoni (Updated)", "active": True},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.route.refresh_from_db()
        self.assertIn("Updated", self.route.name)

    def test_admin_product_create(self):
        res = self.ops_client.post(
            "/api/v1/trips/transit/admin/products",
            {
                "code": "brt_weekly",
                "name": "BRT Weekly Pass",
                "fare_minor": 12_000_00,
                "ticket_type": "weekly",
                "validity_hours": 168,
                "max_validations": 20,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(TransitTicketProduct.objects.filter(code="brt_weekly").exists())

    def test_nfc_validate_path(self):
        self.passenger_client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {"route_id": str(self.route.id), "product_code": "brt_single"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="p5-nfc-ticket",
        )
        ticket = TransportTicket.objects.filter(owner=self.passenger_owner).latest("created_at")
        ticket.ticket_type = "nfc"
        ticket.token_hash = __import__("hashlib").sha256(ticket.media_code.encode()).hexdigest()
        ticket.save(update_fields=["ticket_type", "token_hash"])

        self.validator_client.post(
            "/api/v1/trips/transit/tickets/validate",
            {"media_code": ticket.media_code, "media_type": "nfc"},
            format="json",
        )
        ticket.refresh_from_db()
        self.assertEqual(ticket.validation_count, 1)

    def test_nfc_validate_via_service(self):
        self.passenger_client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {"route_id": str(self.route.id), "product_code": "brt_single"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="p5-nfc-service",
        )
        ticket = TransportTicket.objects.filter(owner=self.passenger_owner).latest("created_at")
        ticket.ticket_type = "nfc"
        ticket.token_hash = __import__("hashlib").sha256(ticket.media_code.encode()).hexdigest()
        ticket.save(update_fields=["ticket_type", "token_hash"])
        updated = validate_transit_ticket(
            media_code=ticket.media_code,
            actor="validator",
            media_type="nfc",
        )
        self.assertEqual(updated.validation_count, 1)
