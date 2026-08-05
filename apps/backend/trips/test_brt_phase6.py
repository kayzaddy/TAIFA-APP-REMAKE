"""Taifa Mobility BRT — Phase 6 AI travel assistant tests."""
from __future__ import annotations

from django.core.management import call_command
from rest_framework.test import APITestCase

from trips.transit_services import transit_ai_assistant


class BrtPhase6ApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-p6-passenger", "platform": "test"},
            format="json",
        ).json()
        self.owner = reg["owner"]
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-p6-passenger",
        )

    def test_assistant_swahili_journey(self):
        res = self.client.post(
            "/api/v1/trips/transit/assistant",
            {"query": "kutoka kimara hadi kivukoni", "locale": "sw"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["intent"], "plan_journey")
        self.assertEqual(res.data["origin_stop"], "kimara")
        self.assertEqual(res.data["destination_stop"], "kivukoni")
        self.assertTrue(res.data["plans"])
        self.assertIn("reply", res.data)

    def test_assistant_english_journey_get(self):
        res = self.client.get(
            "/api/v1/trips/transit/assistant",
            {"q": "from ubungo to kariakoo", "locale": "en"},
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["intent"], "plan_journey")
        self.assertTrue(res.data["plans"])

    def test_assistant_search_intent(self):
        res = self.client.post(
            "/api/v1/trips/transit/assistant",
            {"query": "search station ubungo", "locale": "en"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["intent"], "search")
        self.assertTrue(res.data["search"]["stops"] or res.data["search"]["routes"])

    def test_assistant_requires_query(self):
        res = self.client.post("/api/v1/trips/transit/assistant", {}, format="json")
        self.assertEqual(res.status_code, 400)

    def test_assistant_service_profile_defaults(self):
        self.client.patch(
            "/api/v1/trips/transit/profile",
            {"home_stop": "kimara", "work_stop": "kivukoni"},
            format="json",
        )
        result = transit_ai_assistant(
            owner=self.owner,
            query="nataka kwenda kazini",
            locale="sw",
            region="Dar es Salaam",
        )
        self.assertEqual(result["origin_stop"], "kimara")
        self.assertEqual(result["destination_stop"], "kivukoni")
        self.assertTrue(result["suggested_actions"])
