"""Taifa Mobility Hybrid Dispatch tests."""
from __future__ import annotations

from django.core.management import call_command
from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APITestCase

from mobility_channels import services
from mobility_channels.models import DeviceCapability, DriverChannelBinding
from trips.models import DispatchOffer, DispatchOfferStatus, Driver, Trip, TripStatus
from trips.services import create_trip


class HybridDispatchServiceTests(TestCase):
    def setUp(self):
        call_command("seed_mobility")

    def test_select_channel_smartphone(self):
        driver = Driver.objects.filter(status="active").first()
        binding = services.ensure_binding(
            driver=driver,
            msisdn="+255712345678",
            device_capability=DeviceCapability.SMARTPHONE,
            has_internet=True,
        )
        plan = services.select_channel(binding)
        self.assertEqual(plan.channel, "push")

    def test_select_channel_feature_phone(self):
        driver = Driver.objects.filter(status="active").first()
        binding = services.ensure_binding(
            driver=driver,
            msisdn="+255798765432",
            device_capability=DeviceCapability.FEATURE_PHONE,
            has_internet=False,
            has_gps=False,
        )
        plan = services.select_channel(binding)
        self.assertEqual(plan.channel, "sms")

    def test_parse_sms_accept_variants(self):
        self.assertEqual(services.parse_sms_response("YES"), "accept")
        self.assertEqual(services.parse_sms_response("1"), "accept")
        self.assertEqual(services.parse_sms_response("Two Milk"), "unknown")
        self.assertEqual(services.parse_sms_response("REGISTER JOHN MWENGE BOXER"), "register")

    def test_register_driver_sms(self):
        result = services.register_driver_sms(
            body="REGISTER JOHN MWENGE BOXER",
            msisdn="+255700000001",
        )
        self.assertEqual(result["status"], "registered")
        self.assertTrue(DriverChannelBinding.objects.filter(msisdn__contains="255700000001").exists())

    def test_ussd_accept_menu(self):
        driver = Driver.objects.filter(status="active").first()
        services.ensure_binding(
            driver=driver,
            msisdn="+255711122233",
            device_capability=DeviceCapability.FEATURE_PHONE,
            has_internet=False,
        )
        root = services.handle_ussd(msisdn="+255711122233", text="")
        self.assertIn("Taifa Mobility", root)
        self.assertIn("Accept Ride", root)

    def test_boarding_pin(self):
        trip = Trip.objects.first()
        if trip is None:
            self.skipTest("no trips")
        pin = services.generate_boarding_pin(trip=trip)
        self.assertEqual(len(pin), 6)
        self.assertTrue(services.verify_boarding_pin(trip=trip, pin=pin))


class HybridDispatchApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility")
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "hybrid-passenger-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="hybrid-passenger-1",
        )
        self.owner = reg["owner"]

    def test_sms_inbound_webhook_register(self):
        res = self.client.post(
            "/api/v1/mobility-channels/webhooks/sms/inbound",
            {"from": "+255700000099", "text": "REGISTER ALI KIMARA BODA"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["status"], "registered")

    def test_ussd_webhook(self):
        res = self.client.post(
            "/api/v1/mobility-channels/webhooks/ussd",
            {"phoneNumber": "+255700000099", "text": ""},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        self.assertIn("Taifa Mobility", res.data["response"])

    def test_trip_hybrid_status(self):
        trip = create_trip(
            owner=self.owner,
            pickup_name="Mwenge",
            pickup_lat=-6.75,
            pickup_lng=39.25,
            dropoff_name="Masaki",
            dropoff_lat=-6.74,
            dropoff_lng=39.28,
            vehicle_mode="motorcycle",
            estimated_distance_meters=5000,
            estimated_duration_seconds=900,
        )
        trip.metadata = {"passenger_msisdn": "+255700111222"}
        trip.save(update_fields=["metadata", "updated_at"])
        res = self.client.get(f"/api/v1/mobility-channels/trips/{trip.id}/status")
        self.assertEqual(res.status_code, 200)
        self.assertIn("message", res.data)
