"""Taifa Mobility BRT — Phase 7 family / guardian tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APIClient, APITestCase

from trips.national_models import PublicTransitRoute, TransitFamilyMember, TransportTicket


class BrtPhase7ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        self.route = PublicTransitRoute.objects.get(code="dart-kimara-kivukoni")

        guard = APIClient().post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p7-guardian", "platform": "test"},
            format="json",
        ).json()
        self.guardian_client = APIClient()
        self.guardian_owner = guard["owner"]
        self.guardian_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {guard['token']}",
            HTTP_X_DEVICE_ID="brt-p7-guardian",
        )

        child = APIClient().post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p7-child", "platform": "test"},
            format="json",
        ).json()
        self.child_client = APIClient()
        self.child_owner = child["owner"]
        self.child_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {child['token']}",
            HTTP_X_DEVICE_ID="brt-p7-child",
        )

    def test_add_family_member(self):
        res = self.guardian_client.post(
            "/api/v1/trips/transit/family/members",
            {
                "member_owner": self.child_owner,
                "display_name": "Asha",
                "relationship": "child",
                "monthly_limit_minor": 50_000_00,
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(
            TransitFamilyMember.objects.filter(
                guardian_owner=self.guardian_owner,
                member_owner=self.child_owner,
            ).exists()
        )

    def test_family_bundle_lists_members(self):
        self.test_add_family_member()
        res = self.guardian_client.get("/api/v1/trips/transit/family")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(len(res.data["members"]), 1)
        self.assertEqual(res.data["members"][0]["display_name"], "Asha")

    def test_guardian_purchase_for_child(self):
        self.test_add_family_member()
        res = self.guardian_client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {
                "route_id": str(self.route.id),
                "product_code": "brt_single",
                "beneficiary_owner": self.child_owner,
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="p7-family-ticket",
        )
        self.assertEqual(res.status_code, 201)
        ticket = TransportTicket.objects.get(pk=res.data["id"])
        self.assertEqual(ticket.owner, self.child_owner)
        self.assertEqual(ticket.metadata.get("guardian_owner"), self.guardian_owner)

    def test_reject_purchase_for_unlinked_member(self):
        res = self.guardian_client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {
                "route_id": str(self.route.id),
                "product_code": "brt_single",
                "beneficiary_owner": self.child_owner,
            },
            format="json",
            HTTP_IDEMPOTENCY_KEY="p7-family-denied",
        )
        self.assertEqual(res.status_code, 400)

    def test_remove_family_member(self):
        self.test_add_family_member()
        member = TransitFamilyMember.objects.get(
            guardian_owner=self.guardian_owner,
            member_owner=self.child_owner,
        )
        res = self.guardian_client.delete(f"/api/v1/trips/transit/family/members/{member.id}")
        self.assertEqual(res.status_code, 204)
        member.refresh_from_db()
        self.assertEqual(member.status, TransitFamilyMember.Status.REMOVED)
