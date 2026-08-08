from __future__ import annotations

from django.test import TestCase
from rest_framework.test import APIClient


class MerchantWorkspaceSprint2Tests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.base = "/api/v1/merchant-app"

    def _bootstrap(self):
        signup = self.client.post(
            f"{self.base}/auth/signup",
            {"email": "s2@shop.test", "password": "securepass1", "full_name": "Juma"},
            format="json",
        )
        token = signup.json()["access_token"]
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
        reg = self.client.post(
            f"{self.base}/merchants/register",
            {"legal_name": "S2 Traders", "city": "Dar", "business_category": "retail"},
            format="json",
        )
        self.assertEqual(reg.status_code, 201)
        login = self.client.post(
            f"{self.base}/auth/login",
            {"email": "s2@shop.test", "password": "securepass1"},
            format="json",
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.json()['access_token']}")
        return login.json()

    def test_settings_and_notifications(self):
        self._bootstrap()
        settings = self.client.get(f"{self.base}/settings")
        self.assertEqual(settings.status_code, 200)
        self.assertEqual(settings.json()["currency"], "TZS")
        patch = self.client.patch(
            f"{self.base}/settings",
            {"language": "en", "payment_preferences": {"sprint3_ready": True}},
            format="json",
        )
        self.assertEqual(patch.status_code, 200)
        self.assertTrue(patch.json()["payment_preferences"]["sprint3_ready"])
        prefs = self.client.get(f"{self.base}/notifications/preferences")
        self.assertEqual(prefs.status_code, 200)
        notes = self.client.get(f"{self.base}/notifications")
        self.assertGreaterEqual(len(notes.json()), 1)

    def test_business_profile_and_dashboard_workspace(self):
        self._bootstrap()
        profile = self.client.patch(
            f"{self.base}/business-profile",
            {"description": "Neighborhood retail", "operating_hours": {"mon": "08:00-18:00"}},
            format="json",
        )
        self.assertEqual(profile.status_code, 200)
        dash = self.client.get(f"{self.base}/dashboard")
        self.assertEqual(dash.status_code, 200)
        body = dash.json()
        self.assertIn("activity_timeline", body)
        self.assertIn("merchant_health", body)
        self.assertEqual(body["placeholders"]["payments"], "coming_sprint_3")
        self.assertIn("pending_tasks", body)

    def test_branch_dashboard_employee_suspend_device_assign(self):
        self._bootstrap()
        branch = self.client.post(
            f"{self.base}/branches",
            {"name": "Main", "code": "main", "operating_hours": {"daily": "09:00-17:00"}},
            format="json",
        ).json()
        invite = self.client.post(
            f"{self.base}/employees",
            {"email": "mgr@shop.test", "full_name": "Manager", "role": "manager"},
            format="json",
        ).json()
        device = self.client.post(
            f"{self.base}/devices",
            {"name": "Pixel", "device_type": "android_phone", "branch_id": branch["id"]},
            format="json",
        ).json()
        assign = self.client.post(
            f"{self.base}/devices/{device['id']}/assign",
            {"branch_id": branch["id"], "assigned_employee_id": invite["id"]},
            format="json",
        )
        self.assertEqual(assign.status_code, 201)
        detail = self.client.get(f"{self.base}/devices/{device['id']}")
        self.assertEqual(detail.status_code, 200)
        self.assertIsNotNone(detail.json()["assignment"])
        branch_dash = self.client.get(f"{self.base}/branches/{branch['id']}/dashboard")
        self.assertEqual(branch_dash.status_code, 200)
        suspended = self.client.post(f"{self.base}/employees/{invite['id']}/suspend")
        self.assertEqual(suspended.status_code, 200)
        self.assertEqual(suspended.json()["status"], "suspended")

    def test_cashier_cannot_edit_settings(self):
        self._bootstrap()
        self.client.post(
            f"{self.base}/employees",
            {"email": "cash@shop.test", "full_name": "Cashier", "role": "cashier"},
            format="json",
        )
        self.client.post(
            f"{self.base}/auth/signup",
            {"email": "cash@shop.test", "password": "securepass2", "full_name": "Cashier"},
            format="json",
        )
        from taifa_merchant.infrastructure.models import Employee, MerchantIdentityUser
        from taifa_merchant.domain.enums import EmployeeStatus

        emp = Employee.objects.get(email="cash@shop.test")
        user = MerchantIdentityUser.objects.get(email="cash@shop.test")
        emp.identity_user_id = user.id
        emp.status = EmployeeStatus.ACTIVE
        emp.save()
        login = self.client.post(
            f"{self.base}/auth/login",
            {"email": "cash@shop.test", "password": "securepass2"},
            format="json",
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.json()['access_token']}")
        denied = self.client.patch(f"{self.base}/settings", {"language": "fr"}, format="json")
        self.assertEqual(denied.status_code, 403)

    def test_no_settlement_routes_in_bff(self):
        joined = " ".join(str(p.pattern) for p in __import__("taifa_merchant.urls", fromlist=["urlpatterns"]).urlpatterns)
        for forbidden in ("settlement", "reconciliation", "fraud-score", "orchestration"):
            self.assertNotIn(forbidden, joined.lower())
