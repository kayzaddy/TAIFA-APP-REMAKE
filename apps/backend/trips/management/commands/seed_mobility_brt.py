"""Seed DART BRT (Mwendokasi) demo corridor and daladala samples."""
from __future__ import annotations

from datetime import time

from django.core.management.base import BaseCommand
from django.utils import timezone

from trips.national_models import (
    PublicTransitRoute,
    PublicTransitTimetable,
    TransitAlert,
    TransitAvlVehicle,
    TransitScheduledRun,
    TransitStationProfile,
    TransitTicketProduct,
)


DART_STOPS = [
    ("kimara", "Kimara Terminal", -6.7201, 39.2088, 1),
    ("ubungo", "Ubungo BRT", -6.7912, 39.2089, 2),
    ("morocco", "Morocco", -6.8015, 39.2455, 3),
    ("kariakoo", "Kariakoo", -6.8234, 39.2695, 4),
    ("posta", "Posta", -6.8162, 39.2872, 5),
    ("kivukoni", "Kivukoni", -6.8180, 39.2945, 6),
]

DALADALA_ROUTES = [
    {
        "code": "dsm-dala-mwenge",
        "name": "Mwenge — Posta Daladala",
        "stops": [
            {"code": "mwenge", "name": "Mwenge", "lat": -6.7490, "lng": 39.2450, "sequence": 1},
            {"code": "mustafa", "name": "Mustafa Centre", "lat": -6.7750, "lng": 39.2550, "sequence": 2},
            {"code": "posta", "name": "Posta", "lat": -6.8162, "lng": 39.2872, "sequence": 3},
        ],
        "metadata": {"operator": "LATRA", "mode": "daladala", "brand": "Daladala"},
        "fare_minor": 800_00,
    },
    {
        "code": "dsm-dala-sinza",
        "name": "Sinza — Kariakoo Daladala",
        "stops": [
            {"code": "sinza", "name": "Sinza", "lat": -6.7850, "lng": 39.2150, "sequence": 1},
            {"code": "magomeni", "name": "Magomeni", "lat": -6.8000, "lng": 39.2400, "sequence": 2},
            {"code": "kariakoo", "name": "Kariakoo", "lat": -6.8234, "lng": 39.2695, "sequence": 3},
        ],
        "metadata": {"operator": "UDA", "mode": "daladala", "brand": "Daladala"},
        "fare_minor": 700_00,
    },
]


class Command(BaseCommand):
    help = "Seed DART BRT Mwendokasi corridor, stations, products, and daladala demos"

    def handle(self, *args, **options):
        products = [
            ("brt_single", "BRT Single Ride", "single", 650_00, 2, 1),
            ("brt_daily", "BRT Daily Pass", "daily", 3_500_00, 24, 10),
            ("dala_single", "Daladala Single Ride", "single", 800_00, 2, 1),
            ("dala_daily", "Daladala Daily Pass", "daily", 2_500_00, 24, 8),
        ]
        for code, name, ticket_type, fare, hours, max_val in products:
            mode = "daladala" if code.startswith("dala_") else "brt"
            operator = "LATRA/UDA" if mode == "daladala" else "DART"
            TransitTicketProduct.objects.update_or_create(
                code=code,
                defaults={
                    "name": name,
                    "description": f"{'Daladala' if mode == 'daladala' else 'Mwendokasi'} {name}",
                    "ticket_type": ticket_type,
                    "fare_minor": fare,
                    "currency": "TZS",
                    "validity_hours": hours,
                    "max_validations": max_val,
                    "active": True,
                    "metadata": {"operator": operator, "mode": mode},
                },
            )

        stops = [
            {
                "code": code,
                "name": name,
                "lat": lat,
                "lng": lng,
                "sequence": seq,
            }
            for code, name, lat, lng, seq in DART_STOPS
        ]
        route, _ = PublicTransitRoute.objects.update_or_create(
            code="dart-kimara-kivukoni",
            defaults={
                "name": "Kimara — Kivukoni (Mwendokasi)",
                "region": "Dar es Salaam",
                "district": "Kinondoni",
                "operator_principal": "dart-ops",
                "vehicle_mode": "bus",
                "stops": stops,
                "metadata": {
                    "operator": "DART",
                    "mode": "brt",
                    "brand": "Mwendokasi",
                    "corridor": "phase_1",
                    "color": "#00A651",
                },
                "active": True,
            },
        )

        weekday = timezone.localdate().weekday()
        for hour in (6, 7, 8, 17, 18, 19):
            PublicTransitTimetable.objects.update_or_create(
                route=route,
                weekday=weekday,
                departure_time=time(hour, 30),
                defaults={
                    "seats": 80,
                    "fare_minor": 650_00,
                    "currency": "TZS",
                    "active": True,
                },
            )

        station_count = 0
        for code, name, lat, lng, _seq in DART_STOPS:
            _, created = TransitStationProfile.objects.update_or_create(
                stop_code=code,
                defaults={
                    "name": name,
                    "region": "Dar es Salaam",
                    "latitude": lat,
                    "longitude": lng,
                    "image_url": "https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800",
                    "facilities": ["shelter", "ticketing", "security"],
                    "accessibility": {"wheelchair": True, "elevator": code in {"kimara", "ubungo"}},
                    "platform": f"Platform {code[:1].upper()}",
                    "exit_map": {"north": "Main road", "south": "Commercial area"},
                    "active": True,
                },
            )
            if created:
                station_count += 1

        TransitAlert.objects.update_or_create(
            title="Mwendokasi service running normally",
            region="Dar es Salaam",
            defaults={
                "severity": "info",
                "body": "All BRT corridors operational. Buy digital tickets in Taifa Wallet.",
                "active": True,
                "route": route,
            },
        )

        dala_created = 0
        for item in DALADALA_ROUTES:
            droute, was_new = PublicTransitRoute.objects.update_or_create(
                code=item["code"],
                defaults={
                    "name": item["name"],
                    "region": "Dar es Salaam",
                    "district": "Kinondoni",
                    "operator_principal": item["metadata"]["operator"].lower(),
                    "vehicle_mode": "minibus",
                    "stops": item["stops"],
                    "metadata": item["metadata"],
                    "active": True,
                },
            )
            if was_new:
                dala_created += 1
            PublicTransitTimetable.objects.update_or_create(
                route=droute,
                weekday=weekday,
                departure_time=time(7, 15),
                defaults={
                    "seats": 14,
                    "fare_minor": item["fare_minor"],
                    "currency": "TZS",
                    "active": True,
                },
            )

        demo_driver = "dev_brt-driver-demo"
        TransitScheduledRun.objects.filter(driver_owner=demo_driver).delete()
        base = timezone.now().replace(minute=0, second=0, microsecond=0)
        for idx, hours_ahead in enumerate((1, 3, 5), start=1):
            TransitScheduledRun.objects.create(
                route=route,
                driver_owner=demo_driver,
                vehicle_label=f"DART-{200 + idx}",
                scheduled_at=base + timezone.timedelta(hours=hours_ahead),
                origin_stop="kimara",
                destination_stop="kivukoni",
                status=TransitScheduledRun.Status.SCHEDULED,
                metadata={"seed_key": f"demo-run-{idx}"},
            )

        avl_samples = [
            ("DART-201", -6.7350, 39.2095, 1500, "ubungo", 240, 28),
            ("DART-202", -6.8020, 39.2460, 4500, "kariakoo", 360, 32),
            ("DART-203", -6.8175, 39.2910, 8800, "kivukoni", 90, 18),
        ]
        for label, lat, lng, progress, next_stop, eta, speed in avl_samples:
            TransitAvlVehicle.objects.update_or_create(
                vehicle_label=label,
                defaults={
                    "route": route,
                    "latitude": lat,
                    "longitude": lng,
                    "heading": 95,
                    "speed_kmh": speed,
                    "progress_e4": progress,
                    "next_stop_code": next_stop,
                    "eta_next_stop_seconds": eta,
                    "status": TransitAvlVehicle.Status.IN_SERVICE,
                    "active": True,
                },
            )

        self.stdout.write(
            self.style.SUCCESS(
                f"Mobility BRT seeded: route={route.code}, "
                f"{TransitStationProfile.objects.count()} station profiles, "
                f"{TransitTicketProduct.objects.count()} products, "
                f"{dala_created} new daladala routes"
            )
        )
