from __future__ import annotations

from django.test import TestCase
from rest_framework.test import APIClient


class MerchantFoundationSprint1Tests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.base = "/api/v1/merchant-app"

    def _signup_login_register(self):
        signup = self.client.post(
            f"{self.base}/auth/signup",
            {"email": "owner@shop.test", "password": "securepass1", "full_name": "Amina"},
            format="json",
        )
        self.assertEqual(signup.status_code, 200)
        token = signup.json()["access_token"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        reg = self.client.post(
            f"{self.base}/merchants/register",
            {"legal_name": "Kariakoo Cosmetics", "city": "Dar es Salaam", "business_category": "retail"},
            format="json",
        )
        self.assertEqual(reg.status_code, 201)
        login = self.client.post(
            f"{self.base}/auth/login",
            {"email": "owner@shop.test", "password": "securepass1"},
            format="json",
        )
        self.assertEqual(login.status_code, 200)
        self.assertIsNotNone(login.json().get("merchant_id"))
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.json()['access_token']}")
        return login.json()

    def test_signup_login_merchant_dashboard(self):
        self._signup_login_register()
        dash = self.client.get(f"{self.base}/dashboard")
        self.assertEqual(dash.status_code, 200)
        self.assertEqual(dash.json()["business_status"], "pending_verification")
        self.assertEqual(dash.json()["placeholders"]["qr"], "coming_sprint_3")

    def test_branch_employee_device_flow(self):
        self._signup_login_register()
        branch = self.client.post(
            f"{self.base}/branches",
            {"name": "HQ", "code": "hq", "city": "Dar"},
            format="json",
        )
        self.assertEqual(branch.status_code, 201)
        invite = self.client.post(
            f"{self.base}/employees",
            {"email": "cashier@shop.test", "full_name": "Neema", "role": "cashier"},
            format="json",
        )
        self.assertEqual(invite.status_code, 201)
        device = self.client.post(
            f"{self.base}/devices",
            {"name": "Counter Phone", "device_type": "mobile", "branch_id": branch.json()["id"]},
            format="json",
        )
        self.assertEqual(device.status_code, 201)
        activated = self.client.post(f"{self.base}/devices/{device.json()['id']}/activate")
        self.assertEqual(activated.status_code, 200)
        self.assertEqual(activated.json()["status"], "active")

    def test_no_payment_endpoints(self):
        """Sprint 1 must not expose payment acceptance APIs."""
        self.assertNotIn("acceptance", str(__import__("taifa_merchant.urls", fromlist=["urlpatterns"]).urlpatterns))
