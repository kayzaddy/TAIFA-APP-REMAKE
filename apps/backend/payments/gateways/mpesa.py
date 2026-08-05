"""Real M-Pesa (Daraja) adapter.

Implements the [PaymentGateway] contract against Safaricom/Vodacom's Daraja API:
OAuth token, STK push (Lipa na M-Pesa Online) for collection/top-up, B2C for
payouts, and an STK query for status. Collection returns [PaymentPending] — the
final state is delivered to our webhook and resolved by the WebhookProcessor.

Credentials come from settings.MPESA (env-driven). With no credentials the
adapter still constructs; live calls will fail cleanly as [PaymentFailed], and
tests inject a fake HTTP session.
"""
from __future__ import annotations

import base64
import datetime as dt
from dataclasses import dataclass

import requests

from ..money import Currency
from .base import (
    PaymentCapability,
    PaymentFailed,
    PaymentGateway,
    PaymentPending,
    PaymentProvider,
    PaymentRequest,
    PaymentResult,
)

_SANDBOX = "https://sandbox.safaricom.co.ke"
_PRODUCTION = "https://api.safaricom.co.ke"


@dataclass
class MpesaConfig:
    consumer_key: str
    consumer_secret: str
    shortcode: str
    passkey: str
    initiator_name: str
    security_credential: str
    callback_base_url: str
    environment: str = "sandbox"
    timeout_seconds: int = 30

    @property
    def base_url(self) -> str:
        return _PRODUCTION if self.environment == "production" else _SANDBOX

    @property
    def is_configured(self) -> bool:
        """True when OAuth + STK credentials are present (live Daraja path)."""
        return bool(self.consumer_key and self.consumer_secret and self.passkey and self.shortcode)

    @classmethod
    def from_settings(cls, mpesa: dict) -> "MpesaConfig":
        return cls(
            consumer_key=mpesa.get("CONSUMER_KEY", ""),
            consumer_secret=mpesa.get("CONSUMER_SECRET", ""),
            shortcode=mpesa.get("SHORTCODE", ""),
            passkey=mpesa.get("PASSKEY", ""),
            initiator_name=mpesa.get("INITIATOR_NAME", ""),
            security_credential=mpesa.get("SECURITY_CREDENTIAL", ""),
            callback_base_url=mpesa.get("CALLBACK_BASE_URL", ""),
            environment=mpesa.get("ENVIRONMENT", "sandbox"),
            timeout_seconds=int(mpesa.get("TIMEOUT_SECONDS", 30)),
        )


class MpesaGateway(PaymentGateway):
    provider = PaymentProvider.MPESA
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.PAYOUT,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.MOBILE_MONEY,
    }

    def __init__(self, config: MpesaConfig, session: requests.Session | None = None):
        self.config = config
        self._session = session or requests.Session()

    # --- capability gate ---
    def can_handle(self, request: PaymentRequest) -> bool:
        if request.method_kind != "mobile_money":
            return False
        if request.amount.currency not in {Currency.TZS, Currency.KES}:
            return False
        from .base import PaymentOperation

        needed = {
            PaymentOperation.CHARGE: PaymentCapability.CHARGE,
            PaymentOperation.PAYOUT: PaymentCapability.PAYOUT,
            PaymentOperation.REFUND: PaymentCapability.REFUND,
        }[request.operation]
        return needed in self.capabilities

    # --- helpers ---
    def _timestamp(self) -> str:
        return dt.datetime.now().strftime("%Y%m%d%H%M%S")

    def _password(self, timestamp: str) -> str:
        raw = f"{self.config.shortcode}{self.config.passkey}{timestamp}".encode()
        return base64.b64encode(raw).decode()

    def _callback(self, path: str) -> str:
        return f"{self.config.callback_base_url.rstrip('/')}{path}"

    def _access_token(self) -> str:
        resp = self._session.get(
            f"{self.config.base_url}/oauth/v1/generate",
            params={"grant_type": "client_credentials"},
            auth=(self.config.consumer_key, self.config.consumer_secret),
            timeout=self.config.timeout_seconds,
        )
        resp.raise_for_status()
        return resp.json()["access_token"]

    def _major_amount(self, request: PaymentRequest) -> int:
        # Daraja expects whole currency units.
        return request.amount.minor_units // request.amount.currency.scale

    def _msisdn(self, request: PaymentRequest) -> str:
        digits = "".join(ch for ch in request.method_ref if ch.isdigit())
        # Normalise +255 / 0-prefixed numbers to the 2557XXXXXXXX MSISDN form.
        if digits.startswith("0"):
            digits = "255" + digits[1:]
        return digits

    # --- operations ---
    def charge(self, request: PaymentRequest) -> PaymentResult:
        """Collect via STK push. Returns PaymentPending; the STK callback resolves it."""
        timestamp = self._timestamp()
        try:
            token = self._access_token()
            body = {
                "BusinessShortCode": self.config.shortcode,
                "Password": self._password(timestamp),
                "Timestamp": timestamp,
                "TransactionType": "CustomerPayBillOnline",
                "Amount": self._major_amount(request),
                "PartyA": self._msisdn(request),
                "PartyB": self.config.shortcode,
                "PhoneNumber": self._msisdn(request),
                "CallBackURL": self._callback("/api/v1/payments/webhooks/mpesa/stk"),
                "AccountReference": request.reference[:12],
                "TransactionDesc": (request.narrative or "TAIFA top-up")[:20],
            }
            resp = self._session.post(
                f"{self.config.base_url}/mpesa/stkpush/v1/processrequest",
                json=body,
                headers={"Authorization": f"Bearer {token}"},
                timeout=self.config.timeout_seconds,
            )
            data = resp.json()
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)
        except (KeyError, ValueError) as exc:
            return PaymentFailed(self.provider, code="BAD_RESPONSE", message=str(exc))

        if str(data.get("ResponseCode")) == "0":
            return PaymentPending(self.provider, provider_ref=data.get("CheckoutRequestID", ""))
        return PaymentFailed(
            self.provider,
            code=str(data.get("errorCode") or data.get("ResponseCode") or "DECLINED"),
            message=data.get("errorMessage") or data.get("ResponseDescription") or "STK push failed",
        )

    def payout(self, request: PaymentRequest) -> PaymentResult:
        """Disburse via B2C. Returns PaymentPending; the result callback resolves it."""
        try:
            token = self._access_token()
            body = {
                "InitiatorName": self.config.initiator_name,
                "SecurityCredential": self.config.security_credential,
                "CommandID": "BusinessPayment",
                "Amount": self._major_amount(request),
                "PartyA": self.config.shortcode,
                "PartyB": self._msisdn(request),
                "Remarks": (request.narrative or "TAIFA payout")[:100],
                "QueueTimeOutURL": self._callback("/api/v1/payments/webhooks/mpesa/b2c/timeout"),
                "ResultURL": self._callback("/api/v1/payments/webhooks/mpesa/b2c"),
                "Occassion": request.reference[:20],
            }
            resp = self._session.post(
                f"{self.config.base_url}/mpesa/b2c/v1/paymentrequest",
                json=body,
                headers={"Authorization": f"Bearer {token}"},
                timeout=self.config.timeout_seconds,
            )
            data = resp.json()
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)
        except (KeyError, ValueError) as exc:
            return PaymentFailed(self.provider, code="BAD_RESPONSE", message=str(exc))

        if str(data.get("ResponseCode")) == "0":
            return PaymentPending(self.provider, provider_ref=data.get("ConversationID", ""))
        return PaymentFailed(
            self.provider,
            code=str(data.get("errorCode") or "DECLINED"),
            message=data.get("errorMessage") or "B2C request failed",
        )

    def refund(self, request: PaymentRequest) -> PaymentResult:
        # Reversal API integration is a later milestone.
        return PaymentFailed(self.provider, code="UNSUPPORTED", message="M-Pesa reversal not yet enabled.")

    def status(self, provider_ref: str) -> PaymentResult:
        timestamp = self._timestamp()
        try:
            token = self._access_token()
            body = {
                "BusinessShortCode": self.config.shortcode,
                "Password": self._password(timestamp),
                "Timestamp": timestamp,
                "CheckoutRequestID": provider_ref,
            }
            resp = self._session.post(
                f"{self.config.base_url}/mpesa/stkpushquery/v1/query",
                json=body,
                headers={"Authorization": f"Bearer {token}"},
                timeout=self.config.timeout_seconds,
            )
            data = resp.json()
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)
        except (KeyError, ValueError) as exc:
            return PaymentFailed(self.provider, code="BAD_RESPONSE", message=str(exc))

        if str(data.get("ResultCode")) == "0":
            from .base import PaymentAccepted

            return PaymentAccepted(self.provider, provider_ref=provider_ref)
        if str(data.get("ResultCode")) in {"1032", "1"}:  # cancelled / insufficient
            return PaymentFailed(self.provider, code=str(data.get("ResultCode")), message=data.get("ResultDesc", ""))
        return PaymentPending(self.provider, provider_ref=provider_ref)
