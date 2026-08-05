"""Phase 2 city-scale mobility tests."""
from __future__ import annotations

import uuid

from django.test import TestCase
from django.utils import timezone

from .models import (
    Driver,
    DriverAvailability,
    DriverLocation,
    DriverStatus,
    SafetyIncident,
    Station,
    TransportMode,
    Trip,
    Vehicle,
    VehicleStatus,
    VerificationStatus,
)
from .services import create_trip, dispatch_trip, transition_incident


class CityMobilityPhase2Tests(TestCase):
    def setUp(self):
        self.station_a = Station.objects.create(
            code="city-a",
            name="City Station A",
            latitude="-6.816100",
            longitude="39.280300",
            region="Dar es Salaam",
            district="Ilala",
            manager_principal="mgr-a",
            capacity=10,
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        self.station_b = Station.objects.create(
            code="city-b",
            name="City Station B",
            latitude="-6.820000",
            longitude="39.285000",
            region="Dar es Salaam",
            district="Ilala",
            manager_principal="mgr-b",
            capacity=10,
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        self.driver = Driver.objects.create(
            owner_principal="city-driver-1",
            full_name="City Driver",
            status=DriverStatus.ACTIVE,
            availability=DriverAvailability.AVAILABLE,
            identity_status=VerificationStatus.VERIFIED,
            license_status=VerificationStatus.VERIFIED,
            station=self.station_b,
            registry_approval_id=uuid.uuid4(),
            rating_e2=480,
            acceptance_rate_e4=9000,
        )
        Vehicle.objects.create(
            registration_number="CITY-MC-1",
            mode=TransportMode.MOTORCYCLE,
            owner_principal="city-driver-1",
            assigned_driver=self.driver,
            status=VehicleStatus.ACTIVE,
            insurance_status=VerificationStatus.VERIFIED,
            road_license_status=VerificationStatus.VERIFIED,
            inspection_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        DriverLocation.objects.create(
            driver=self.driver,
            latitude="-6.819500",
            longitude="39.284500",
            recorded_at=timezone.now(),
        )

    def test_station_intelligence_and_rankings(self):
        from .city_ops import rank_stations, station_intelligence

        intel = station_intelligence(self.station_a)
        self.assertEqual(intel["station_health"], "healthy")
        rankings = rank_stations(region="Dar es Salaam", district="Ilala")
        self.assertGreaterEqual(len(rankings), 2)

    def test_overflow_dispatch_can_select_cross_station_driver(self):
        trip = create_trip(
            owner="city-passenger",
            pickup_name="Near A",
            pickup_lat="-6.816200",
            pickup_lng="39.280400",
            dropoff_name="Posta",
            dropoff_lat="-6.820000",
            dropoff_lng="39.290000",
            vehicle_mode=TransportMode.MOTORCYCLE,
            region="Dar es Salaam",
            estimated_distance_meters=2500,
            estimated_duration_seconds=600,
            actor="city-passenger",
        )
        Trip.objects.filter(pk=trip.pk).update(
            station=self.station_a,
            dispatch_strategy="overflow",
        )
        offers = dispatch_trip(trip.id)
        self.assertTrue(any(o.driver_id == self.driver.id for o in offers))

    def test_incident_workflow_transitions(self):
        incident = SafetyIncident.objects.create(
            reporter_principal="ops-1",
            kind="sos",
            severity="critical",
            latitude="-6.8",
            longitude="39.2",
        )
        acknowledged = transition_incident(
            incident.id,
            to_status="acknowledged",
            actor="ops-1",
        )
        self.assertEqual(acknowledged.status, "acknowledged")
        resolved = transition_incident(
            acknowledged.id,
            to_status="resolved",
            actor="ops-1",
            notes="safe",
        )
        self.assertEqual(resolved.status, "resolved")
        self.assertIsNotNone(resolved.resolved_at)

    def test_city_map_snapshot(self):
        from .city_ops import city_map_snapshot

        snapshot = city_map_snapshot(region="Dar es Salaam", district="Ilala")
        self.assertEqual(snapshot["summary"]["stations"], 2)
        self.assertGreaterEqual(snapshot["summary"]["drivers_visible"], 1)

    def test_driver_performance_contract(self):
        from .intelligence import driver_performance

        perf = driver_performance(self.driver)
        self.assertIn("reward_score_e4", perf)
        self.assertEqual(perf["driver_id"], str(self.driver.id))
