from __future__ import annotations

import hashlib
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from decimal import Decimal
from typing import Protocol
from uuid import UUID, uuid4


@dataclass
class TnpiPaymentResult:
    tnpi_payment_id: str
    status: str
    authorization_code: str | None = None
    failure_code: str | None = None


@dataclass
class TnpiQrResult:
    tnpi_qr_id: str
    payload: str
    expires_at: datetime | None


@dataclass
class TnpiLinkResult:
    tnpi_link_id: str
    url: str
    expires_at: datetime


@dataclass
class TnpiRefundResult:
    tnpi_refund_id: str
    status: str


class TnpiAcceptancePort(Protocol):
    """MAP / Developer Platform facade — all money movement via TNPI orchestration (no duplicate logic)."""

    def create_softpos_session(
        self,
        *,
        tnpi_merchant_id: str,
        tnpi_terminal_id: str,
        amount: Decimal,
        currency: str,
        idempotency_key: str,
    ) -> TnpiPaymentResult: ...

    def confirm_softpos_tap(
        self,
        *,
        tnpi_payment_id: str,
        nfc_token: str,
        wallet_hint: str | None,
    ) -> TnpiPaymentResult: ...

    def create_qr(
        self,
        *,
        tnpi_merchant_id: str,
        qr_type: str,
        amount: Decimal | None,
        currency: str,
        expires_in_seconds: int | None,
    ) -> TnpiQrResult: ...

    def create_payment_link(
        self,
        *,
        tnpi_merchant_id: str,
        amount: Decimal,
        currency: str,
        description: str,
        expires_in_hours: int,
    ) -> TnpiLinkResult: ...

    def simulate_link_paid(self, *, tnpi_link_id: str) -> TnpiPaymentResult: ...

    def simulate_qr_paid(self, *, tnpi_qr_id: str, amount: Decimal, currency: str) -> TnpiPaymentResult: ...

    def refund(
        self,
        *,
        tnpi_payment_id: str,
        amount: Decimal,
        reason: str,
        idempotency_key: str,
    ) -> TnpiRefundResult: ...

    def void_payment(self, *, tnpi_payment_id: str, reason: str) -> TnpiPaymentResult: ...


class DevTnpiAcceptanceClient:
    """
    Development stub for MAP → Orchestration → PSP.
    Production: HTTP client via TIP to TNPI Developer Platform routes.
    """

    def create_softpos_session(
        self,
        *,
        tnpi_merchant_id: str,
        tnpi_terminal_id: str,
        amount: Decimal,
        currency: str,
        idempotency_key: str,
    ) -> TnpiPaymentResult:
        pid = f"pay_{hashlib.sha256(idempotency_key.encode()).hexdigest()[:16]}"
        return TnpiPaymentResult(tnpi_payment_id=pid, status="pending")

    def confirm_softpos_tap(
        self,
        *,
        tnpi_payment_id: str,
        nfc_token: str,
        wallet_hint: str | None,
    ) -> TnpiPaymentResult:
        if not nfc_token or nfc_token == "decline":
            return TnpiPaymentResult(
                tnpi_payment_id=tnpi_payment_id,
                status="failed",
                failure_code="card_declined",
            )
        return TnpiPaymentResult(
            tnpi_payment_id=tnpi_payment_id,
            status="captured",
            authorization_code=secrets.token_hex(3).upper(),
        )

    def create_qr(
        self,
        *,
        tnpi_merchant_id: str,
        qr_type: str,
        amount: Decimal | None,
        currency: str,
        expires_in_seconds: int | None,
    ) -> TnpiQrResult:
        qid = f"qr_{uuid4().hex[:12]}"
        amt = amount or Decimal("0")
        payload = f"TAIFA|{tnpi_merchant_id}|{qr_type}|{amt}|{currency}|{qid}"
        exp = None
        if expires_in_seconds:
            exp = datetime.now(timezone.utc) + timedelta(seconds=expires_in_seconds)
        return TnpiQrResult(tnpi_qr_id=qid, payload=payload, expires_at=exp)

    def create_payment_link(
        self,
        *,
        tnpi_merchant_id: str,
        amount: Decimal,
        currency: str,
        description: str,
        expires_in_hours: int,
    ) -> TnpiLinkResult:
        lid = f"link_{uuid4().hex[:12]}"
        url = f"https://pay.taifa.local/l/{lid}"
        exp = datetime.now(timezone.utc) + timedelta(hours=expires_in_hours)
        return TnpiLinkResult(tnpi_link_id=lid, url=url, expires_at=exp)

    def simulate_link_paid(self, *, tnpi_link_id: str) -> TnpiPaymentResult:
        return TnpiPaymentResult(
            tnpi_payment_id=f"pay_{tnpi_link_id}",
            status="captured",
            authorization_code=secrets.token_hex(3).upper(),
        )

    def simulate_qr_paid(self, *, tnpi_qr_id: str, amount: Decimal, currency: str) -> TnpiPaymentResult:
        return TnpiPaymentResult(
            tnpi_payment_id=f"pay_{tnpi_qr_id}",
            status="captured",
            authorization_code=secrets.token_hex(3).upper(),
        )

    def refund(
        self,
        *,
        tnpi_payment_id: str,
        amount: Decimal,
        reason: str,
        idempotency_key: str,
    ) -> TnpiRefundResult:
        return TnpiRefundResult(tnpi_refund_id=f"rf_{uuid4().hex[:12]}", status="succeeded")

    def void_payment(self, *, tnpi_payment_id: str, reason: str) -> TnpiPaymentResult:
        return TnpiPaymentResult(tnpi_payment_id=tnpi_payment_id, status="voided")
