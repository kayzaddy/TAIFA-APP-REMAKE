"""Taifa Mobility BRT — Phase 8 lost & found tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APIClient, APITestCase

from trips.national_models import TransitLostFoundItem, TransitNotification


class BrtPhase8ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")

        reporter = APIClient().post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p8-reporter", "platform": "test"},
            format="json",
        ).json()
        self.reporter_client = APIClient()
        self.reporter_owner = reporter["owner"]
        self.reporter_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reporter['token']}",
            HTTP_X_DEVICE_ID="brt-p8-reporter",
        )

        claimant = APIClient().post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p8-claimant", "platform": "test"},
            format="json",
        ).json()
        self.claimant_client = APIClient()
        self.claimant_owner = claimant["owner"]
        self.claimant_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {claimant['token']}",
            HTTP_X_DEVICE_ID="brt-p8-claimant",
        )

    def test_report_lost_item(self):
        res = self.reporter_client.post(
            "/api/v1/trips/transit/lost-found",
            {
                "kind": "lost",
                "category": "phone",
                "title": "Samsung phone",
                "description": "Black case, cracked screen",
                "stop_code": "ubungo",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.data["kind"], "lost")
        self.assertTrue(
            TransitLostFoundItem.objects.filter(
                reporter_owner=self.reporter_owner,
                title="Samsung phone",
            ).exists()
        )

    def test_report_found_item_and_browse(self):
        res = self.reporter_client.post(
            "/api/v1/trips/transit/lost-found",
            {
                "kind": "found",
                "category": "wallet",
                "title": "Brown leather wallet",
                "stop_code": "kimara",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        bundle = self.claimant_client.get(
            "/api/v1/trips/transit/lost-found?kind=found&stop_code=kimara"
        )
        self.assertEqual(bundle.status_code, 200)
        self.assertEqual(len(bundle.data["open_items"]), 1)
        self.assertEqual(bundle.data["open_items"][0]["title"], "Brown leather wallet")

    def test_claim_found_item(self):
        found = self.reporter_client.post(
            "/api/v1/trips/transit/lost-found",
            {
                "kind": "found",
                "category": "bag",
                "title": "Blue school bag",
                "stop_code": "ubungo",
            },
            format="json",
        ).data
        res = self.claimant_client.post(
            f"/api/v1/trips/transit/lost-found/{found['id']}/claim",
            {"message": "My daughter's bag"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["status"], "claimed")
        item = TransitLostFoundItem.objects.get(pk=found["id"])
        self.assertEqual(item.claimant_owner, self.claimant_owner)
        self.assertTrue(
            TransitNotification.objects.filter(
                owner=self.reporter_owner,
                event_type="transit.lost_found.claimed",
            ).exists()
        )

    def test_reject_claim_on_own_report(self):
        found = self.reporter_client.post(
            "/api/v1/trips/transit/lost-found",
            {
                "kind": "found",
                "title": "Umbrella",
                "stop_code": "posta",
            },
            format="json",
        ).data
        res = self.reporter_client.post(
            f"/api/v1/trips/transit/lost-found/{found['id']}/claim",
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_resolve_claimed_item(self):
        found = self.reporter_client.post(
            "/api/v1/trips/transit/lost-found",
            {
                "kind": "found",
                "title": "ID card",
                "stop_code": "kariakoo",
            },
            format="json",
        ).data
        self.claimant_client.post(
            f"/api/v1/trips/transit/lost-found/{found['id']}/claim",
            format="json",
        )
        res = self.reporter_client.post(
            f"/api/v1/trips/transit/lost-found/{found['id']}/resolve",
            {"status": "matched"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["status"], "matched")
        item = TransitLostFoundItem.objects.get(pk=found["id"])
        self.assertIsNotNone(item.resolved_at)
