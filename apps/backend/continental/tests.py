"""Pan-African continental platform tests."""
from __future__ import annotations

from django.test import TestCase

from payments.money import Currency

from .adapters import resolve_identity_adapter
from .compliance import evaluate_transaction_limits
from .fx import convert_minor, get_rate_e8
from .models import CountryProfile, CrossBorderCorridor, LanguagePack
from .services import (
    continental_blueprint,
    global_ops_center,
    localize,
    quote_cross_border,
    seed_continental,
)


class ContinentalSeedTests(TestCase):
    def test_seed_eight_countries(self):
        result = seed_continental()
        self.assertEqual(result["countries"], 8)
        self.assertTrue(CountryProfile.objects.filter(code="TZ", status="active").exists())
        self.assertTrue(CountryProfile.objects.filter(code="KE").exists())
        self.assertTrue(CountryProfile.objects.filter(code="CD").exists())
        self.assertGreaterEqual(CrossBorderCorridor.objects.filter(active=True).count(), 5)
        blueprint = continental_blueprint()
        self.assertEqual(blueprint["model_version"], "continental-blueprint-v1")
        self.assertIn("TZS", blueprint["currencies"])
        self.assertIn("KES", blueprint["currencies"])


class FxAndCrossBorderTests(TestCase):
    def setUp(self):
        seed_continental()

    def test_currency_enum_covers_region(self):
        for code in ("TZS", "KES", "UGX", "RWF", "BIF", "ZMW", "MWK", "CDF", "USD", "EUR"):
            self.assertEqual(Currency.from_code(code).code, code)

    def test_fx_usd_to_tzs(self):
        rate = get_rate_e8(base="USD", quote="TZS")
        self.assertGreater(rate, 100_000_000)
        converted, used = convert_minor(
            amount_minor=100, from_currency="USD", to_currency="TZS"
        )
        self.assertEqual(used, rate)
        self.assertGreater(converted, 100)

    def test_cross_border_quote(self):
        intent = quote_cross_border(
            corridor_code="tz-ke-wallet",
            owner="user-1",
            amount_minor=100_000_00,
        )
        self.assertEqual(intent.status, "quoted")
        self.assertEqual(intent.currency, "TZS")
        self.assertEqual(intent.converted_currency, "KES")
        self.assertGreater(intent.converted_minor, 0)
        self.assertGreater(intent.fee_minor, 0)
        self.assertIn("payment_note", intent.metadata)


class ComplianceIdentityI18nTests(TestCase):
    def setUp(self):
        seed_continental()

    def test_aml_threshold_flags(self):
        result = evaluate_transaction_limits(
            country_code="TZ",
            amount_minor=900_000_00,
            currency="TZS",
            daily_total_minor=200_000_00,
        )
        self.assertTrue(result["requires_review"])
        self.assertTrue(any(f["code"] == "aml_daily_threshold" for f in result["flags"]))

    def test_identity_stub(self):
        adapter = resolve_identity_adapter("TZ", "nida")
        out = adapter.lookup(identifier="19800101123456789012")
        self.assertTrue(out.matched)
        self.assertIn("NIDA", out.reference.upper() or out.provider.upper() or "NIDA")

    def test_swahili_pack(self):
        self.assertTrue(LanguagePack.objects.filter(locale="sw").exists())
        self.assertEqual(localize(locale="sw", key="wallet.title"), "Pochi")
        self.assertTrue(LanguagePack.objects.get(locale="ar").rtl)

    def test_ops_center(self):
        cc = global_ops_center()
        self.assertEqual(cc["model_version"], "continental-ops-center-v1")
        self.assertEqual(cc["active_countries"], 1)
        self.assertGreaterEqual(cc["pilot_countries"], 2)
