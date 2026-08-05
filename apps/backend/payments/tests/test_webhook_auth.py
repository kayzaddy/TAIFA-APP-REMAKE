"""Unit + API tests for M-Pesa webhook IP allow-list and shared secret."""
from __future__ import annotations

from types import SimpleNamespace

from django.test import SimpleTestCase, override_settings
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.test import APIRequestFactory, APITestCase

from payments.webhook_auth import (
    assert_mpesa_stk_webhook_trusted,
    client_ip,
    ip_is_allowed,
    secret_is_valid,
    validate_stk_payload,
)


def _fake_request(*, data: dict, remote_addr: str = "127.0.0.1", secret: str = ""):
    meta = {"REMOTE_ADDR": remote_addr}
    if secret:
        meta["HTTP_X_TAIFA_MPESA_WEBHOOK_SECRET"] = secret
    return SimpleNamespace(META=meta, data=data, body=b"{}")


class WebhookAuthUnitTests(SimpleTestCase):
    def test_ip_allow_list_exact_and_cidr(self):
        self.assertTrue(ip_is_allowed("203.0.113.10", []))
        self.assertTrue(ip_is_allowed("203.0.113.10", ["203.0.113.10"]))
        self.assertFalse(ip_is_allowed("203.0.113.11", ["203.0.113.10"]))
        self.assertTrue(ip_is_allowed("203.0.113.40", ["203.0.113.0/24"]))
        self.assertFalse(ip_is_allowed("198.51.100.1", ["203.0.113.0/24"]))
        self.assertFalse(ip_is_allowed("", ["203.0.113.10"]))

    def test_secret_compare(self):
        self.assertTrue(secret_is_valid("", ""))
        self.assertTrue(secret_is_valid("abc", "abc"))
        self.assertFalse(secret_is_valid("abc", "xyz"))
        self.assertFalse(secret_is_valid("", "xyz"))

    def test_validate_stk_payload(self):
        checkout, code = validate_stk_payload(
            {"Body": {"stkCallback": {"CheckoutRequestID": "ws_ABC", "ResultCode": 0}}}
        )
        self.assertEqual(checkout, "ws_ABC")
        self.assertEqual(code, "0")
        with self.assertRaises(ValidationError):
            validate_stk_payload({"Body": {}})
        with self.assertRaises(ValidationError):
            validate_stk_payload({"Body": {"stkCallback": {"ResultCode": 0}}})

    def test_client_ip_from_forwarded_for(self):
        factory = APIRequestFactory()
        req = factory.post("/api/v1/payments/webhooks/mpesa/stk")
        req.META["HTTP_X_FORWARDED_FOR"] = "198.51.100.7, 10.0.0.1"
        req.META["REMOTE_ADDR"] = "10.0.0.1"
        self.assertEqual(client_ip(req), "198.51.100.7")


class WebhookAuthViewTests(APITestCase):
    def _callback(self, checkout="ws_TEST"):
        return {
            "Body": {
                "stkCallback": {
                    "CheckoutRequestID": checkout,
                    "ResultCode": 0,
                    "ResultDesc": "ok",
                }
            }
        }

    @override_settings(MPESA_WEBHOOK_ALLOWED_IPS=["203.0.113.10"], MPESA_WEBHOOK_SHARED_SECRET="")
    def test_rejects_disallowed_ip(self):
        req = _fake_request(data=self._callback(), remote_addr="198.51.100.1")
        with self.assertRaises(PermissionDenied):
            assert_mpesa_stk_webhook_trusted(req)

    @override_settings(
        MPESA_WEBHOOK_ALLOWED_IPS=["203.0.113.0/24"],
        MPESA_WEBHOOK_SHARED_SECRET="",
        MPESA_WEBHOOK_FAIL_CLOSED=False,
        MPESA_WEBHOOK_REQUIRE_HMAC=False,
    )
    def test_allows_cidr_match(self):
        req = _fake_request(data=self._callback("ws_CIDR"), remote_addr="203.0.113.55")
        assert_mpesa_stk_webhook_trusted(req)  # no raise

    @override_settings(
        MPESA_WEBHOOK_ALLOWED_IPS=[],
        MPESA_WEBHOOK_SHARED_SECRET="s3cret",
        MPESA_WEBHOOK_FAIL_CLOSED=False,
        MPESA_WEBHOOK_REQUIRE_HMAC=False,
    )
    def test_rejects_missing_secret(self):
        req = _fake_request(data=self._callback("ws_NOS"), remote_addr="127.0.0.1")
        with self.assertRaises(PermissionDenied):
            assert_mpesa_stk_webhook_trusted(req)

    @override_settings(
        MPESA_WEBHOOK_ALLOWED_IPS=[],
        MPESA_WEBHOOK_SHARED_SECRET="s3cret",
        MPESA_WEBHOOK_FAIL_CLOSED=False,
        MPESA_WEBHOOK_REQUIRE_HMAC=False,
    )
    def test_allows_matching_secret(self):
        req = _fake_request(
            data=self._callback("ws_OK"),
            remote_addr="127.0.0.1",
            secret="s3cret",
        )
        assert_mpesa_stk_webhook_trusted(req)

    @override_settings(MPESA_WEBHOOK_ALLOWED_IPS=[], MPESA_WEBHOOK_SHARED_SECRET="")
    def test_http_endpoint_rejects_malformed_body(self):
        resp = self.client.post(
            "/api/v1/payments/webhooks/mpesa/stk",
            {"nope": True},
            format="json",
        )
        self.assertEqual(resp.status_code, 400)

    @override_settings(MPESA_WEBHOOK_ALLOWED_IPS=["203.0.113.10"], MPESA_WEBHOOK_SHARED_SECRET="")
    def test_http_endpoint_rejects_bad_ip(self):
        resp = self.client.post(
            "/api/v1/payments/webhooks/mpesa/stk",
            self._callback(),
            format="json",
            REMOTE_ADDR="198.51.100.1",
        )
        self.assertEqual(resp.status_code, 403)
