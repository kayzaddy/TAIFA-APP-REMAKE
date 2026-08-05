"""Card acquirer HTTP gateway — configurable PSP (never simulated in production)."""
from __future__ import annotations

from dataclasses import dataclass

import requests
from django.conf import settings

from ..money import Currency
from .base import (
    PaymentAccepted,
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
class CardAcquirerConfig:
    base_url: str
    api_key: str
    merchant_id: str
    timeout_seconds: int = 30

    @property
    def is_configured(self) -> bool:
        return bool(self.base_url and self.api_key and self.merchant_id)

    @classmethod
    def from_settings(cls) -> "CardAcquirerConfig":
        cfg = getattr(settings, "CARD_ACQUIRER", None) or {}
        return cls(
            base_url=(cfg.get("BASE_URL") or "").rstrip("/"),
            api_key=cfg.get("API_KEY", ""),
            merchant_id=cfg.get("MERCHANT_ID", ""),
            timeout_seconds=int(cfg.get("TIMEOUT_SECONDS", 30)),
        )


class CardGateway(PaymentGateway):
    provider = PaymentProvider.CARD_SCHEME
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.REFUND,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.CARD,
    }

    def __init__(
        self,
        config: CardAcquirerConfig | None = None,
        session: requests.Session | None = None,
    ):
        self.config = config or CardAcquirerConfig.from_settings()
        self._session = session or requests.Session()

    def can_handle(self, request: PaymentRequest) -> bool:
        if not self.config.is_configured:
            return False
        if request.method_kind != "card":
            return False
        if request.amount.currency not in {Currency.TZS, Currency.USD, Currency.EUR, Currency.KES}:
            return False
        needed = {
            PaymentOperation.CHARGE: PaymentCapability.CHARGE,
            PaymentOperation.PAYOUT: PaymentCapability.PAYOUT,
            PaymentOperation.REFUND: PaymentCapability.REFUND,
        }[request.operation]
        return needed in self.capabilities

    def _headers(self) -> dict:
        return {
            "Authorization": f"Bearer {self.config.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-Merchant-Id": self.config.merchant_id,
            "Idempotency-Key": "",
        }

    def charge(self, request: PaymentRequest) -> PaymentResult:
        if not self.can_handle(request):
            return PaymentFailed(
                self.provider,
                code="NOT_CONFIGURED",
                message="Card acquirer credentials missing or request unsupported.",
            )
        headers = self._headers()
        headers["Idempotency-Key"] = request.idempotency_key
        body = {
            "merchant_id": self.config.merchant_id,
            "amount": request.amount.minor_units,
            "currency": request.amount.currency.code,
            "reference": request.reference,
            "payment_method_token": request.method_ref,
            "capture": True,
            "metadata": request.metadata,
        }
        try:
            resp = self._session.post(
                f"{self.config.base_url}/v1/charges",
                headers=headers,
                json=body,
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            if resp.status_code >= 400:
                return PaymentFailed(
                    self.provider,
                    code=str(data.get("code") or resp.status_code),
                    message=str(data.get("message") or resp.text[:200]),
                    retryable=resp.status_code >= 500,
                )
            status = str(data.get("status") or "").upper()
            ref = str(data.get("id") or data.get("charge_id") or request.reference)
            if status in {"SUCCEEDED", "CAPTURED", "PAID"}:
                return PaymentAccepted(self.provider, provider_ref=ref, raw_status=status)
            return PaymentPending(self.provider, provider_ref=ref, raw_status=status or "PENDING")
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)

    def payout(self, request: PaymentRequest) -> PaymentResult:
        return PaymentFailed(self.provider, code="UNSUPPORTED", message="Card payouts unsupported")

    def refund(self, request: PaymentRequest) -> PaymentResult:
        if not self.config.is_configured:
            return PaymentFailed(self.provider, code="NOT_CONFIGURED", message="Card acquirer not configured")
        headers = self._headers()
        headers["Idempotency-Key"] = request.idempotency_key
        body = {
            "charge_id": request.method_ref or request.metadata.get("provider_ref"),
            "amount": request.amount.minor_units,
            "currency": request.amount.currency.code,
            "reference": request.reference,
        }
        try:
            resp = self._session.post(
                f"{self.config.base_url}/v1/refunds",
                headers=headers,
                json=body,
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            if resp.status_code >= 400:
                return PaymentFailed(
                    self.provider,
                    code=str(data.get("code") or resp.status_code),
                    message=str(data.get("message") or "")[:200],
                    retryable=resp.status_code >= 500,
                )
            return PaymentAccepted(
                self.provider,
                provider_ref=str(data.get("id") or request.reference),
                raw_status="REFUNDED",
            )
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)

    def status(self, provider_ref: str) -> PaymentResult:
        if not self.config.is_configured:
            return PaymentFailed(self.provider, code="NOT_CONFIGURED", message="Card acquirer not configured")
        try:
            resp = self._session.get(
                f"{self.config.base_url}/v1/charges/{provider_ref}",
                headers=self._headers(),
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            status = str(data.get("status") or "").upper()
            if status in {"SUCCEEDED", "CAPTURED", "PAID"}:
                return PaymentAccepted(self.provider, provider_ref=provider_ref, raw_status=status)
            if status in {"FAILED", "CANCELLED"}:
                return PaymentFailed(self.provider, code=status, message="declined", provider_ref=provider_ref)
            return PaymentPending(self.provider, provider_ref=provider_ref, raw_status=status or "PENDING")
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)
