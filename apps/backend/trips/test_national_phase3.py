"""Phase 3 national mobility infrastructure tests."""
from __future__ import annotations

import uuid
from decimal import Decimal

from django.test import TestCase
from django.utils import timezone

from .adapters.government import government_adapter
from .models import (
    PricingRule,
    Station,
    TransportMode,
    TripKind,
    VerificationStatus,
)
from .national_models import (
    EnterpriseEmployee,
    EnterpriseOrganization,
    IntercityCorridor,
    IntercityDeparture,
    NationalDailyMetric,
    PartnerApiCredential,
    PublicTransitRoute,
    PublicTransitTimetable,
    TransportTicket,
)
from .national_ops import (
    build_national_daily_metrics,
    national_analytics,
    national_command_center,
    national_map_layers,
    national_optimization_recommendations,
)
from .national_services import (
    authorize_enterprise_trip,
    book_intercity_departure,
    create_emergency_dispatch,
    create_logistics_shipment,
    create_partner_credential,
    issue_transit_ticket,
    validate_ticket,
)
from .services import MobilityError


def _ensure_pricing(mode: str, trip_kind: str) -> None:
    PricingRule.objects.get_or_create(
        code=f"test-{mode}-{trip_kind}",
        version=1,
        defaults={
            "vehicle_mode": mode,
            "region": "",
            "trip_kind": trip_kind,
            "base_fare_minor": 1000 if trip_kind != TripKind.EMERGENCY else 0,
            "per_km_minor": 400 if trip_kind != TripKind.EMERGENCY else 0,
            "per_minute_minor": 40 if trip_kind != TripKind.EMERGENCY else 0,
            "waiting_per_minute_minor": 40 if trip_kind != TripKind.EMERGENCY else 0,
            "minimum_fare_minor": 1000 if trip_kind != TripKind.EMERGENCY else 0,
            "night_multiplier_e4": 10000,
            "peak_multiplier_e4": 10000,
            "conditions": {},
            "active": True,
            "effective_from": timezone.now() - timezone.timedelta(days=1),
        },
    )


class NationalCommandCenterTests(TestCase):
    def setUp(self):
        Station.objects.create(
            code="noc-dsm-1",
            name="NOC Station DSM",
            latitude="-6.816100",
            longitude="39.280300",
            region="Dar es Salaam",
            district="Ilala",
            manager_principal="mgr-noc",
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
            service_radius_meters=50_000,
            active=True,
        )
        Station.objects.create(
            code="noc-arusha-1",
            name="NOC Station Arusha",
            latitude="-3.386900",
            longitude="36.683000",
            region="Arusha",
            district="Arusha",
            manager_principal="mgr-aru",
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
            service_radius_meters=50_000,
            active=True,
        )

    def test_command_center_covers_regions(self):
        payload = national_command_center()
        self.assertIn("Dar es Salaam", payload["regions"])
        self.assertIn("Arusha", payload["regions"])
        self.assertEqual(payload["national"]["regions"], 2)
        self.assertIn(payload["national"]["system_health"], {"healthy", "degraded", "critical"})
        self.assertEqual(payload["model_version"], "national-command-center-v1")

    def test_national_map_layers(self):
        layers = national_map_layers()
        self.assertGreaterEqual(len(layers["layers"]), 2)
        self.assertEqual(layers["model_version"], "national-map-v1")

    def test_daily_metrics_and_analytics(self):
        NationalDailyMetric.objects.create(
            date=timezone.localdate(),
            region="Dar es Salaam",
            district="Ilala",
            vehicle_mode=TransportMode.MOTORCYCLE,
            trip_kind=TripKind.PASSENGER,
            requested=10,
            completed=8,
            cancelled=1,
            fare_minor=50_000,
            sos_count=0,
        )
        analytics = national_analytics(days=7)
        self.assertEqual(analytics["by_region"][0]["region"], "Dar es Salaam")
        result = build_national_daily_metrics(day=timezone.localdate())
        self.assertIn("rows", result)

    def test_optimization_recommendations_shape(self):
        recs = national_optimization_recommendations()
        self.assertIn("demand", recs)
        self.assertIn("fleet_balancing", recs)
        self.assertIn("station_expansion", recs)


class IntercityAndTicketingTests(TestCase):
    def setUp(self):
        self.corridor = IntercityCorridor.objects.create(
            code="dsm-morogoro",
            name="Dar–Morogoro",
            origin_region="Dar es Salaam",
            destination_region="Morogoro",
            distance_km=195,
            typical_duration_minutes=240,
            vehicle_modes=["bus", "minibus"],
            active=True,
        )
        self.departure = IntercityDeparture.objects.create(
            corridor=self.corridor,
            vehicle_mode="bus",
            operator_principal="operator-1",
            departs_at=timezone.now() + timezone.timedelta(hours=6),
            arrives_at=timezone.now() + timezone.timedelta(hours=10),
            seats_total=40,
            seats_available=40,
            fare_minor=15_000_00,
            currency="TZS",
            status="scheduled",
        )
        self.route = PublicTransitRoute.objects.create(
            code="dsm-uda-01",
            name="UDA Route 01",
            region="Dar es Salaam",
            district="Ilala",
            operator_principal="uda-ops",
            vehicle_mode="bus",
            stops=[{"name": "Kariakoo"}, {"name": "Posta"}],
            active=True,
        )
        PublicTransitTimetable.objects.create(
            route=self.route,
            weekday=timezone.localdate().weekday(),
            departure_time=timezone.localtime().time().replace(microsecond=0),
            seats=50,
            fare_minor=500_00,
            active=True,
        )

    def test_book_intercity_issues_ticket(self):
        booking = book_intercity_departure(
            departure_id=self.departure.id,
            owner="passenger-ic-1",
            seats=2,
        )
        self.departure.refresh_from_db()
        self.assertEqual(booking.seats, 2)
        self.assertEqual(booking.fare_minor, 30_000_00)
        self.assertEqual(self.departure.seats_available, 38)
        self.assertTrue(
            TransportTicket.objects.filter(
                intercity_booking=booking, status="active"
            ).exists()
        )

    def test_book_intercity_rejects_overbook(self):
        self.departure.seats_available = 1
        self.departure.save(update_fields=["seats_available"])
        with self.assertRaises(MobilityError):
            book_intercity_departure(
                departure_id=self.departure.id,
                owner="passenger-ic-2",
                seats=2,
            )

    def test_transit_ticket_issue_and_validate(self):
        ticket = issue_transit_ticket(
            owner="passenger-pt-1",
            route_id=self.route.id,
            ticket_type=TransportTicket.TicketType.QR,
        )
        validated = validate_ticket(media_code=ticket.media_code)
        self.assertEqual(validated.id, ticket.id)


class EnterpriseEmergencyLogisticsTests(TestCase):
    def setUp(self):
        for mode, kind in [
            (TransportMode.AMBULANCE, TripKind.EMERGENCY),
            (TransportMode.VAN, TripKind.EMERGENCY),
            (TransportMode.DELIVERY_BIKE, TripKind.DELIVERY),
            (TransportMode.TRUCK, TripKind.DELIVERY),
        ]:
            _ensure_pricing(mode, kind)
        Station.objects.create(
            code="nat-ops-st",
            name="National Ops Station",
            latitude="-6.816100",
            longitude="39.280300",
            region="Dar es Salaam",
            district="Ilala",
            manager_principal="mgr-nat",
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
            service_radius_meters=100_000,
            active=True,
        )
        self.org = EnterpriseOrganization.objects.create(
            code="acme-tz",
            legal_name="ACME Tanzania",
            billing_account="acme-billing",
            organization_type="corporate",
            region="Dar es Salaam",
            policy={"allowed_departments": ["HR", "Ops"]},
            active=True,
        )
        EnterpriseEmployee.objects.create(
            organization=self.org,
            principal="employee-1",
            employee_code="E001",
            department="HR",
            active=True,
        )

    def test_enterprise_authorize(self):
        org = authorize_enterprise_trip(
            organization_code="acme-tz",
            employee_principal="employee-1",
            department="HR",
        )
        self.assertEqual(org.code, "acme-tz")
        with self.assertRaises(MobilityError):
            authorize_enterprise_trip(
                organization_code="acme-tz",
                employee_principal="employee-1",
                department="Finance",
            )

    def test_emergency_dispatch_creates_request(self):
        req = create_emergency_dispatch(
            requester="hospital-1",
            kind="ambulance",
            region="Dar es Salaam",
            pickup_name="Scene A",
            pickup_lat=Decimal("-6.816200"),
            pickup_lng=Decimal("39.280400"),
            dropoff_name="Muhimbili",
            dropoff_lat=Decimal("-6.807000"),
            dropoff_lng=Decimal("39.273000"),
            district="Ilala",
        )
        self.assertEqual(req.kind, "ambulance")
        self.assertIsNotNone(req.trip_id)
        self.assertIn(req.status, {"searching", "dispatched"})

    def test_logistics_shipment_courier(self):
        shipment = create_logistics_shipment(
            owner="shipper-1",
            category="courier",
            origin_name="Warehouse",
            origin_lat=Decimal("-6.816200"),
            origin_lng=Decimal("39.280400"),
            destination_name="Customer",
            destination_lat=Decimal("-6.820000"),
            destination_lng=Decimal("39.290000"),
            region="Dar es Salaam",
        )
        self.assertEqual(shipment.vehicle_mode, TransportMode.DELIVERY_BIKE)
        self.assertIsNotNone(shipment.trip_id)
        self.assertIsNotNone(shipment.delivery_id)

    def test_partner_credential_and_gov_adapter(self):
        cred, raw = create_partner_credential(
            partner_code="muni-dsm",
            legal_name="DSM Municipality",
            owner_principal="muni-admin",
        )
        self.assertTrue(raw)
        self.assertEqual(cred.api_key_prefix, raw[:12])
        self.assertTrue(
            PartnerApiCredential.objects.filter(partner_code="muni-dsm").exists()
        )
        adapter = government_adapter("LATRA")
        result = adapter.submit_transport_statistics(
            period_start="2026-01-01",
            period_end="2026-01-31",
            payload={"trips": 1},
        )
        self.assertTrue(result.accepted)
        self.assertIn("LATRA", result.reference)


class NationwideSimulationTests(TestCase):
    """Mass-scale simulation: many stations/regions without live network."""

    def setUp(self):
        _ensure_pricing(TransportMode.MOTORCYCLE, TripKind.PASSENGER)
        self.regions = [
            "Dar es Salaam",
            "Arusha",
            "Mwanza",
            "Dodoma",
            "Mbeya",
            "Morogoro",
            "Tanga",
            "Kilimanjaro",
        ]
        for i, region in enumerate(self.regions):
            for j in range(3):
                Station.objects.create(
                    code=f"sim-{region[:3].lower()}-{j}",
                    name=f"{region} Station {j}",
                    latitude=f"-{6 + i * 0.1:.6f}",
                    longitude=f"{35 + j * 0.1:.6f}",
                    region=region,
                    district=f"District {j}",
                    manager_principal=f"mgr-{i}-{j}",
                    verification_status=VerificationStatus.VERIFIED,
                    registry_approval_id=uuid.uuid4(),
                    service_radius_meters=80_000,
                    capacity=50,
                    active=True,
                )

    def test_national_command_center_scales_across_regions(self):
        payload = national_command_center()
        self.assertEqual(len(payload["regions"]), len(self.regions))
        self.assertEqual(payload["national"]["stations"], len(self.regions) * 3)
        self.assertEqual(len(payload["regional_kpis"]), len(self.regions))

    def test_gis_map_layers_per_region(self):
        layers = national_map_layers(region="Dar es Salaam")
        self.assertEqual(len(layers["layers"]), 1)
        self.assertEqual(layers["layers"][0]["region"], "Dar es Salaam")
        all_layers = national_map_layers()
        self.assertEqual(len(all_layers["layers"]), len(self.regions))
