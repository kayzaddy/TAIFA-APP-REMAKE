"""Taifa Mobility BRT — production hardening tests."""
from __future__ import annotations

from unittest.mock import patch

from django.core.management import call_command
from rest_framework.test import APIClient, APITestCase

from enterprise.models import PlatformPrincipal, PlatformRole
from integrations.notifications import DeliveryResult
from payments.models import Device
from trips.national_models import TransitLostFoundItem, TransitNotification


class BrtHardeningApiTests(APITestCase):
    def setUp(self):
        call_command("seed_mobility_brt")
        self.passenger_client = APIClient()
        self.ops_client = APIClient()

        reg = self.passenger_client.post(
            "/api/v1/auth/device/register",
            {
                "device_id": "brt-hard-passenger",
                "platform": "test",
                "push_token": "push-token-demo",
            },
            format="json",
        ).json()
        self.owner = reg["owner"]
        self.passenger_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {reg['token']}",
            HTTP_X_DEVICE_ID="brt-hard-passenger",
        )

        ops_reg = self.ops_client.post(
            "/api/v1/auth/device/register",
            {"device_id": "brt-hard-ops", "platform": "test"},
            format="json",
        ).json()
        self.ops_client.credentials(
            HTTP_AUTHORIZATION=f"Bearer {ops_reg['token']}",
            HTTP_X_DEVICE_ID="brt-hard-ops",
        )
        self._grant_ops(ops_reg["owner"])

    def _grant_ops(self, owner: str) -> None:
        role, _ = PlatformRole.objects.get_or_create(
            code="mobility-ops-hard",
            defaults={"name": "Mobility Ops", "permissions": ["mobility.operations"]},
        )
        principal, _ = PlatformPrincipal.objects.get_or_create(
            principal_id=owner,
            defaults={"display_name": "Ops", "mfa_required": False},
        )
        principal.roles.add(role)

    @patch("integrations.notifications.deliver_notification")
    def test_push_delivery_on_lost_found_report(self, deliver_mock):
        deliver_mock.return_value = DeliveryResult(
            channel="push",
            accepted=True,
            provider_ref="push-1",
            detail={},
        )
        res = self.passenger_client.post(
            "/api/v1/trips/transit/lost-found",
            {
                "kind": "lost",
                "title": "Blue backpack",
                "stop_code": "ubungo",
            },
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        deliver_mock.assert_called()
        note = TransitNotification.objects.filter(
            owner=self.owner,
            event_type="transit.lost_found.reported",
        ).first()
        self.assertIsNotNone(note)
        self.assertTrue(note.payload.get("push_delivered"))

    def test_upload_lost_found_photo(self):
        import base64

        content = base64.b64encode(b"fake-image-bytes").decode()
        res = self.passenger_client.post(
            "/api/v1/trips/transit/lost-found/photo",
            {"content_base64": content, "content_type": "image/jpeg"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        self.assertIn("photo_url", res.data)
        report = self.passenger_client.post(
            "/api/v1/trips/transit/lost-found",
            {
                "kind": "found",
                "title": "Wallet with photo",
                "photo_url": res.data["photo_url"],
                "stop_code": "kimara",
            },
            format="json",
        )
        self.assertEqual(report.status_code, 201)
        item = TransitLostFoundItem.objects.get(pk=report.data["id"])
        self.assertTrue(item.photo_url)

    def test_ops_lists_lost_found_queue(self):
        self.passenger_client.post(
            "/api/v1/trips/transit/lost-found",
            {"kind": "found", "title": "Umbrella", "stop_code": "posta"},
            format="json",
        )
        denied = self.passenger_client.get("/api/v1/trips/transit/admin/lost-found")
        self.assertEqual(denied.status_code, 403)
        allowed = self.ops_client.get("/api/v1/trips/transit/admin/lost-found?status=open")
        self.assertEqual(allowed.status_code, 200)
        self.assertGreaterEqual(len(allowed.data["items"]), 1)

    def test_ops_resolve_lost_found_item(self):
        found = self.passenger_client.post(
            "/api/v1/trips/transit/lost-found",
            {"kind": "found", "title": "ID card", "stop_code": "kariakoo"},
            format="json",
        ).data
        res = self.ops_client.post(
            f"/api/v1/trips/transit/admin/lost-found/{found['id']}/resolve",
            {"status": "closed"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        item = TransitLostFoundItem.objects.get(pk=found["id"])
        self.assertEqual(item.status, "closed")

    def test_device_push_token_update(self):
        res = self.passenger_client.post(
            "/api/v1/auth/device/push-token",
            {"push_token": "updated-push-token"},
            format="json",
        )
        self.assertEqual(res.status_code, 200)
        device = Device.objects.get(device_id="brt-hard-passenger")
        self.assertEqual(device.push_token, "updated-push-token")

    def test_transit_ops_snapshot_includes_lost_found(self):
        from trips.transit_services import transit_ops_snapshot

        snap = transit_ops_snapshot()
        self.assertIn("lost_found_open", snap)
        self.assertIn("lost_found_claimed", snap)
