"""Governance scorecard tests."""
from django.test import TestCase, override_settings

from .scorecard import build_scorecard


class GovernanceScorecardTests(TestCase):
    def test_scorecard_shape_and_passing_core_checks(self):
        card = build_scorecard()
        self.assertEqual(card["model_version"], "governance-scorecard-v2")
        self.assertIn("score_e4", card)
        self.assertGreaterEqual(card["checks_passed"], 10)
        self.assertGreaterEqual(card["score_e4"], 7000)
        self.assertTrue(any(b["code"] == "ARB" for b in card["boards"]))
        self.assertIn("architecture", card["dimensions"])
