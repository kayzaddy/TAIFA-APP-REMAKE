from rest_framework.test import APITestCase


class FoodOrderApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "food-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="food-device-1",
        )

    def test_create_and_pay_food_order(self):
        created = self.client.post(
            "/api/v1/commerce/food-orders",
            {
                "restaurant_id": "rst-spice",
                "restaurant_name": "Spice Bazaar",
                "subtotal_minor": 2150000,
                "delivery_fee_minor": 150000,
                "total_minor": 2300000,
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        oid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/food-orders/{oid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="food-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])
        listed = self.client.get("/api/v1/commerce/food-orders")
        self.assertEqual(len(listed.json()), 1)


class StayBookingApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "stay-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="stay-device-1",
        )

    def test_create_and_pay_stay_booking(self):
        created = self.client.post(
            "/api/v1/commerce/stay-bookings",
            {
                "hotel_id": "htl-hyatt",
                "hotel_name": "Hyatt Regency Dar",
                "room_name": "King Harbour View",
                "check_in": "2026-08-01",
                "check_out": "2026-08-03",
                "guests": 2,
                "nights": 2,
                "nightly_rate_minor": 32000000,
                "taxes_minor": 6400000,
                "total_minor": 70400000,
                "confirmation_code": "TAF-100137",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        bid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/stay-bookings/{bid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="stay-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])
        listed = self.client.get("/api/v1/commerce/stay-bookings")
        self.assertEqual(len(listed.json()), 1)


class FlightBookingApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "flt-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="flt-device-1",
        )

    def test_create_and_pay_flight_booking(self):
        created = self.client.post(
            "/api/v1/commerce/flight-bookings",
            {
                "airline": "Precision Air",
                "flight_number": "PW 401",
                "origin_code": "DAR",
                "destination_code": "ZNZ",
                "depart_at": "2026-08-10T07:30:00Z",
                "passengers": 1,
                "total_minor": 14500000,
                "pnr": "TA1041A",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        bid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/flight-bookings/{bid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="flt-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])


class TourBookingApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "tour-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="tour-device-1",
        )

    def test_create_and_pay_tour_booking(self):
        created = self.client.post(
            "/api/v1/commerce/tour-bookings",
            {
                "tour_id": "tour-stone",
                "tour_title": "Stone Town Heritage Walk",
                "experience_date": "2026-08-12",
                "guests": 2,
                "total_minor": 13000000,
                "confirmation_code": "EXP-200173",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        bid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/tour-bookings/{bid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="tour-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])


class WingaCommerceApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "winga-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="winga-device-1",
        )

    def test_winga_order_service_and_shop(self):
        order = self.client.post(
            "/api/v1/commerce/winga-orders",
            {
                "total_minor": 45000000,
                "item_count": 2,
                "summary": "Fridge + blender",
                "payment_ref": "WINGA-1",
            },
            format="json",
        )
        self.assertEqual(order.status_code, 201)
        oid = order.json()["id"]
        patched = self.client.patch(
            f"/api/v1/commerce/winga-orders/{oid}",
            {"status": "delivering", "courier_name": "Juma", "eta_label": "25 min"},
            format="json",
        )
        self.assertEqual(patched.status_code, 200)
        self.assertEqual(patched.json()["status"], "delivering")

        svc = self.client.post(
            "/api/v1/commerce/winga-service-bookings",
            {
                "service_id": "svc-ac",
                "service_title": "AC Service",
                "slot_label": "Today · 3–5 pm",
                "total_minor": 7500000,
            },
            format="json",
        )
        self.assertEqual(svc.status_code, 201)

        shop = self.client.post(
            "/api/v1/commerce/winga-shops",
            {"name": "Dar Gadgets", "category": "Electronics", "address": "Kariakoo"},
            format="json",
        )
        self.assertEqual(shop.status_code, 201)
        self.assertEqual(shop.json()["status"], "approved")


class GovRequestApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "gov-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="gov-device-1",
        )

    def test_create_and_pay_gov_request(self):
        created = self.client.post(
            "/api/v1/commerce/gov-requests",
            {
                "service_id": "gov-nida",
                "service_title": "NIDA ID replacement",
                "agency": "NIDA",
                "category": "Identity",
                "applicant_name": "Amani Juma",
                "fee_minor": 2500000,
                "eta_days": 14,
                "reference": "GVR-200017",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "in_review")
        rid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/gov-requests/{rid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="gov-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])
        listed = self.client.get("/api/v1/commerce/gov-requests")
        self.assertEqual(len(listed.json()), 1)


class HealthAppointmentApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "health-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="health-device-1",
        )

    def test_create_and_pay_health_appointment(self):
        created = self.client.post(
            "/api/v1/commerce/health-appointments",
            {
                "facility_id": "hlt-muhimbili",
                "facility_name": "Muhimbili OPD",
                "specialty": "General",
                "area": "Upanga",
                "patient_name": "Amani Juma",
                "slot_at": "2026-08-10T09:30:00Z",
                "fee_minor": 3500000,
                "confirmation_code": "HL-1013",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "confirmed")
        aid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/health-appointments/{aid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="hlt-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])
        listed = self.client.get("/api/v1/commerce/health-appointments")
        self.assertEqual(len(listed.json()), 1)


class EduPaymentApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "edu-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="edu-device-1",
        )

    def test_create_and_pay_edu_payment(self):
        created = self.client.post(
            "/api/v1/commerce/edu-payments",
            {
                "school_id": "edu-agakhan",
                "school_name": "Aga Khan Primary",
                "level": "Primary",
                "area": "Upanga",
                "student_name": "Neema Juma",
                "amount_minor": 85000000,
                "invoice_no": "INV-EDU-3001",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "invoiced")
        pid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/edu-payments/{pid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="edu-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "paid")
        self.assertTrue(paid.json()["payment_ref"])


class HousingInquiryApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "housing-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="housing-device-1",
        )

    def test_create_and_pay_housing_inquiry(self):
        created = self.client.post(
            "/api/v1/commerce/housing-inquiries",
            {
                "listing_id": "hs-masaki",
                "listing_title": "2BR Masaki flat",
                "area": "Masaki",
                "beds": 2,
                "baths": 2,
                "monthly_rent_minor": 120000000,
                "deposit_minor": 240000000,
                "viewing_at": "2026-08-12T15:00:00Z",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "scheduled")
        iid = created.json()["id"]
        paid = self.client.post(
            f"/api/v1/commerce/housing-inquiries/{iid}/pay",
            {},
            format="json",
            HTTP_IDEMPOTENCY_KEY="hsg-pay-1",
        )
        self.assertEqual(paid.status_code, 200)
        self.assertEqual(paid.json()["status"], "deposit_paid")
        self.assertTrue(paid.json()["payment_ref"])


class WealthContributionApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "wealth-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="wealth-device-1",
        )

    def test_create_wealth_contribution(self):
        created = self.client.post(
            "/api/v1/commerce/wealth-contributions",
            {
                "circle_id": "hrb-family",
                "circle_name": "Family Harambee",
                "purpose": "School fees",
                "amount_minor": 5000000,
                "payment_ref": "HRB-1",
                "status": "paid",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "paid")
        listed = self.client.get("/api/v1/commerce/wealth-contributions")
        self.assertEqual(len(listed.json()), 1)


class JobAssignmentApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "jobs-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="jobs-device-1",
        )

    def test_accept_and_advance_job(self):
        created = self.client.post(
            "/api/v1/commerce/job-assignments",
            {
                "job_id": "job-move",
                "job_title": "Apartment move assist",
                "area": "Mikocheni",
                "kind": "gig",
                "summary": "Help load a truck",
                "pay_minor": 2500000,
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "accepted")
        aid = created.json()["id"]
        advanced = self.client.patch(
            f"/api/v1/commerce/job-assignments/{aid}",
            {"status": "in_progress"},
            format="json",
        )
        self.assertEqual(advanced.status_code, 200)
        self.assertEqual(advanced.json()["status"], "in_progress")
        paid = self.client.patch(
            f"/api/v1/commerce/job-assignments/{aid}",
            {"status": "paid", "payment_ref": "JOB-1"},
            format="json",
        )
        # Money fields are server-authored; forging paid must fail.
        self.assertEqual(paid.status_code, 400)
        completed = self.client.patch(
            f"/api/v1/commerce/job-assignments/{aid}",
            {"status": "completed"},
            format="json",
        )
        self.assertEqual(completed.status_code, 200)
        self.assertEqual(completed.json()["status"], "completed")


class InsurancePolicyApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "ins-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="ins-device-1",
        )

    def test_buy_insurance_policy(self):
        created = self.client.post(
            "/api/v1/commerce/insurance-policies",
            {
                "plan_id": "ins-health",
                "plan_name": "Family Health",
                "provider": "Jubilee",
                "category": "Health",
                "premium_minor": 4500000,
                "coverage_minor": 500000000,
                "policy_ref": "POL-1",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "active")


class FamilyTransferApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "fam-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="fam-device-1",
        )

    def test_send_family_transfer(self):
        created = self.client.post(
            "/api/v1/commerce/family-transfers",
            {
                "member_id": "fam-neema",
                "member_name": "Neema Juma",
                "member_role": "Daughter",
                "member_phone": "+255700000001",
                "kind": "send",
                "amount_minor": 2000000,
                "note": "Weekly allowance",
                "payment_ref": "FAM-1",
                "status": "paid",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "paid")


class HudumaBookingApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "hdm-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="hdm-device-1",
        )

    def test_book_huduma_service(self):
        created = self.client.post(
            "/api/v1/commerce/huduma-bookings",
            {
                "service_id": "hdm-clean",
                "service_title": "Home cleaning",
                "category": "Cleaning",
                "provider": "Safisha Co",
                "slot_label": "Tomorrow · 10 am",
                "price_minor": 3500000,
                "payment_ref": "HDM-1",
                "status": "paid",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        self.assertEqual(created.json()["status"], "paid")

class MerchantOrderApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "merchant-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="merchant-device-1",
        )

    def test_create_and_advance_merchant_order(self):
        created = self.client.post(
            "/api/v1/commerce/merchant-orders",
            {
                "customer_name": "Neema K.",
                "items_label": "2x Mishkaki · Pilau",
                "total_minor": 3350000,
                "status": "new",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        oid = created.json()["id"]
        advanced = self.client.patch(
            f"/api/v1/commerce/merchant-orders/{oid}",
            {"status": "preparing"},
            format="json",
        )
        self.assertEqual(advanced.status_code, 200)
        self.assertEqual(advanced.json()["status"], "preparing")


class DriverJobApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "driver-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="driver-device-1",
        )

    def test_create_and_update_driver_job(self):
        created = self.client.post(
            "/api/v1/commerce/driver-jobs",
            {
                "rider_name": "Amani J.",
                "pickup": "Mikocheni B",
                "dropoff": "Masaki",
                "fare_minor": 850000,
                "eta_minutes": 6,
                "status": "offered",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        jid = created.json()["id"]
        updated = self.client.patch(
            f"/api/v1/commerce/driver-jobs/{jid}",
            {"status": "accepted"},
            format="json",
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.json()["status"], "accepted")

class ChatApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "chat-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="chat-device-1",
        )

    def test_thread_and_message(self):
        thread = self.client.post(
            "/api/v1/commerce/chat-threads",
            {"title": "Driver", "subtitle": "Hi", "unread": 1},
            format="json",
        )
        self.assertEqual(thread.status_code, 201)
        tid = thread.json()["id"]
        msg = self.client.post(
            f"/api/v1/commerce/chat-threads/{tid}/messages",
            {"sender": "me", "text": "Niko njiani"},
            format="json",
        )
        self.assertEqual(msg.status_code, 201)
        listed = self.client.get(f"/api/v1/commerce/chat-threads/{tid}/messages")
        self.assertEqual(len(listed.json()), 1)
        refreshed = self.client.get(f"/api/v1/commerce/chat-threads/{tid}")
        self.assertEqual(refreshed.json()["subtitle"], "Niko njiani")


class AdminCaseApiTests(APITestCase):
    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "admin-device-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="admin-device-1",
        )

    def test_create_and_advance_admin_case(self):
        created = self.client.post(
            "/api/v1/commerce/admin-cases",
            {
                "kind": "kyc",
                "title": "NIDA KYC review",
                "subject": "Fatuma Ally",
                "detail": "Mismatch score 0.62",
                "status": "open",
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        cid = created.json()["id"]
        advanced = self.client.patch(
            f"/api/v1/commerce/admin-cases/{cid}",
            {"status": "reviewing"},
            format="json",
        )
        self.assertEqual(advanced.status_code, 200)
        self.assertEqual(advanced.json()["status"], "reviewing")


class CommerceMoneyIntegrityTests(APITestCase):
    """P0: clients cannot forge paid / payment_ref via PATCH."""

    def setUp(self):
        reg = self.client.post(
            "/api/v1/auth/device/register",
            {"device_id": "money-integrity-1", "platform": "test"},
            format="json",
        ).json()
        self.client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="money-integrity-1",
        )

    def test_patch_paid_rejected(self):
        created = self.client.post(
            "/api/v1/commerce/food-orders",
            {
                "restaurant_id": "rst-1",
                "restaurant_name": "Test",
                "subtotal_minor": 100000,
                "delivery_fee_minor": 0,
                "total_minor": 100000,
            },
            format="json",
        )
        self.assertEqual(created.status_code, 201)
        oid = created.json()["id"]
        forged = self.client.patch(
            f"/api/v1/commerce/food-orders/{oid}",
            {"status": "paid", "payment_ref": "FORGED"},
            format="json",
        )
        self.assertEqual(forged.status_code, 400)
        detail = forged.json()
        self.assertTrue(detail)

