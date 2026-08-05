"""Seed Hotels field-pilot roster — Dar CBD · 10 hotels · 20 Wingas.

Scaffolding only. Field KYC/KYB/onboarding completion is tracked in
docs/winga_pilot/field/ — never treat seed counts as completed field bookings.

Does not add platform modules. Uses existing Winga models only.
"""
from __future__ import annotations

from django.core.management import call_command
from django.core.management.base import BaseCommand

from winga.models import (
    BrokerageDomain,
    CommissionKind,
    CommissionRule,
    Offering,
    OfferingKind,
    ProviderProfile,
    VerificationStatus,
    WingaKind,
    WingaProfile,
)

PILOT = "hotels-v1"
CITY = "Dar es Salaam"

# Harbour View + surrounding business-district hotels (recruitment roster).
HOTELS = [
    ("harbour-view", "Harbour View Hotels Ltd", "Harbour View", 8200, True),
    ("sea-breeze", "Sea Breeze Inn Ltd", "Sea Breeze Inn", 6100, False),
    ("kivukoni-lodge", "Kivukoni Lodge Co", "Kivukoni Lodge", 6400, False),
    ("city-crown", "City Crown Hotel Ltd", "City Crown", 7000, False),
    ("palm-court", "Palm Court Suites Ltd", "Palm Court", 6800, False),
    ("harbour-annex", "Harbour Annex Residences", "Harbour Annex", 5900, False),
    ("masaki-gateway", "Masaki Gateway Hotel", "Masaki Gateway", 7200, False),
    ("posta-plaza", "Posta Plaza Hotel Ltd", "Posta Plaza", 6600, False),
    ("azikiwe-suites", "Azikiwe Suites Ltd", "Azikiwe Suites", 6300, False),
    ("waterfront-stay", "Waterfront Stay Ltd", "Waterfront Stay", 7500, False),
]

WINGAS = [
    ("Asha M.", "Dar corporate stays"),
    ("Juma K.", "Airport & transit stays"),
    ("Neema R.", "Wedding & events blocks"),
    ("Baraka T.", "NGO & conference bookings"),
    ("Fatma S.", "Zanzibar overflow referrals"),
    ("Ibrahim H.", "Government travel desks"),
    ("Grace L.", "Tour operator partner"),
    ("Daniel O.", "Bank staff lodging"),
    ("Halima N.", "Family weekend packages"),
    ("Peter W.", "Medical tourism stays"),
    ("Sarah B.", "Embassy travel"),
    ("Kevin M.", "Sports teams lodging"),
    ("Rehema A.", "University visitor stays"),
    ("Oscar N.", "Construction crew lodging"),
    ("Lillian D.", "Wedding guest blocks"),
    ("Hassan J.", "Religious conference stays"),
    ("Mercy K.", "Diaspora homecoming stays"),
    ("Tom P.", "Film & production crews"),
    ("Amina Z.", "Startup / tech visitors"),
    ("Joseph C.", "Insurance adjuster travel"),
]


class Command(BaseCommand):
    help = "Seed Hotels field-pilot roster: 10 hotels, 20 Wingas (idempotent)"

    def add_arguments(self, parser):
        parser.add_argument(
            "--with-domains",
            action="store_true",
            help="Also run seed_winga first",
        )

    def handle(self, *args, **options):
        if options["with_domains"]:
            call_command("seed_winga")

        hotels_domain = BrokerageDomain.objects.filter(code="hotels").first()
        if hotels_domain is None:
            raise SystemExit("Domain 'hotels' missing — run: python manage.py seed_winga")

        for slug, legal, trading, rep, field_anchor in HOTELS:
            principal = f"pilot:hotel-{slug}"
            # Keep legacy principal for Harbour View so existing training data stays linked.
            if slug == "harbour-view":
                principal = "pilot:harbour-view"
            provider, _ = ProviderProfile.objects.update_or_create(
                principal=principal,
                defaults={
                    "legal_name": legal,
                    "trading_name": trading,
                    # Platform profile ready for training; field_verified tracks real KYB.
                    "verification_status": VerificationStatus.VERIFIED
                    if field_anchor
                    else VerificationStatus.PENDING,
                    "kyb_ref": f"KYB-PILOT-{slug.upper()}" if field_anchor else "",
                    "locations": [
                        {
                            "city": CITY,
                            "country": "TZ",
                            "area": "Harbour View / CBD",
                        }
                    ],
                    "reputation_score_e4": rep,
                    "metadata": {
                        "pilot": PILOT,
                        "vertical": "hotels",
                        "city": CITY,
                        "area": "harbour-view-cbd",
                        "field_verified": field_anchor,
                        "onboarding_complete": field_anchor,
                        "roster": "scaffold",
                    },
                    "active": True,
                },
            )
            provider.domains.add(hotels_domain)

            # Anchor hotel gets sellable offerings; others wait for field inventory.
            if field_anchor:
                for title, price, attrs in [
                    ("King Harbour View · 2 nights", 450_000_00, {"nights": 2, "room": "king"}),
                    ("Executive Suite · weekend", 780_000_00, {"nights": 2, "room": "suite"}),
                    ("Conference package · 20 pax", 1_200_000_00, {"pax": 20, "kind": "meeting"}),
                ]:
                    Offering.objects.update_or_create(
                        provider=provider,
                        domain=hotels_domain,
                        title=title,
                        defaults={
                            "kind": OfferingKind.SERVICE,
                            "description": f"Hotels pilot offering — {title}",
                            "currency": "TZS",
                            "price_minor": price,
                            "attributes": {**attrs, "pilot": PILOT},
                            "locations": [{"city": CITY, "area": "Harbour View"}],
                            "active": True,
                        },
                    )
                CommissionRule.objects.update_or_create(
                    code="hotels-pilot-peak",
                    defaults={
                        "name": "Hotels pilot peak (12%)",
                        "kind": CommissionKind.PERCENTAGE,
                        "domain": hotels_domain,
                        "provider": provider,
                        "bps": 1200,
                        "priority": 100,
                        "campaign_code": PILOT,
                        "active": True,
                    },
                )

        created_w = 0
        for i, (name, bio) in enumerate(WINGAS, start=1):
            principal = f"pilot:winga-hotels-{i:02d}"
            # First 5 marked ready for training dry-runs; rest pending field KYC.
            field_ready = i <= 5
            w, was = WingaProfile.objects.update_or_create(
                principal=principal,
                defaults={
                    "kind": WingaKind.INDIVIDUAL,
                    "display_name": name,
                    "bio": bio,
                    "verification_status": VerificationStatus.VERIFIED
                    if field_ready
                    else VerificationStatus.PENDING,
                    "kyc_ref": f"KYC-PILOT-W-{i:02d}" if field_ready else "",
                    "certification": "hotels-pilot" if field_ready else "",
                    "reputation_score_e4": 5500 + (i * 120),
                    "metadata": {
                        "pilot": PILOT,
                        "vertical": "hotels",
                        "city": CITY,
                        "field_verified": field_ready,
                        "onboarding_complete": False,
                        "training_complete": False,
                        "roster": "scaffold",
                    },
                    "active": True,
                },
            )
            w.domains.add(hotels_domain)
            if was:
                created_w += 1

        field_hotels = ProviderProfile.objects.filter(metadata__pilot=PILOT).count()
        field_wingas = WingaProfile.objects.filter(metadata__pilot=PILOT).count()
        field_verified_hotels = ProviderProfile.objects.filter(
            metadata__pilot=PILOT, metadata__field_verified=True
        ).count()
        field_verified_wingas = WingaProfile.objects.filter(
            metadata__pilot=PILOT, metadata__field_verified=True
        ).count()

        self.stdout.write(
            self.style.SUCCESS(
                "Hotels field roster OK: "
                f"hotels={field_hotels} (field_verified={field_verified_hotels}), "
                f"wingas={field_wingas} (field_verified={field_verified_wingas}), "
                f"wingas_created={created_w}, "
                f"anchor_offerings="
                f"{Offering.objects.filter(attributes__pilot=PILOT).count()}"
            )
        )
        self.stdout.write(
            self.style.WARNING(
                "Scaffold only — 0 field bookings. Track real onboarding in "
                "docs/winga_pilot/field/"
            )
        )
