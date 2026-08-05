"""Airtel Money collection / disbursement — live HTTP when credentials are set."""
from __future__ import annotations

from dataclasses import dataclass

import requests
from django.conf import settings

from ..money import Currency
from .base import (
    PaymentCapability,
    PaymentFailed,
    PaymentGateway,
    PaymentOperation,
    PaymentPending,
    PaymentProvider,
    PaymentRequest,
    PaymentResult,
)


@dataclass
class AirtelConfig:
    client_id: str
    client_secret: str
    base_url: str
    country: str = "TZ"
    currency: str = "TZS"
    timeout_seconds: int = 30

    @property
    def is_configured(self) -> bool:
        return bool(self.client_id and self.client_secret and self.base_url)

    @classmethod
    def from_settings(cls) -> "AirtelConfig":
        cfg = getattr(settings, "AIRTEL_MONEY", None) or {}
        return cls(
            client_id=cfg.get("CLIENT_ID", ""),
            client_secret=cfg.get("CLIENT_SECRET", ""),
            base_url=(cfg.get("BASE_URL") or "").rstrip("/"),
            country=cfg.get("COUNTRY", "TZ"),
            currency=cfg.get("CURRENCY", "TZS"),
            timeout_seconds=int(cfg.get("TIMEOUT_SECONDS", 30)),
        )


class AirtelMoneyGateway(PaymentGateway):
    provider = PaymentProvider.AIRTEL_MONEY
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.PAYOUT,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.MOBILE_MONEY,
    }

    def __init__(self, config: AirtelConfig | None = None, session: requests.Session | None = None):
        self.config = config or AirtelConfig.from_settings()
        self._session = session or requests.Session()
        self._token: str | None = None

    def can_handle(self, request: PaymentRequest) -> bool:
        if not self.config.is_configured:
            return False
        if request.method_kind != "mobile_money":
            return False
        if request.amount.currency not in {Currency.TZS, Currency.KES, Currency.UGX}:
            return False
        needed = {
            PaymentOperation.CHARGE: PaymentCapability.CHARGE,
            PaymentOperation.PAYOUT: PaymentCapability.PAYOUT,
            PaymentOperation.REFUND: PaymentCapability.REFUND,
        }[request.operation]
        return needed in self.capabilities

    def _access_token(self) -> str:
        if self._token:
            return self._token
        resp = self._session.post(
            f"{self.config.base_url}/auth/oauth2/token",
            data={
                "client_id": self.config.client_id,
                "client_secret": self.config.client_secret,
                "grant_type": "client_credentials",
            },
            timeout=self.config.timeout_seconds,
        )
        resp.raise_for_status()
        self._token = resp.json()["access_token"]
        return self._token

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self._access_token()}",
            "Content-Type": "application/json",
            "Accept": "*/*",
            "X-Country": self.config.country,
            "X-Currency": self.config.currency,
        }

    def charge(self, request: PaymentRequest) -> PaymentResult:
        if not self.can_handle(request):
            return PaymentFailed(
                self.provider,
                code="NOT_CONFIGURED",
                message="Airtel Money credentials missing or request unsupported.",
            )
        amount_major = request.amount.minor_units // request.amount.currency.scale
        body = {
            "reference": request.reference,
            "subscriber": {"msisdn": request.method_ref},
            "transaction": {
                "amount": int(amount_major),
                "country": self.config.country,
                "currency": self.config.currency,
                "id": request.idempotency_key[:50],
            },
        }
        try:
            resp = self._session.post(
                f"{self.config.base_url}/merchant/v1/payments/",
                headers=self._headers(),
                json=body,
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            if resp.status_code >= 400:
                return PaymentFailed(
                    self.provider,
                    code=str(data.get("status", {}).get("response_code") or resp.status_code),
                    message=str(data.get("status", {}).get("message") or resp.text[:200]),
                    retryable=resp.status_code >= 500,
                )
            txn = (data.get("data") or {}).get("transaction") or {}
            ref = str(txn.get("id") or txn.get("airtel_money_id") or request.idempotency_key)
            return PaymentPending(self.provider, provider_ref=ref, raw_status="AWAITING_CUSTOMER")
        except requests.RequestException as exc:
            return PaymentFailed(
                self.provider,
                code="NETWORK",
                message=str(exc),
                retryable=True,
            )

    def payout(self, request: PaymentRequest) -> PaymentResult:
        if not self.can_handle(request):
            return PaymentFailed(
                self.provider,
                code="NOT_CONFIGURED",
                message="Airtel Money credentials missing or request unsupported.",
            )
        body = {
            "payee": {"msisdn": request.method_ref},
            "reference": request.reference,
            "pin": "",
            "transaction": {
                "amount": int(request.amount.minor_units // request.amount.currency.scale),
                "id": request.idempotency_key[:50],
            },
        }
        try:
            resp = self._session.post(
                f"{self.config.base_url}/standard/v1/disbursements/",
                headers=self._headers(),
                json=body,
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            if resp.status_code >= 400:
                return PaymentFailed(
                    self.provider,
                    code=str(resp.status_code),
                    message=str(data)[:200],
                    retryable=resp.status_code >= 500,
                )
            ref = str(((data.get("data") or {}).get("transaction") or {}).get("id") or request.reference)
            from .base import PaymentAccepted

            return PaymentAccepted(self.provider, provider_ref=ref)
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)

    def refund(self, request: PaymentRequest) -> PaymentResult:
        return PaymentFailed(
            self.provider,
            code="UNSUPPORTED",
            message="Airtel refunds must be initiated via support workflow.",
        )

    def status(self, provider_ref: str) -> PaymentResult:
        if not self.config.is_configured:
            return PaymentFailed(self.provider, code="NOT_CONFIGURED", message="Airtel not configured")
        try:
            resp = self._session.get(
                f"{self.config.base_url}/standard/v1/payments/{provider_ref}",
                headers=self._headers(),
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            status = str(((data.get("data") or {}).get("transaction") or {}).get("status") or "").upper()
            from .base import PaymentAccepted

            if status in {"TS", "SUCCESS", "COMPLETED"}:
                return PaymentAccepted(self.provider, provider_ref=provider_ref, raw_status=status)
            if status in {"TF", "FAILED"}:
                return PaymentFailed(self.provider, code=status, message="declined", provider_ref=provider_ref)
            return PaymentPending(self.provider, provider_ref=provider_ref, raw_status=status or "PENDING")
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)
