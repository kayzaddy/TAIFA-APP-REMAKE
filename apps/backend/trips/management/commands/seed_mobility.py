"""Seed a Dar es Salaam station + demo drivers for local ride requests."""
from __future__ import annotations

import uuid

from django.core.management.base import BaseCommand
from django.utils import timezone

from trips.models import (
    Driver,
    DriverAvailability,
    DriverLocation,
    DriverStatus,
    Station,
    StationQueueEntry,
    TransportMode,
    Vehicle,
    VehicleStatus,
    VerificationStatus,
)


class Command(BaseCommand):
    help = "Seed approved station, drivers, and vehicles for local mobility demos"

    def handle(self, *args, **options):
        station, created = Station.objects.update_or_create(
            code="dar-masaki-hub",
            defaults={
                "name": "Masaki Mobility Hub",
                "latitude": "-6.750000",
                "longitude": "39.280000",
                "region": "Dar es Salaam",
                "district": "Kinondoni",
                "ward": "Masaki",
                "manager_principal": "station-manager-masaki",
                "service_radius_meters": 50_000,
                "active": True,
                "verification_status": VerificationStatus.VERIFIED,
                "registry_approval_id": uuid.uuid5(uuid.NAMESPACE_DNS, "dar-masaki-hub"),
            },
        )
        self.stdout.write(
            self.style.SUCCESS(f"{'Created' if created else 'Updated'} station {station.code}")
        )

        demos = [
            ("taxi", "T 458 DSM", "Silver", "Toyota", "Corolla", "Amina Juma"),
            ("private_car", "T 901 DSM", "Black", "Honda", "Accord", "Baraka Mushi"),
            ("van", "T 220 DSM", "White", "Toyota", "Hiace", "Neema Ally"),
            ("motorcycle", "MC 101 DSM", "Red", "Bajaj", "Boxer", "Juma Mussa"),
        ]
        for i, (mode, plate, color, make, model, name) in enumerate(demos, start=1):
            principal = f"demo-driver-{mode}"
            driver, _ = Driver.objects.update_or_create(
                owner_principal=principal,
                defaults={
                    "full_name": name,
                    "phone_masked": f"+25570000000{i}",
                    "status": DriverStatus.ACTIVE,
                    "availability": DriverAvailability.AVAILABLE,
                    "identity_status": VerificationStatus.VERIFIED,
                    "license_status": VerificationStatus.VERIFIED,
                    "station": station,
                    "registry_approval_id": uuid.uuid5(uuid.NAMESPACE_DNS, principal),
                    "rating_e2": 490,
                    "safety_score_e2": 480,
                    "acceptance_rate_e4": 9500,
                },
            )
            vehicle, _ = Vehicle.objects.update_or_create(
                registration_number=plate,
                defaults={
                    "mode": mode,
                    "make": make,
                    "model": model,
                    "color": color,
                    "capacity": 4 if mode != TransportMode.MOTORCYCLE else 1,
                    "owner_principal": principal,
                    "assigned_driver": driver,
                    "status": VehicleStatus.ACTIVE,
                    "insurance_status": VerificationStatus.VERIFIED,
                    "road_license_status": VerificationStatus.VERIFIED,
                    "inspection_status": VerificationStatus.VERIFIED,
                    "registry_approval_id": uuid.uuid5(uuid.NAMESPACE_DNS, f"veh-{plate}"),
                },
            )
            DriverLocation.objects.update_or_create(
                driver=driver,
                defaults={
                    "latitude": "-6.751000",
                    "longitude": "39.281000",
                    "recorded_at": timezone.now(),
                },
            )
            StationQueueEntry.objects.update_or_create(
                driver=driver,
                defaults={"station": station, "position": i, "active": True},
            )
            self.stdout.write(f"  driver {driver.full_name} · {vehicle.mode} · {plate}")

        self.stdout.write(self.style.SUCCESS("Mobility demo seed complete."))
