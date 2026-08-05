"""Unit tests for the real M-Pesa Daraja adapter (HTTP mocked — no live calls)."""
from __future__ import annotations

from unittest.mock import MagicMock

from django.test import SimpleTestCase, override_settings

from payments.gateways.base import (
    PaymentAccepted,
    PaymentFailed,
    PaymentOperation,
    PaymentPending,
    PaymentRequest,
)
from payments.gateways.factory import _mpesa_gateway
from payments.gateways.mpesa import MpesaConfig, MpesaGateway
from payments.gateways.simulated import OfflineMpesaGateway
from payments.money import Currency, Money


def _req(**overrides) -> PaymentRequest:
    base = dict(
        idempotency_key="idem-1",
        reference="txn-ref-1",
        amount=Money.major(1000, Currency.TZS),
        operation=PaymentOperation.CHARGE,
        method_kind="mobile_money",
        method_ref="255712345678",
        operator="mpesa",
        narrative="Top up",
    )
    base.update(overrides)
    return PaymentRequest(**base)


class MpesaGatewayUnitTests(SimpleTestCase):
    def setUp(self):
        self.cfg = MpesaConfig(
            consumer_key="key",
            consumer_secret="secret",
            shortcode="174379",
            passkey="pass",
            initiator_name="",
            security_credential="",
            callback_base_url="https://hooks.example.test",
            environment="sandbox",
        )

    def test_is_configured(self):
        self.assertTrue(self.cfg.is_configured)
        bare = MpesaConfig(
            consumer_key="",
            consumer_secret="",
            shortcode="174379",
            passkey="",
            initiator_name="",
            security_credential="",
            callback_base_url="",
        )
        self.assertFalse(bare.is_configured)

    def test_charge_returns_pending_on_response_code_0(self):
        session = MagicMock()
        token_resp = MagicMock()
        token_resp.raise_for_status = MagicMock()
        token_resp.json.return_value = {"access_token": "tok"}
        stk_resp = MagicMock()
        stk_resp.json.return_value = {
            "ResponseCode": "0",
            "CheckoutRequestID": "ws_CO_123",
        }
        session.get.return_value = token_resp
        session.post.return_value = stk_resp

        gw = MpesaGateway(self.cfg, session=session)
        result = gw.charge(_req())
        self.assertIsInstance(result, PaymentPending)
        self.assertEqual(result.provider_ref, "ws_CO_123")
        session.post.assert_called_once()
        body = session.post.call_args.kwargs["json"]
        self.assertEqual(body["BusinessShortCode"], "174379")
        self.assertEqual(body["PhoneNumber"], "255712345678")
        self.assertIn("/webhooks/mpesa/stk", body["CallBackURL"])

    def test_charge_normalises_leading_zero_msisdn(self):
        session = MagicMock()
        token_resp = MagicMock()
        token_resp.raise_for_status = MagicMock()
        token_resp.json.return_value = {"access_token": "tok"}
        stk_resp = MagicMock()
        stk_resp.json.return_value = {"ResponseCode": "0", "CheckoutRequestID": "x"}
        session.get.return_value = token_resp
        session.post.return_value = stk_resp

        gw = MpesaGateway(self.cfg, session=session)
        gw.charge(_req(method_ref="0712345678"))
        self.assertEqual(session.post.call_args.kwargs["json"]["PartyA"], "255712345678")

    def test_status_accepted_on_result_0(self):
        session = MagicMock()
        token_resp = MagicMock()
        token_resp.raise_for_status = MagicMock()
        token_resp.json.return_value = {"access_token": "tok"}
        q_resp = MagicMock()
        q_resp.json.return_value = {"ResultCode": "0", "ResultDesc": "The service request is processed successfully."}
        session.get.return_value = token_resp
        session.post.return_value = q_resp

        gw = MpesaGateway(self.cfg, session=session)
        result = gw.status("ws_CO_123")
        self.assertIsInstance(result, PaymentAccepted)

    def test_status_failed_on_cancelled(self):
        session = MagicMock()
        token_resp = MagicMock()
        token_resp.raise_for_status = MagicMock()
        token_resp.json.return_value = {"access_token": "tok"}
        q_resp = MagicMock()
        q_resp.json.return_value = {"ResultCode": "1032", "ResultDesc": "Request cancelled by user"}
        session.get.return_value = token_resp
        session.post.return_value = q_resp

        gw = MpesaGateway(self.cfg, session=session)
        result = gw.status("ws_CO_123")
        self.assertIsInstance(result, PaymentFailed)


class FactorySelectionTests(SimpleTestCase):
    @override_settings(
        MPESA={
            "ENVIRONMENT": "sandbox",
            "CONSUMER_KEY": "",
            "CONSUMER_SECRET": "",
            "SHORTCODE": "174379",
            "PASSKEY": "",
            "INITIATOR_NAME": "",
            "SECURITY_CREDENTIAL": "",
            "CALLBACK_BASE_URL": "https://example.com",
            "TIMEOUT_SECONDS": 30,
        }
    )
    def test_offline_without_credentials(self):
        self.assertIsInstance(_mpesa_gateway(), OfflineMpesaGateway)

    @override_settings(
        MPESA={
            "ENVIRONMENT": "sandbox",
            "CONSUMER_KEY": "k",
            "CONSUMER_SECRET": "s",
            "SHORTCODE": "174379",
            "PASSKEY": "p",
            "INITIATOR_NAME": "",
            "SECURITY_CREDENTIAL": "",
            "CALLBACK_BASE_URL": "https://example.com",
            "TIMEOUT_SECONDS": 30,
        }
    )
    def test_live_with_credentials(self):
        self.assertIsInstance(_mpesa_gateway(), MpesaGateway)
