"""Taifa Mobility BRT — Phase 4 passenger engagement tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APITestCase

from trips.national_models import PublicTransitRoute, TransitNotification
from trips.models import SafetyIncident


class BrtPhase4ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        self.route = PublicTransitRoute.objects.get(code="dart-kimara-kivukoni")
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p4-passenger", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-p4-passenger",
        )
        self.owner = reg["owner"]

    def test_profile_bundle(self):
        res = self.client.get("/api/v1/trips/transit/profile")
        self.assertEqual(res.status_code, 200)
        self.assertIn("profile", res.data)
        self.assertIn("stats", res.data)

    def test_update_profile_accessibility(self):
        res = self.client.patch(
            "/api/v1/trips/transit/profile",
            {
                "home_stop": "kimara",
                "work_stop": "kivukoni",
                "accessibility": {"wheelchair": True, "large_text": True},
            },
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["profile"]["home_stop"], "kimara")
        self.assertTrue(res.data["profile"]["accessibility"]["wheelchair"])

    def test_favorites_crud(self):
        created = self.client.post(
            "/api/v1/trips/transit/favorites",
            {"subject_type": "station", "subject_code": "ubungo", "label": "Ubungo"},
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        fav_id = created.data["id"]
        listed = self.client.get("/api/v1/trips/transit/favorites")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(len(listed.data["favorites"]), 1)
        deleted = self.client.delete(f"/api/v1/trips/transit/favorites/{fav_id}")
        self.assertEqual(deleted.status_code, 204)

    def test_ticket_purchase_emits_notification(self):
        res = self.client.post(
            "/api/v1/trips/transit/tickets/purchase",
            {"route_id": str(self.route.id), "product_code": "brt_single"},
            format="json",
            HTTP_IDEMPOTENCY_KEY="p4-notify-ticket",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(
            TransitNotification.objects.filter(
                owner=self.owner, event_type="transit.ticket.purchased"
            ).exists()
        )
        notes = self.client.get("/api/v1/trips/transit/notifications")
        self.assertGreaterEqual(len(notes.data["notifications"]), 1)

    def test_mark_notifications_read(self):
        self.test_ticket_purchase_emits_notification()
        res = self.client.post("/api/v1/trips/transit/notifications", {}, format="json")
        self.assertEqual(res.status_code, 200)
        self.assertGreaterEqual(res.data["marked_read"], 1)

    def test_submit_feedback(self):
        res = self.client.post(
            "/api/v1/trips/transit/feedback",
            {
                "rating": 5,
                "comment": "Fast and clean buses",
                "route_id": str(self.route.id),
                "tags": ["clean", "on_time"],
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["sentiment"], "positive")
        listed = self.client.get("/api/v1/trips/transit/feedback")
        self.assertEqual(len(listed.data["feedback"]), 1)

    def test_transit_sos(self):
        res = self.client.post(
            "/api/v1/trips/transit/safety/sos",
            {
                "latitude": -6.7912,
                "longitude": 39.2089,
                "stop_code": "ubungo",
                "route_id": str(self.route.id),
                "notes": "Need help at platform",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertTrue(SafetyIncident.objects.filter(reporter_principal=self.owner).exists())
