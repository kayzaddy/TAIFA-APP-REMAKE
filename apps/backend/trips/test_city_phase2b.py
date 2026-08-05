"""Phase 2B passenger, pricing, regional, and city simulation tests."""
from __future__ import annotations

import uuid
from datetime import time, timedelta
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone

from .models import (
    Driver,
    DriverAvailability,
    DriverLocation,
    DriverStatus,
    MobilityFavorite,
    PricingRule,
    RecurringRidePlan,
    RegionalSupervisorAssignment,
    Station,
    TransportMode,
    TripKind,
    Vehicle,
    VehicleStatus,
    VerificationStatus,
)
from .passenger_views import materialize_recurring_rides
from .services import create_trip, quote_fare


class PassengerAndPricingPhase2BTests(TestCase):
    def setUp(self):
        self.station = Station.objects.create(
            code="p2b-station",
            name="P2B Station",
            latitude="-6.816100",
            longitude="39.280300",
            region="Dar es Salaam",
            district="Ilala",
            manager_principal="mgr-p2b",
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
            service_radius_meters=50_000,
        )
        PricingRule.objects.create(
            code="p2b-moto",
            version=1,
            vehicle_mode=TransportMode.MOTORCYCLE,
            region="Dar es Salaam",
            trip_kind=TripKind.PASSENGER,
            base_fare_minor=1000,
            per_km_minor=500,
            per_minute_minor=50,
            minimum_fare_minor=1000,
            night_multiplier_e4=12000,
            peak_multiplier_e4=15000,
            conditions={
                "peak_hours": [7, 8, 9],
                "holiday_multiplier_e4": 13000,
                "holidays": [timezone.localdate().isoformat()],
                "corporate_accounts": ["acme-corp"],
                "corporate_multiplier_e4": 9000,
            },
            effective_from=timezone.now() - timezone.timedelta(days=1),
            active=True,
        )

    def test_pricing_applies_holiday_and_corporate_multipliers(self):
        quote = quote_fare(
            vehicle_mode=TransportMode.MOTORCYCLE,
            trip_kind=TripKind.PASSENGER,
            region="Dar es Salaam",
            distance_meters=2000,
            duration_seconds=600,
            at=timezone.now().replace(hour=8, minute=0, second=0, microsecond=0),
            corporate_account="acme-corp",
        )
        self.assertTrue(quote.breakdown["holiday"])
        self.assertEqual(quote.breakdown["corporate_account"], "acme-corp")
        self.assertGreater(quote.total_minor, 0)

    def test_favorite_uniqueness(self):
        MobilityFavorite.objects.create(
            owner="passenger-1",
            subject_type=MobilityFavorite.SubjectType.STATION,
            subject_id=str(self.station.id),
            label="Home station",
        )
        with self.assertRaises(Exception):
            MobilityFavorite.objects.create(
                owner="passenger-1",
                subject_type=MobilityFavorite.SubjectType.STATION,
                subject_id=str(self.station.id),
            )

    def test_recurring_ride_materialization(self):
        future_dt = timezone.localtime() + timedelta(hours=2)
        plan = RecurringRidePlan.objects.create(
            owner="passenger-recurring",
            label="Morning commute",
            pickup_name="A",
            pickup_lat=Decimal("-6.816200"),
            pickup_lng=Decimal("39.280400"),
            dropoff_name="B",
            dropoff_lat=Decimal("-6.820000"),
            dropoff_lng=Decimal("39.290000"),
            vehicle_mode=TransportMode.MOTORCYCLE,
            region="Dar es Salaam",
            estimated_distance_meters=2500,
            estimated_duration_seconds=600,
            weekdays=[future_dt.weekday()],
            local_time=future_dt.time().replace(microsecond=0),
            active=True,
        )
        result = materialize_recurring_rides(day=future_dt.date())
        plan.refresh_from_db()
        self.assertEqual(result["created"], 1)
        self.assertEqual(plan.last_materialized_on, future_dt.date())


class CityDispatchSimulationTests(TestCase):
    def setUp(self):
        PricingRule.objects.create(
            code="sim-moto",
            version=1,
            vehicle_mode=TransportMode.MOTORCYCLE,
            region="Dar es Salaam",
            trip_kind=TripKind.PASSENGER,
            base_fare_minor=1000,
            per_km_minor=400,
            per_minute_minor=40,
            minimum_fare_minor=1000,
            effective_from=timezone.now() - timezone.timedelta(days=1),
            active=True,
        )
        self.stations = []
        for index in range(5):
            station = Station.objects.create(
                code=f"sim-st-{index}",
                name=f"Sim Station {index}",
                latitude=f"-6.81{index}000",
                longitude=f"39.28{index}000",
                region="Dar es Salaam",
                district="Ilala",
                manager_principal=f"mgr-{index}",
                capacity=20,
                verification_status=VerificationStatus.VERIFIED,
                registry_approval_id=uuid.uuid4(),
                service_radius_meters=100_000,
            )
            self.stations.append(station)
            for d in range(4):
                driver = Driver.objects.create(
                    owner_principal=f"sim-driver-{index}-{d}",
                    full_name=f"Sim Driver {index}-{d}",
                    status=DriverStatus.ACTIVE,
                    availability=DriverAvailability.AVAILABLE,
                    identity_status=VerificationStatus.VERIFIED,
                    license_status=VerificationStatus.VERIFIED,
                    station=station,
                    registry_approval_id=uuid.uuid4(),
                    rating_e2=450,
                    acceptance_rate_e4=8500,
                )
                Vehicle.objects.create(
                    registration_number=f"SIM-{index}-{d}",
                    mode=TransportMode.MOTORCYCLE,
                    owner_principal=driver.owner_principal,
                    assigned_driver=driver,
                    status=VehicleStatus.ACTIVE,
                    insurance_status=VerificationStatus.VERIFIED,
                    road_license_status=VerificationStatus.VERIFIED,
                    inspection_status=VerificationStatus.VERIFIED,
                    registry_approval_id=uuid.uuid4(),
                )
                DriverLocation.objects.create(
                    driver=driver,
                    latitude=station.latitude,
                    longitude=station.longitude,
                    recorded_at=timezone.now(),
                )

    def test_city_wide_request_burst_dispatches(self):
        from .services import dispatch_trip

        offered = 0
        for i in range(10):
            trip = create_trip(
                owner=f"sim-passenger-{i}",
                pickup_name=f"Pickup {i}",
                pickup_lat=Decimal("-6.816200"),
                pickup_lng=Decimal("39.280400"),
                dropoff_name=f"Drop {i}",
                dropoff_lat=Decimal("-6.820000"),
                dropoff_lng=Decimal("39.290000"),
                vehicle_mode=TransportMode.MOTORCYCLE,
                region="Dar es Salaam",
                estimated_distance_meters=2000 + i * 100,
                estimated_duration_seconds=500,
                actor=f"sim-passenger-{i}",
                dispatch_strategy="overflow" if i % 2 else "station_first",
            )
            offers = dispatch_trip(trip.id)
            offered += len(offers)
        self.assertGreaterEqual(offered, 10)


class RegionalSupervisorTests(TestCase):
    def test_assignment_scopes_region(self):
        assignment = RegionalSupervisorAssignment.objects.create(
            principal="supervisor-1",
            scope=RegionalSupervisorAssignment.Scope.DISTRICT,
            region="Dar es Salaam",
            district="Ilala",
            role_title="district_manager",
        )
        self.assertEqual(assignment.district, "Ilala")
