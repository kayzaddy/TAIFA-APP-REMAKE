"""Seed Winga Property listings, virtual experience media, and demo access."""
from __future__ import annotations

import secrets
from datetime import timedelta

from django.core.management.base import BaseCommand
from django.utils import timezone

from winga_property.models import (
    MediaKind,
    MediaTourKind,
    PropertyCategory,
    PropertyListing,
    PropertyOwner,
    PropertyOwnerRole,
    PropertyTransactionType,
    PropertyType,
    PropertyVerificationStatus,
    PropertyViewingPass,
    PropertyViewingPassStatus,
    ViewingPassPlanCode,
)
from winga_property.services import add_media, verify_listing

PROPERTY_WINGAS = [
    ("winga-property-asha", "Asha Mwangi", "Taifa Certified Property Advisor", 8200),
    ("winga-property-juma", "Juma Kilimanjaro", "Senior Real Estate Winga", 7800),
    ("winga-property-neema", "Neema Hassan", "Relocation & Property Specialist", 7600),
]

DEMO_VIDEO = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"

EXPERIENCE_BY_TITLE: dict[str, dict] = {
    "Masaki Sea View Apartment": {
        "walkthrough": [
            ("living", "Living room", "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200"),
            ("kitchen", "Kitchen", "https://images.unsplash.com/photo-1556911222-e6b2c8c8b65e?w=1200"),
            ("bedroom", "Master bedroom", "https://images.unsplash.com/photo-1616594039964-4081a3b8e2c5?w=1200"),
            ("bathroom", "Bathroom", "https://images.unsplash.com/photo-1620626011761-996317b8d101?w=1200"),
            ("compound", "Balcony & compound", "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200"),
        ],
        "floor_plan_rooms": ["living", "kitchen", "bedroom", "bathroom"],
        "panorama": "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=2000",
        "vr_ready": True,
    },
    "Mikocheni Family House": {
        "walkthrough": [
            ("exterior", "Street view", "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=1200"),
            ("living", "Living room", "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=1200"),
            ("kitchen", "Kitchen", "https://images.unsplash.com/photo-1556912173-46c336c7fd55?w=1200"),
            ("bedroom", "Bedroom", "https://images.unsplash.com/photo-1615529328331-f8917597711f?w=1200"),
            ("compound", "Garden", "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200"),
        ],
        "floor_plan_rooms": ["living", "kitchen", "bedroom", "bathroom", "compound"],
        "panorama": "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=2000",
    },
    "Oysterbay Office Suite": {
        "walkthrough": [
            ("exterior", "Building entrance", "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200"),
            ("living", "Reception", "https://images.unsplash.com/photo-1497366216548-37526070297c?w=1200"),
            ("kitchen", "Pantry", "https://images.unsplash.com/photo-1497366754035-f200968a6e72?w=1200"),
            ("bedroom", "Executive office", "https://images.unsplash.com/photo-1497366811353-6870744d04b2?w=1200"),
            ("parking", "Parking bay", "https://images.unsplash.com/photo-1506521781263-d8422e82f27a?w=1200"),
        ],
        "floor_plan_rooms": ["reception", "office", "meeting", "pantry"],
    },
    "Tegeta Plot — 500 sqm": {
        "walkthrough": [
            ("exterior", "Plot frontage", "https://images.unsplash.com/photo-1500382017468-90403fedc95e?w=1200"),
            ("compound", "Survey stakes", "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=1200"),
        ],
        "floor_plan_rooms": ["plot"],
        "panorama": "https://images.unsplash.com/photo-1500382017468-90403fedc95e?w=2000",
    },
}

DEMO_LISTINGS = [
    {
        "title": "Masaki Sea View Apartment",
        "type": "apartment",
        "cat": "residential",
        "price": 2_500_000,
        "deposit": 5_000_000,
        "beds": 2,
        "baths": 2,
        "area": 95,
        "ward": "Masaki",
        "district": "Kinondoni",
        "region": "Dar es Salaam",
        "lat": "-6.7505",
        "lng": "39.2795",
        "photo": "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
    },
    {
        "title": "Mikocheni Family House",
        "type": "house",
        "cat": "residential",
        "price": 1_800_000,
        "deposit": 3_600_000,
        "beds": 3,
        "baths": 2,
        "area": 140,
        "ward": "Mikocheni",
        "district": "Kinondoni",
        "region": "Dar es Salaam",
        "lat": "-6.7580",
        "lng": "39.2450",
        "photo": "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
    },
    {
        "title": "Oysterbay Office Suite",
        "type": "office",
        "cat": "commercial",
        "price": 4_500_000,
        "deposit": 9_000_000,
        "beds": 0,
        "baths": 1,
        "area": 120,
        "ward": "Oysterbay",
        "district": "Ilala",
        "region": "Dar es Salaam",
        "lat": "-6.7690",
        "lng": "39.2870",
        "photo": "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800",
    },
    {
        "title": "Tegeta Plot — 500 sqm",
        "type": "plot",
        "cat": "land",
        "price": 85_000_000,
        "deposit": 0,
        "beds": 0,
        "baths": 0,
        "area": 500,
        "ward": "Tegeta",
        "district": "Kinondoni",
        "region": "Dar es Salaam",
        "lat": "-6.7200",
        "lng": "39.2200",
        "photo": "https://images.unsplash.com/photo-1500382017468-90403fedc95e?w=800",
        "transaction": PropertyTransactionType.SALE,
    },
]


def _ensure_basic_media(*, listing: PropertyListing, photo_url: str) -> None:
    if not listing.media.filter(is_primary=True).exists():
        add_media(listing=listing, kind=MediaKind.PHOTO, url=photo_url, is_primary=True)
    if not listing.media.filter(tour_kind=MediaTourKind.VIDEO_TOUR).exists():
        add_media(
            listing=listing,
            kind=MediaKind.VIDEO,
            url=DEMO_VIDEO,
            caption="Property video tour",
            duration_seconds=60,
            tour_kind=MediaTourKind.VIDEO_TOUR,
            sort_order=1,
        )
    if not listing.media.filter(tour_kind=MediaTourKind.GUIDED_TOUR).exists():
        add_media(
            listing=listing,
            kind=MediaKind.VIDEO,
            url=DEMO_VIDEO,
            caption="Guided tour with Winga host",
            duration_seconds=90,
            tour_kind=MediaTourKind.GUIDED_TOUR,
            sort_order=2,
        )


def _ensure_virtual_experience(*, listing: PropertyListing, preset: dict) -> int:
    """Idempotently attach walkthrough, floor plan, and 360 media. Returns items added."""
    added = 0
    existing_rooms = set(
        listing.media.filter(tour_kind=MediaTourKind.WALKTHROUGH)
        .exclude(room_code="")
        .values_list("room_code", flat=True)
    )
    for i, (room, caption, url) in enumerate(preset.get("walkthrough", [])):
        if room in existing_rooms:
            continue
        add_media(
            listing=listing,
            kind=MediaKind.PHOTO,
            url=url,
            caption=caption,
            sort_order=10 + i,
            room_code=room,
            tour_kind=MediaTourKind.WALKTHROUGH,
            is_hd=True,
        )
        added += 1

    if not listing.media.filter(tour_kind=MediaTourKind.FLOOR_PLAN).exists():
        rooms = preset.get("floor_plan_rooms", [])
        add_media(
            listing=listing,
            kind=MediaKind.PHOTO,
            url="https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=1200",
            caption="Floor plan",
            tour_kind=MediaTourKind.FLOOR_PLAN,
            sort_order=50,
            floor_plan_data={"rooms": rooms, "sqm": float(listing.area_sqm or 0)},
        )
        added += 1

    panorama = preset.get("panorama")
    if panorama and not listing.media.filter(tour_kind=MediaTourKind.PANORAMA_360).exists():
        add_media(
            listing=listing,
            kind=MediaKind.PHOTO,
            url=panorama,
            caption="360° panorama",
            tour_kind=MediaTourKind.PANORAMA_360,
            panorama_url=panorama,
            sort_order=60,
            is_hd=True,
        )
        added += 1

    return added


def _bootstrap_device_virtual_access() -> tuple[int, int]:
    """Fund wallets and grant active unlimited viewing passes for all registered devices."""
    from payments import journal
    from payments.engine import default_engine
    from payments.models import Device, Transaction, TransactionDirection, TransactionStatus, TransactionType
    from payments.money import Currency, Money
    from payments.orchestrator import OrchestratorContext, default_orchestrator

    demo_balance = Money.major(2_847_500, Currency.TZS)
    min_balance = Money.major(500_000, Currency.TZS)
    funded = 0
    passes = 0

    for owner in Device.objects.values_list("owner", flat=True).distinct():
        balance = default_engine().wallet_balance(owner, Currency.TZS)
        if balance.minor_units < min_balance.minor_units:
            top_up = Money(min_balance.minor_units - balance.minor_units, Currency.TZS)
            if balance.minor_units == 0:
                try:
                    default_orchestrator().open_wallet(
                        owner,
                        demo_balance,
                        OrchestratorContext(actor="seed", device_id=""),
                    )
                    funded += 1
                except Exception:
                    pass
            else:
                txn = Transaction.objects.create(
                    owner=owner,
                    type=TransactionType.TOP_UP,
                    status=TransactionStatus.SUCCEEDED,
                    direction=TransactionDirection.CREDIT,
                    amount_minor=top_up.minor_units,
                    currency="TZS",
                    counterparty="Winga Property virtual experience demo",
                    method_kind="wallet",
                    idempotency_key=f"seed-vx-{owner[:40]}-{secrets.token_hex(4)}",
                )
                journal.post_topup_settle(
                    txn, owner, top_up, "Winga Property virtual experience demo"
                )
                funded += 1

        if PropertyViewingPass.objects.filter(
            principal=owner,
            status=PropertyViewingPassStatus.ACTIVE,
            plan_code=ViewingPassPlanCode.UNLIMITED,
        ).exists():
            continue
        PropertyViewingPass.objects.create(
            principal=owner,
            plan_code=ViewingPassPlanCode.UNLIMITED,
            status=PropertyViewingPassStatus.ACTIVE,
            amount_minor=0,
            currency="TZS",
            payment_ref="demo-seed",
            qr_token=secrets.token_urlsafe(24),
            unlock_address=True,
            unlock_navigation=True,
            unlock_contact=True,
            unlock_scheduling=True,
            expires_at=timezone.now() + timedelta(days=30),
        )
        passes += 1

    return funded, passes


class Command(BaseCommand):
    help = "Seed Winga Property categories, listings, virtual experience media, and demo access"

    def add_arguments(self, parser):
        parser.add_argument(
            "--no-bootstrap",
            action="store_true",
            help="Skip wallet funding and unlimited viewing pass for registered devices",
        )

    def handle(self, *args, **options):
        from django.core.management import call_command

        from winga.models import BrokerageDomain, VerificationStatus, WingaProfile

        call_command("seed_winga")
        property_domain = BrokerageDomain.objects.filter(code="property").first()

        categories = [
            ("residential", "Residential", "Homes and apartments", "home", 1),
            ("commercial", "Commercial", "Offices and retail", "store", 2),
            ("land", "Land", "Plots and acreage", "landscape", 3),
        ]
        for code, name, desc, icon, order in categories:
            PropertyCategory.objects.update_or_create(
                code=code,
                defaults={"name": name, "description": desc, "icon": icon, "sort_order": order},
            )

        types = [
            ("residential", "apartment", "Apartment"),
            ("residential", "house", "House"),
            ("residential", "villa", "Villa"),
            ("commercial", "office", "Office Space"),
            ("commercial", "shop", "Shop / Retail"),
            ("land", "plot", "Plot"),
        ]
        for cat_code, type_code, type_name in types:
            cat = PropertyCategory.objects.get(code=cat_code)
            PropertyType.objects.update_or_create(
                category=cat,
                code=type_code,
                defaults={"name": type_name},
            )

        owner, _ = PropertyOwner.objects.get_or_create(
            principal="winga-property-demo-owner",
            defaults={
                "display_name": "Salma Properties",
                "phone": "+255712345000",
                "role": PropertyOwnerRole.AGENT,
                "verification_status": PropertyVerificationStatus.VERIFIED,
            },
        )

        created = 0
        experience_items = 0
        for d in DEMO_LISTINGS:
            cat = PropertyCategory.objects.get(code=d["cat"])
            ptype = PropertyType.objects.get(category=cat, code=d["type"])
            listing, was_new = PropertyListing.objects.get_or_create(
                owner=owner,
                title=d["title"],
                defaults={
                    "category": cat,
                    "property_type": ptype,
                    "transaction_type": d.get("transaction", PropertyTransactionType.RENT),
                    "description": (
                        f"Verified listing in {d['ward']}, {d['region']}. "
                        "Includes virtual walkthrough, floor plan, and live tour."
                    ),
                    "price_minor": d["price"],
                    "deposit_minor": d["deposit"],
                    "beds": d["beds"],
                    "baths": d["baths"],
                    "area_sqm": d["area"],
                    "ward": d["ward"],
                    "district": d["district"],
                    "region": d["region"],
                    "latitude": d["lat"],
                    "longitude": d["lng"],
                    "address_line": f"{d['ward']}, {d['district']}",
                },
            )
            if was_new:
                created += 1

            _ensure_basic_media(listing=listing, photo_url=d["photo"])
            preset = EXPERIENCE_BY_TITLE.get(d["title"], {})
            experience_items += _ensure_virtual_experience(listing=listing, preset=preset)

            if listing.verification_status != PropertyVerificationStatus.VERIFIED:
                verify_listing(listing=listing, actor="seed", approve=True, notes="demo verified")

        for principal, name, cert, rep in PROPERTY_WINGAS:
            winga, _ = WingaProfile.objects.update_or_create(
                principal=principal,
                defaults={
                    "display_name": name,
                    "certification": cert,
                    "verification_status": VerificationStatus.VERIFIED,
                    "reputation_score_e4": rep,
                    "bio": "Trusted Taifa property Winga serving Dar es Salaam.",
                },
            )
            if property_domain:
                winga.domains.add(property_domain)

        funded = passes = 0
        if not options["no_bootstrap"]:
            funded, passes = _bootstrap_device_virtual_access()

        self.stdout.write(
            self.style.SUCCESS(
                f"Winga Property seeded: {PropertyCategory.objects.count()} categories, "
                f"{PropertyListing.objects.filter(active=True).count()} listings ({created} new), "
                f"{experience_items} experience media items added, "
                f"{funded} wallets funded, {passes} unlimited viewing passes granted"
            )
        )
