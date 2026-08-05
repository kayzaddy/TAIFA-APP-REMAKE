from datetime import timedelta
import uuid

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient, APITestCase

from enterprise.models import Merchant, MerchantStatus, PlatformPrincipal, PlatformRole
from payments.engine import default_engine
from payments.money import Currency, Money
from payments.reconciliation import run_reconciliation

from .models import (
    DispatchOfferStatus,
    Driver,
    DriverAvailability,
    DriverLocation,
    DriverStatus,
    PricingRule,
    Promotion,
    SafetyIncident,
    Station,
    StationQueueEntry,
    TransportMode,
    Trip,
    TripStatus,
    Vehicle,
    VehicleStatus,
    VerificationStatus,
)
from .services import (
    MobilityError,
    accept_offer,
    collect_trip_payment,
    create_trip,
    dispatch_trip,
    quote_fare,
    transition_trip,
)


class TripApiTests(APITestCase):
    def setUp(self):
        Station.objects.create(
            code="api-approved-station",
            name="API Approved Station",
            latitude="-6.800000",
            longitude="39.240000",
            region="Dar es Salaam",
            district="Kinondoni",
            manager_principal="manager-api",
            service_radius_meters=100_000,
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "trip-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="trip-device-1",
        )

    def test_create_and_list_trips(self):
        created = self.client.post(
            "/api/v1/trips/",
            {
                "pickup_name": "Masaki",
                "pickup_lat": -6.75,
                "pickup_lng": 39.28,
                "dropoff_name": "Airport",
                "dropoff_lat": -6.88,
                "dropoff_lng": 39.20,
                "vehicle_mode": "motorcycle",
                "region": "Dar es Salaam",
                "estimated_distance_meters": 12000,
                "estimated_duration_seconds": 1200,
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        trip_id = created.json()["id"]
        self.assertGreater(created.json()["fare_minor"], 0)
        self.assertNotIn("fare_minor", {
            "pickup_name": "Masaki",
            "vehicle_mode": "motorcycle",
        })

        patched = self.client.patch(
            f"/api/v1/trips/{trip_id}",
            {"status": "cancelled", "metadata": {"reason": "customer changed plans"}},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        self.assertEqual(patched.json()["status"], "cancelled")

        listed = self.client.get("/api/v1/trips/")
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(len(listed.json()), 1)

    def test_client_cannot_submit_or_override_fare(self):
        response = self.client.post(
            "/api/v1/trips/",
            {
                "pickup_name": "A",
                "pickup_lat": -6.8,
                "pickup_lng": 39.2,
                "dropoff_name": "B",
                "dropoff_lat": -6.9,
                "dropoff_lng": 39.3,
                "vehicle_mode": "motorcycle",
                "estimated_distance_meters": 1000,
                "estimated_duration_seconds": 300,
                "fare_minor": 1,
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertNotEqual(response.json()["fare_minor"], 1)


class MobilityDispatchTests(TestCase):
    def setUp(self):
        self.station = Station.objects.create(
            code="kariakoo-boda",
            name="Kariakoo Bodaboda Station",
            latitude="-6.816100",
            longitude="39.280300",
            region="Dar es Salaam",
            district="Ilala",
            ward="Kariakoo",
            manager_principal="station-manager",
            service_radius_meters=10_000,
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        self.driver = Driver.objects.create(
            owner_principal="driver-1",
            full_name="Juma Mussa",
            status=DriverStatus.ACTIVE,
            availability=DriverAvailability.AVAILABLE,
            identity_status=VerificationStatus.VERIFIED,
            license_status=VerificationStatus.VERIFIED,
            station=self.station,
            registry_approval_id=uuid.uuid4(),
        )
        self.vehicle = Vehicle.objects.create(
            registration_number="MC-123-ABC",
            mode=TransportMode.MOTORCYCLE,
            owner_principal="driver-1",
            assigned_driver=self.driver,
            status=VehicleStatus.ACTIVE,
            insurance_status=VerificationStatus.VERIFIED,
            road_license_status=VerificationStatus.VERIFIED,
            inspection_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        DriverLocation.objects.create(
            driver=self.driver,
            latitude="-6.816000",
            longitude="39.280000",
            recorded_at=timezone.now(),
        )
        StationQueueEntry.objects.create(
            station=self.station,
            driver=self.driver,
            position=1,
        )

    def _trip(self):
        return create_trip(
            owner="customer-1",
            pickup_name="Kariakoo",
            pickup_lat="-6.816200",
            pickup_lng="39.280400",
            dropoff_name="Posta",
            dropoff_lat="-6.820000",
            dropoff_lng="39.290000",
            vehicle_mode=TransportMode.MOTORCYCLE,
            region="Dar es Salaam",
            estimated_distance_meters=2500,
            estimated_duration_seconds=600,
            actor="customer-1",
        )

    def test_station_first_dispatch_and_driver_acceptance(self):
        trip = self._trip()
        self.assertEqual(trip.station, self.station)
        offers = dispatch_trip(trip.id)
        self.assertEqual(len(offers), 1)
        self.assertEqual(offers[0].driver, self.driver)
        trip = accept_offer(offers[0].id, driver=self.driver)
        self.assertEqual(trip.status, TripStatus.DRIVER_ASSIGNED)
        self.assertEqual(trip.vehicle, self.vehicle)
        self.assertEqual(
            self.driver.dispatch_offers.get().status,
            DispatchOfferStatus.ACCEPTED,
        )

    def test_reject_offer_triggers_redispatch(self):
        from .services import reject_offer

        driver_two = Driver.objects.create(
            owner_principal="driver-reject-2",
            full_name="Asha Reject",
            status=DriverStatus.ACTIVE,
            availability=DriverAvailability.AVAILABLE,
            identity_status=VerificationStatus.VERIFIED,
            license_status=VerificationStatus.VERIFIED,
            station=self.station,
            registry_approval_id=uuid.uuid4(),
        )
        Vehicle.objects.create(
            registration_number="MC-REJECT-2",
            mode=TransportMode.MOTORCYCLE,
            owner_principal="driver-reject-2",
            assigned_driver=driver_two,
            status=VehicleStatus.ACTIVE,
            insurance_status=VerificationStatus.VERIFIED,
            road_license_status=VerificationStatus.VERIFIED,
            inspection_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        DriverLocation.objects.create(
            driver=driver_two,
            latitude="-6.816100",
            longitude="39.280100",
            recorded_at=timezone.now(),
        )
        StationQueueEntry.objects.create(
            station=self.station,
            driver=driver_two,
            position=2,
        )
        trip = self._trip()
        offers = dispatch_trip(trip.id)
        first = next(o for o in offers if o.driver_id == self.driver.id)
        reject_offer(first.id, driver=self.driver, reason="busy")
        trip.refresh_from_db()
        self.assertEqual(trip.status, TripStatus.SEARCHING)
        self.assertTrue(
            trip.offers.filter(status=DispatchOfferStatus.PENDING).exists()
        )

    def test_queue_reorder_requires_manager(self):
        from .services import reorder_station_queue

        driver_two = Driver.objects.create(
            owner_principal="driver-queue-2",
            full_name="Queue Two",
            status=DriverStatus.ACTIVE,
            availability=DriverAvailability.AVAILABLE,
            identity_status=VerificationStatus.VERIFIED,
            license_status=VerificationStatus.VERIFIED,
            station=self.station,
            registry_approval_id=uuid.uuid4(),
        )
        StationQueueEntry.objects.create(
            station=self.station,
            driver=driver_two,
            position=2,
        )
        with self.assertRaises(MobilityError):
            reorder_station_queue(
                station=self.station,
                ordered_driver_ids=[driver_two.id, self.driver.id],
                actor="not-the-manager",
            )
        entries = reorder_station_queue(
            station=self.station,
            ordered_driver_ids=[driver_two.id, self.driver.id],
            actor="station-manager",
        )
        self.assertEqual(entries[0].driver_id, driver_two.id)
        self.assertEqual(entries[0].position, 1)

    def test_lifecycle_rejects_illegal_transition(self):
        trip = self._trip()
        with self.assertRaises(MobilityError):
            transition_trip(
                trip.id,
                to_status=TripStatus.COMPLETED,
                actor="customer-1",
            )

    def test_first_accept_wins_and_releases_losing_driver(self):
        driver_two = Driver.objects.create(
            owner_principal="driver-2",
            full_name="Asha Said",
            status=DriverStatus.ACTIVE,
            availability=DriverAvailability.AVAILABLE,
            identity_status=VerificationStatus.VERIFIED,
            license_status=VerificationStatus.VERIFIED,
            station=self.station,
            registry_approval_id=uuid.uuid4(),
        )
        Vehicle.objects.create(
            registration_number="MC-456-XYZ",
            mode=TransportMode.MOTORCYCLE,
            owner_principal="driver-2",
            assigned_driver=driver_two,
            status=VehicleStatus.ACTIVE,
            insurance_status=VerificationStatus.VERIFIED,
            road_license_status=VerificationStatus.VERIFIED,
            inspection_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        DriverLocation.objects.create(
            driver=driver_two,
            latitude="-6.816300",
            longitude="39.280500",
            recorded_at=timezone.now(),
        )
        StationQueueEntry.objects.create(
            station=self.station,
            driver=driver_two,
            position=2,
        )
        offers = dispatch_trip(self._trip().id)
        first = next(o for o in offers if o.driver_id == self.driver.id)
        second = next(o for o in offers if o.driver_id == driver_two.id)
        accept_offer(first.id, driver=self.driver)
        with self.assertRaises(MobilityError):
            accept_offer(second.id, driver=driver_two)
        driver_two.refresh_from_db()
        second.refresh_from_db()
        self.assertEqual(second.status, DispatchOfferStatus.CANCELLED)
        self.assertEqual(driver_two.availability, DriverAvailability.AVAILABLE)

    def test_pricing_is_versioned_and_configurable(self):
        quote = quote_fare(
            vehicle_mode=TransportMode.MOTORCYCLE,
            trip_kind="passenger",
            region="Dar es Salaam",
            distance_meters=10000,
            duration_seconds=1200,
            at=timezone.now(),
        )
        self.assertGreater(quote.total_minor, 0)
        self.assertEqual(quote.rule_version, 1)

    def test_promotion_is_bounded_and_snapshotted(self):
        now = timezone.now()
        Promotion.objects.create(
            code="PILOT10",
            discount_bps=1000,
            maximum_discount_minor=50_000,
            region="Dar es Salaam",
            active=True,
            starts_at=now - timedelta(hours=1),
            ends_at=now + timedelta(hours=1),
        )
        trip = create_trip(
            owner="customer-2",
            pickup_name="Kariakoo",
            pickup_lat="-6.816200",
            pickup_lng="39.280400",
            dropoff_name="Posta",
            dropoff_lat="-6.820000",
            dropoff_lng="39.290000",
            vehicle_mode="motorcycle",
            region="Dar es Salaam",
            estimated_distance_meters=2500,
            estimated_duration_seconds=600,
            promo_code="pilot10",
        )
        self.assertEqual(
            trip.fare_breakdown["promotion_code"],
            "PILOT10",
        )
        self.assertLessEqual(
            trip.fare_breakdown["promotion_discount_minor"],
            50_000,
        )


class MobilityPaymentDelegationTests(TestCase):
    def setUp(self):
        self.merchant = Merchant.objects.create(
            code="mobility-station-merchant",
            legal_name="Mobility Station Cooperative",
            status=MerchantStatus.ACTIVE,
            fee_bps=0,
        )
        self.station = Station.objects.create(
            code="mwenge",
            name="Mwenge Station",
            latitude="-6.770000",
            longitude="39.220000",
            region="Dar es Salaam",
            district="Kinondoni",
            manager_principal="manager-1",
            payment_merchant=self.merchant,
            verification_status=VerificationStatus.VERIFIED,
            registry_approval_id=uuid.uuid4(),
        )
        default_engine().open_wallet(
            "mobility-payer",
            Money.major(100_000, Currency.TZS),
        )

    def test_wallet_payment_uses_existing_payment_transaction(self):
        trip = create_trip(
            owner="mobility-payer",
            pickup_name="Mwenge",
            pickup_lat="-6.770000",
            pickup_lng="39.220000",
            dropoff_name="Mlimani City",
            dropoff_lat="-6.771000",
            dropoff_lng="39.230000",
            vehicle_mode="motorcycle",
            region="Dar es Salaam",
            estimated_distance_meters=2000,
            estimated_duration_seconds=600,
        )
        Trip.objects.filter(pk=trip.pk).update(
            station=self.station,
            status=TripStatus.COMPLETED,
        )
        trip = collect_trip_payment(
            trip.id,
            actor="mobility-payer",
            idempotency_key="mobility-pay-1",
        )
        self.assertEqual(trip.status, TripStatus.PAYMENT_CONFIRMED)
        self.assertIsNotNone(trip.payment_transaction_id)
        self.assertIsNotNone(trip.payment_transaction.ledger_entry_id)
        self.assertTrue(run_reconciliation(record=True).ok)

    def test_cash_does_not_mint_or_fake_payment(self):
        trip = create_trip(
            owner="mobility-payer",
            pickup_name="Mwenge",
            pickup_lat="-6.770000",
            pickup_lng="39.220000",
            dropoff_name="Mlimani City",
            dropoff_lat="-6.771000",
            dropoff_lng="39.230000",
            vehicle_mode="motorcycle",
            region="Dar es Salaam",
            estimated_distance_meters=2000,
            estimated_duration_seconds=600,
            payment_method="cash",
        )
        Trip.objects.filter(pk=trip.pk).update(
            station=self.station,
            status=TripStatus.COMPLETED,
        )
        trip = collect_trip_payment(
            trip.id,
            actor="mobility-payer",
            idempotency_key="cash-does-not-post",
        )
        self.assertEqual(trip.status, TripStatus.PAYMENT_PENDING)
        self.assertIsNone(trip.payment_transaction_id)


class MobilityOperatorSecurityTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "ops-device", "platform": "test"},
            format="json",
        ).json()
        self.owner = reg["owner"]
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="ops-device",
        )

    def test_ops_dashboard_requires_enterprise_role(self):
        denied = self.client.get("/api/v1/trips/operations/dashboard")
        self.assertEqual(denied.status_code, 403)
        role = PlatformRole.objects.create(
            code="mobility-ops",
            name="Mobility Operations",
            permissions=["mobility.operations"],
        )
        principal = PlatformPrincipal.objects.create(
            principal_id=self.owner,
            display_name="Ops",
        )
        principal.roles.add(role)
        allowed = self.client.get("/api/v1/trips/operations/dashboard")
        self.assertEqual(allowed.status_code, 200)

    def test_sos_is_persisted(self):
        response = self.client.post(
            "/api/v1/trips/safety/incidents",
            {
                "kind": "sos",
                "severity": "critical",
                "latitude": "-6.8",
                "longitude": "39.2",
                "details": {"silent": True},
            },
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(SafetyIncident.objects.count(), 1)
