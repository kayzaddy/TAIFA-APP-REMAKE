"""Selcom Pay — signed HTTP aggregator (mobile money, card, bank)."""
from __future__ import annotations

import base64
import hashlib
import hmac
import json
from dataclasses import dataclass
from datetime import datetime, timezone

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
class SelcomConfig:
    base_url: str
    api_key: str
    api_secret: str
    vendor: str
    timeout_seconds: int = 30

    @property
    def is_configured(self) -> bool:
        return bool(self.base_url and self.api_key and self.api_secret and self.vendor)

    @classmethod
    def from_settings(cls) -> "SelcomConfig":
        cfg = getattr(settings, "SELCOM", None) or {}
        return cls(
            base_url=(cfg.get("BASE_URL") or "").rstrip("/"),
            api_key=cfg.get("API_KEY", ""),
            api_secret=cfg.get("API_SECRET", ""),
            vendor=cfg.get("VENDOR", ""),
            timeout_seconds=int(cfg.get("TIMEOUT_SECONDS", 30)),
        )


class SelcomGateway(PaymentGateway):
    provider = PaymentProvider.SELCOM
    capabilities = {
        PaymentCapability.CHARGE,
        PaymentCapability.PAYOUT,
        PaymentCapability.REFUND,
        PaymentCapability.STATUS_QUERY,
        PaymentCapability.MOBILE_MONEY,
        PaymentCapability.CARD,
        PaymentCapability.BANK,
    }

    def __init__(self, config: SelcomConfig | None = None, session: requests.Session | None = None):
        self.config = config or SelcomConfig.from_settings()
        self._session = session or requests.Session()

    def can_handle(self, request: PaymentRequest) -> bool:
        if not self.config.is_configured:
            return False
        if request.amount.currency not in {Currency.TZS, Currency.KES, Currency.USD}:
            return False
        needed = {
            PaymentOperation.CHARGE: PaymentCapability.CHARGE,
            PaymentOperation.PAYOUT: PaymentCapability.PAYOUT,
            PaymentOperation.REFUND: PaymentCapability.REFUND,
        }[request.operation]
        return needed in self.capabilities

    def _signed_headers(self, *, body: dict) -> dict:
        timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S+00:00")
        signed_fields = ["timestamp", "vendor"]
        digest_src = f"timestamp={timestamp}&vendor={self.config.vendor}"
        for key in sorted(k for k in body.keys() if k not in {"vendor"}):
            signed_fields.append(key)
            digest_src += f"&{key}={body[key]}"
        digest = base64.b64encode(
            hmac.new(
                self.config.api_secret.encode(),
                digest_src.encode(),
                hashlib.sha256,
            ).digest()
        ).decode()
        auth = base64.b64encode(self.config.api_key.encode()).decode()
        return {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"SELCOM {auth}",
            "Digest-Method": "HS256",
            "Digest": digest,
            "Timestamp": timestamp,
            "Signed-Fields": ",".join(signed_fields),
        }

    def charge(self, request: PaymentRequest) -> PaymentResult:
        if not self.can_handle(request):
            return PaymentFailed(
                self.provider,
                code="NOT_CONFIGURED",
                message="Selcom credentials missing or request unsupported.",
            )
        path = "/v1/checkout/create-order-minimal"
        selcom = getattr(settings, "SELCOM", {}) or {}
        body = {
            "vendor": self.config.vendor,
            "order_id": request.reference[:50],
            "buyer_phone": request.method_ref or "255700000000",
            "amount": str(int(request.amount.minor_units // request.amount.currency.scale)),
            "currency": request.amount.currency.code,
            "buyer_fullname": request.narrative or "Taifa payment",
            "redirect_url": selcom.get("REDIRECT_URL", "https://taifa.app/pay/return"),
            "cancel_url": selcom.get("CANCEL_URL", "https://taifa.app/pay/cancel"),
            "webhook": selcom.get("WEBHOOK_URL", ""),
            "no_of_items": 1,
        }
        try:
            resp = self._session.post(
                f"{self.config.base_url}{path}",
                headers=self._signed_headers(body=body),
                data=json.dumps(body),
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            result = str(data.get("result") or "").upper()
            resultcode = str(data.get("resultcode") or "")
            okish = result in {"SUCCESS", "PENDING"} or resultcode in {"000", "111"}
            if resp.status_code >= 400 and not okish:
                return PaymentFailed(
                    self.provider,
                    code=resultcode or str(resp.status_code),
                    message=str(data.get("message") or resp.text[:200]),
                    retryable=resp.status_code >= 500,
                )
            if not okish and resp.status_code < 400 and result not in {"", "SUCCESS", "PENDING"}:
                # Soft-fail: still surface provider message when explicitly failed
                if result in {"FAIL", "FAILED", "ERROR"}:
                    return PaymentFailed(
                        self.provider,
                        code=resultcode or result,
                        message=str(data.get("message") or "declined"),
                    )
            ref = request.reference
            payload = data.get("data")
            if isinstance(payload, list) and payload:
                ref = str(payload[0].get("payment_token") or payload[0].get("order_id") or ref)
            elif isinstance(payload, dict):
                ref = str(payload.get("payment_token") or payload.get("order_id") or ref)
            else:
                ref = str(data.get("payment_token") or data.get("order_id") or ref)
            return PaymentPending(self.provider, provider_ref=ref, raw_status=result or "PENDING")
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)

    def payout(self, request: PaymentRequest) -> PaymentResult:
        if not self.can_handle(request):
            return PaymentFailed(self.provider, code="NOT_CONFIGURED", message="Selcom not configured")
        path = "/v1/wallet/process-disbursement"
        body = {
            "vendor": self.config.vendor,
            "order_id": request.reference[:50],
            "amount": str(int(request.amount.minor_units // request.amount.currency.scale)),
            "currency": request.amount.currency.code,
            "msisdn": request.method_ref,
        }
        try:
            resp = self._session.post(
                f"{self.config.base_url}{path}",
                headers=self._signed_headers(body=body),
                data=json.dumps(body),
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            if resp.status_code >= 400:
                return PaymentFailed(
                    self.provider,
                    code=str(data.get("resultcode") or resp.status_code),
                    message=str(data.get("message") or "")[:200],
                    retryable=resp.status_code >= 500,
                )
            return PaymentAccepted(
                self.provider,
                provider_ref=str(data.get("transid") or request.reference),
            )
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)

    def refund(self, request: PaymentRequest) -> PaymentResult:
        return PaymentFailed(
            self.provider,
            code="UNSUPPORTED",
            message="Selcom refunds require operator portal / dedicated refund API mapping.",
        )

    def status(self, provider_ref: str) -> PaymentResult:
        if not self.config.is_configured:
            return PaymentFailed(self.provider, code="NOT_CONFIGURED", message="Selcom not configured")
        path = "/v1/checkout/order-status"
        body = {"vendor": self.config.vendor, "order_id": provider_ref}
        try:
            resp = self._session.post(
                f"{self.config.base_url}{path}",
                headers=self._signed_headers(body=body),
                data=json.dumps(body),
                timeout=self.config.timeout_seconds,
            )
            data = resp.json() if resp.content else {}
            payload = data.get("data")
            row = payload[0] if isinstance(payload, list) and payload else (payload if isinstance(payload, dict) else data)
            payment_status = str(row.get("payment_status") or "").upper()
            if payment_status in {"COMPLETED", "SUCCESS", "PAID"}:
                return PaymentAccepted(self.provider, provider_ref=provider_ref, raw_status=payment_status)
            if payment_status in {"CANCELLED", "FAILED"}:
                return PaymentFailed(
                    self.provider, code=payment_status, message="declined", provider_ref=provider_ref
                )
            return PaymentPending(self.provider, provider_ref=provider_ref, raw_status=payment_status or "PENDING")
        except requests.RequestException as exc:
            return PaymentFailed(self.provider, code="NETWORK", message=str(exc), retryable=True)
