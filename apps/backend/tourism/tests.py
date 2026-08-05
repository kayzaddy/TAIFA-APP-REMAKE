"""Tourism DTOS API tests."""
from __future__ import annotations

from django.test import TestCase
from rest_framework.test import APITestCase


class TourismTripApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "tourism-trip-device", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="tourism-trip-device",
        )

    def test_create_plan_select_itinerary(self):
        created = self.client.post(
            "/api/v1/tourism/trips",
            {"title": "Family safari", "party_size": 4, "budget_tier": "luxury"},
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        trip_id = created.json()["id"]

        planned = self.client.post(
            f"/api/v1/tourism/trips/{trip_id}/plan",
            {
                "interests": ["safari", "beach"],
                "start_date": "2026-09-01",
            },
            format="json",
        )
        self.assertEqual(planned.status_code, 200)
        itineraries = planned.json()["itineraries"]
        self.assertGreaterEqual(len(itineraries), 2)
        self.assertTrue(itineraries[0]["days"])

        iid = itineraries[0]["id"]
        selected = self.client.post(
            f"/api/v1/tourism/trips/{trip_id}/itineraries/{iid}/select",
            {},
            format="json",
        )
        self.assertEqual(selected.status_code, 200)
        self.assertEqual(selected.json()["status"], "ready")
        self.assertEqual(selected.json()["selected_itinerary_id"], iid)

    def test_attach_tour_booking(self):
        trip = self.client.post("/api/v1/tourism/trips", {}, format="json").json()
        tour = self.client.post(
            "/api/v1/commerce/tour-bookings",
            {
                "tour_id": "tour-serengeti",
                "tour_title": "Serengeti Day Flight Safari",
                "experience_date": "2026-09-03",
                "guests": 2,
                "total_minor": 89000000,
            },
            format="json",
        )
        self.assertEqual(tour.status_code, 201)
        attached = self.client.post(
            f"/api/v1/tourism/trips/{trip['id']}/attach-booking",
            {"booking_type": "tour", "booking_id": tour.json()["id"]},
            format="json",
        )
        self.assertEqual(attached.status_code, 200)
        self.assertIn(tour.json()["id"], attached.json()["tour_booking_ids"])

    def test_cart_checkout_pay_with_insurance(self):
        trip = self.client.post(
            "/api/v1/tourism/trips",
            {"party_size": 2},
            format="json",
        ).json()
        tour = self.client.post(
            "/api/v1/commerce/tour-bookings",
            {
                "tour_id": "tour-stone",
                "tour_title": "Stone Town Walk",
                "experience_date": "2026-09-03",
                "guests": 2,
                "total_minor": 6500000,
            },
            format="json",
        ).json()
        self.client.post(
            f"/api/v1/tourism/trips/{trip['id']}/attach-booking",
            {"booking_type": "tour", "booking_id": tour["id"]},
            format="json",
        )

        cart = self.client.post(
            f"/api/v1/tourism/trips/{trip['id']}/cart/build",
            {},
            format="json",
        )
        self.assertEqual(cart.status_code, 200)
        body = cart.json()
        self.assertGreater(body["travel_subtotal_minor"], 0)
        self.assertIsNotNone(body.get("insurance_quote"))

        checkout = self.client.post(
            f"/api/v1/tourism/trips/{trip['id']}/checkout",
            {"include_insurance": True},
            format="json",
        )
        self.assertEqual(checkout.status_code, 201)
        self.assertTrue(checkout.json()["include_insurance"])
        self.assertGreater(checkout.json()["protection_subtotal_minor"], 0)

        paid = self.client.post(
            f"/api/v1/tourism/trips/{trip['id']}/checkout/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="tourism-checkout-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])
        self.assertIsNotNone(paid.json()["insurance_policy_id"])

        trip_detail = self.client.get(f"/api/v1/tourism/trips/{trip['id']}")
        self.assertEqual(trip_detail.json()["status"], "active")

    def test_assist_sos_creates_incident(self):
        trip = self.client.post("/api/v1/tourism/trips", {}, format="json").json()
        sos = self.client.post(
            "/api/v1/tourism/assist/sos",
            {"trip_id": trip["id"], "latitude": -6.79, "longitude": 39.28, "notes": "Need help"},
            format="json",
        )
        self.assertEqual(sos.status_code, 201)
        self.assertIsNotNone(sos.json()["safety_incident_id"])

        nearby = self.client.get("/api/v1/tourism/assist/nearby")
        self.assertEqual(nearby.status_code, 200)
        self.assertGreaterEqual(len(nearby.json()["places"]), 2)

    def test_cart_includes_esim_quote(self):
        trip = self.client.post("/api/v1/tourism/trips", {}, format="json").json()
        cart = self.client.post(
            f"/api/v1/tourism/trips/{trip['id']}/cart/build",
            {},
            format="json",
        ).json()
        self.assertIsNotNone(cart.get("esim_quote"))
        self.assertGreater(cart.get("connectivity_subtotal_minor", 0), 0)


class TourismServiceTests(TestCase):
    def test_generate_itineraries(self):
        from tourism.models import TourismTrip
        from tourism.services import generate_itinerary_options

        trip = TourismTrip.objects.create(owner="u1", interests=["safari"])
        rows = generate_itinerary_options(trip=trip)
        self.assertGreaterEqual(len(rows), 2)
