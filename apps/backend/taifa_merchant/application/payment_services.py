from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timezone
from decimal import Decimal
from uuid import UUID

from django.db import transaction
from django.db.models import Count, Q, Sum
from django.utils import timezone as dj_tz

from taifa_merchant.application.services import MerchantAppError
from taifa_merchant.application.workspace_services import record_activity
from taifa_merchant.domain.payment_enums import (
    PaymentChannel,
    PaymentStatus,
    QRType,
    RefundStatus,
    TerminalStatus,
)
from taifa_merchant.infrastructure.models import Device, Merchant, MerchantSettings
from taifa_merchant.infrastructure.payment_models import (
    MerchantTerminal,
    PaymentLink,
    PaymentTransaction,
    QRPayment,
    Receipt,
    Refund,
    TransactionAudit,
)
from taifa_merchant.infrastructure.tnpi.payment_client import DevTnpiAcceptanceClient, TnpiAcceptancePort


def _audit_tx(
    *,
    merchant_id: UUID,
    tx: PaymentTransaction,
    action: str,
    actor_id: UUID | None,
    metadata: dict | None = None,
) -> None:
    TransactionAudit.objects.create(
        merchant_id=merchant_id,
        transaction=tx,
        action=action,
        actor_identity_user_id=actor_id,
        metadata=metadata or {},
    )


def _issue_receipt(*, merchant_id: UUID, tx: PaymentTransaction) -> Receipt:
    settings = MerchantSettings.objects.filter(merchant_id=merchant_id).first()
    branding = settings.receipt_branding if settings else {}
    number = f"RCP-{tx.id.hex[:10].upper()}"
    code = secrets.token_hex(4).upper()
    return Receipt.objects.create(
        merchant_id=merchant_id,
        transaction=tx,
        receipt_number=number,
        verification_code=code,
        branding=branding,
        pdf_s3_key=f"receipts/{merchant_id}/{number}.pdf",
    )


class PaymentAcceptanceService:
    def __init__(self, tnpi: TnpiAcceptancePort | None = None) -> None:
        self._tnpi = tnpi or DevTnpiAcceptanceClient()

    def _merchant(self, merchant_id: UUID) -> Merchant:
        return Merchant.objects.get(pk=merchant_id)

    @transaction.atomic
    def register_terminal(self, *, merchant_id: UUID, device_id: UUID, actor_id: UUID) -> MerchantTerminal:
        device = Device.objects.filter(pk=device_id, merchant_id=merchant_id).first()
        if device is None:
            raise MerchantAppError("Device not found", "not_found", 404)
        terminal, created = MerchantTerminal.objects.get_or_create(
            device=device,
            defaults={
                "merchant_id": merchant_id,
                "tnpi_terminal_id": f"term-{device.id.hex[:12]}",
                "status": TerminalStatus.READY,
                "softpos_settings": {"emv_ready": False, "certification": "prep"},
            },
        )
        if not created:
            terminal.status = TerminalStatus.READY
            terminal.save(update_fields=["status", "updated_at"])
        record_activity(
            merchant_id=merchant_id,
            actor_id=actor_id,
            activity_type="terminal.registered",
            summary=f"SoftPOS terminal ready for {device.name}",
        )
        return terminal

    def terminal_status(self, *, merchant_id: UUID, device_id: UUID) -> MerchantTerminal:
        terminal = MerchantTerminal.objects.filter(merchant_id=merchant_id, device_id=device_id).first()
        if terminal is None:
            raise MerchantAppError("Terminal not registered", "not_found", 404)
        return terminal

    @transaction.atomic
    def start_softpos_session(
        self,
        *,
        merchant_id: UUID,
        device_id: UUID,
        amount: Decimal,
        currency: str,
        merchant_reference: str,
        actor_id: UUID,
        branch_id: UUID | None = None,
    ) -> PaymentTransaction:
        merchant = self._merchant(merchant_id)
        terminal = self.terminal_status(merchant_id=merchant_id, device_id=device_id)
        if terminal.status not in (TerminalStatus.READY, TerminalStatus.BUSY):
            raise MerchantAppError("Terminal not ready", "terminal_unavailable", 409)
        idem = f"{merchant_id}:{device_id}:{merchant_reference}:{amount}"
        result = self._tnpi.create_softpos_session(
            tnpi_merchant_id=merchant.tnpi_merchant_id,
            tnpi_terminal_id=terminal.tnpi_terminal_id,
            amount=amount,
            currency=currency,
            idempotency_key=idem,
        )
        tx = PaymentTransaction.objects.create(
            merchant_id=merchant_id,
            branch_id=branch_id,
            device_id=device_id,
            tnpi_payment_id=result.tnpi_payment_id,
            channel=PaymentChannel.SOFTPOS,
            status=PaymentStatus.PENDING,
            amount=amount,
            currency=currency,
            merchant_reference=merchant_reference,
        )
        terminal.status = TerminalStatus.BUSY
        terminal.save(update_fields=["status", "updated_at"])
        _audit_tx(merchant_id=merchant_id, tx=tx, action="softpos.session_started", actor_id=actor_id)
        return tx

    @transaction.atomic
    def confirm_softpos(
        self,
        *,
        merchant_id: UUID,
        transaction_id: UUID,
        nfc_token: str,
        wallet_hint: str | None,
        actor_id: UUID,
    ) -> tuple[PaymentTransaction, Receipt | None]:
        tx = PaymentTransaction.objects.filter(pk=transaction_id, merchant_id=merchant_id).first()
        if tx is None:
            raise MerchantAppError("Transaction not found", "not_found", 404)
        result = self._tnpi.confirm_softpos_tap(
            tnpi_payment_id=tx.tnpi_payment_id,
            nfc_token=nfc_token,
            wallet_hint=wallet_hint,
        )
        tx.status = PaymentStatus.CAPTURED if result.status == "captured" else PaymentStatus.FAILED
        tx.authorization_code = result.authorization_code or ""
        tx.failure_code = result.failure_code or ""
        if tx.status == PaymentStatus.CAPTURED:
            tx.captured_at = dj_tz.now()
        tx.save()
        if tx.device_id:
            MerchantTerminal.objects.filter(device_id=tx.device_id).update(status=TerminalStatus.READY)
        receipt = None
        if tx.status == PaymentStatus.CAPTURED:
            receipt = _issue_receipt(merchant_id=merchant_id, tx=tx)
        _audit_tx(
            merchant_id=merchant_id,
            tx=tx,
            action="softpos.confirmed",
            actor_id=actor_id,
            metadata={"wallet_hint": wallet_hint},
        )
        record_activity(
            merchant_id=merchant_id,
            actor_id=actor_id,
            activity_type="payment.captured" if tx.status == PaymentStatus.CAPTURED else "payment.failed",
            summary=f"SoftPOS {tx.amount} {tx.currency} — {tx.status}",
        )
        return tx, receipt

    @transaction.atomic
    def create_qr(
        self,
        *,
        merchant_id: UUID,
        qr_type: str,
        amount: Decimal | None,
        currency: str,
        expires_in_seconds: int | None,
        actor_id: UUID,
    ) -> QRPayment:
        merchant = self._merchant(merchant_id)
        result = self._tnpi.create_qr(
            tnpi_merchant_id=merchant.tnpi_merchant_id,
            qr_type=qr_type,
            amount=amount,
            currency=currency,
            expires_in_seconds=expires_in_seconds,
        )
        sig = hashlib.sha256(result.payload.encode()).hexdigest()[:32]
        qr = QRPayment.objects.create(
            merchant_id=merchant_id,
            tnpi_qr_id=result.tnpi_qr_id,
            qr_type=qr_type,
            payload=result.payload,
            amount=amount,
            currency=currency,
            expires_at=result.expires_at,
            signature=sig,
        )
        _audit_tx_placeholder(merchant_id, "qr.created", actor_id, {"qr_id": str(qr.id)})
        return qr

    @transaction.atomic
    def complete_qr_payment(
        self,
        *,
        merchant_id: UUID,
        qr_id: UUID,
        actor_id: UUID,
    ) -> tuple[PaymentTransaction, Receipt]:
        qr = QRPayment.objects.filter(pk=qr_id, merchant_id=merchant_id, is_revoked=False).first()
        if qr is None:
            raise MerchantAppError("QR not found", "not_found", 404)
        if qr.expires_at and qr.expires_at < dj_tz.now():
            raise MerchantAppError("QR expired", "qr_expired", 410)
        amount = qr.amount or Decimal("1000")
        result = self._tnpi.simulate_qr_paid(tnpi_qr_id=qr.tnpi_qr_id, amount=amount, currency=qr.currency)
        channel = PaymentChannel.QR_STATIC if qr.qr_type == QRType.STATIC else PaymentChannel.QR_DYNAMIC
        tx = PaymentTransaction.objects.create(
            merchant_id=merchant_id,
            tnpi_payment_id=result.tnpi_payment_id,
            channel=channel,
            status=PaymentStatus.CAPTURED,
            amount=amount,
            currency=qr.currency,
            authorization_code=result.authorization_code or "",
            captured_at=dj_tz.now(),
        )
        qr.transaction = tx
        qr.save(update_fields=["transaction"])
        receipt = _issue_receipt(merchant_id=merchant_id, tx=tx)
        _audit_tx(merchant_id=merchant_id, tx=tx, action="qr.paid", actor_id=actor_id)
        return tx, receipt

    @transaction.atomic
    def create_payment_link(
        self,
        *,
        merchant_id: UUID,
        amount: Decimal,
        currency: str,
        description: str,
        expires_in_hours: int,
        actor_id: UUID,
        share: dict | None = None,
    ) -> PaymentLink:
        merchant = self._merchant(merchant_id)
        result = self._tnpi.create_payment_link(
            tnpi_merchant_id=merchant.tnpi_merchant_id,
            amount=amount,
            currency=currency,
            description=description,
            expires_in_hours=expires_in_hours,
        )
        link = PaymentLink.objects.create(
            merchant_id=merchant_id,
            tnpi_link_id=result.tnpi_link_id,
            url=result.url,
            amount=amount,
            currency=currency,
            description=description,
            expires_at=result.expires_at,
            share_channels=share or {},
        )
        return link

    @transaction.atomic
    def complete_link_payment(
        self,
        *,
        merchant_id: UUID,
        link_id: UUID,
        actor_id: UUID,
    ) -> tuple[PaymentTransaction, Receipt]:
        link = PaymentLink.objects.filter(pk=link_id, merchant_id=merchant_id, status="active").first()
        if link is None:
            raise MerchantAppError("Link not found", "not_found", 404)
        if link.expires_at < dj_tz.now():
            raise MerchantAppError("Link expired", "link_expired", 410)
        result = self._tnpi.simulate_link_paid(tnpi_link_id=link.tnpi_link_id)
        tx = PaymentTransaction.objects.create(
            merchant_id=merchant_id,
            tnpi_payment_id=result.tnpi_payment_id,
            channel=PaymentChannel.PAYMENT_LINK,
            status=PaymentStatus.CAPTURED,
            amount=link.amount,
            currency=link.currency,
            authorization_code=result.authorization_code or "",
            captured_at=dj_tz.now(),
            merchant_reference=link.description,
        )
        link.transaction = tx
        link.status = "paid"
        link.save(update_fields=["transaction", "status"])
        receipt = _issue_receipt(merchant_id=merchant_id, tx=tx)
        _audit_tx(merchant_id=merchant_id, tx=tx, action="link.paid", actor_id=actor_id)
        return tx, receipt

    def list_transactions(
        self,
        *,
        merchant_id: UUID,
        query: str = "",
        status: str | None = None,
        channel: str | None = None,
        limit: int = 50,
    ) -> list[PaymentTransaction]:
        qs = PaymentTransaction.objects.filter(merchant_id=merchant_id).order_by("-created_at")
        if status:
            qs = qs.filter(status=status)
        if channel:
            qs = qs.filter(channel=channel)
        if query:
            qs = qs.filter(
                Q(merchant_reference__icontains=query)
                | Q(tnpi_payment_id__icontains=query)
                | Q(authorization_code__icontains=query)
            )
        return list(qs[:limit])

    def get_transaction(self, *, merchant_id: UUID, transaction_id: UUID) -> PaymentTransaction:
        tx = PaymentTransaction.objects.filter(pk=transaction_id, merchant_id=merchant_id).first()
        if tx is None:
            raise MerchantAppError("Transaction not found", "not_found", 404)
        return tx

    @transaction.atomic
    def refund(
        self,
        *,
        merchant_id: UUID,
        transaction_id: UUID,
        amount: Decimal | None,
        reason: str,
        actor_id: UUID,
        void: bool = False,
    ) -> Refund:
        tx = self.get_transaction(merchant_id=merchant_id, transaction_id=transaction_id)
        if tx.status not in (PaymentStatus.CAPTURED, PaymentStatus.PARTIALLY_REFUNDED):
            raise MerchantAppError("Transaction not refundable", "invalid_state", 400)
        refund_amount = amount if amount is not None else tx.amount
        if void:
            self._tnpi.void_payment(tnpi_payment_id=tx.tnpi_payment_id, reason=reason)
            tx.status = PaymentStatus.VOIDED
            tnpi_refund_id = f"void_{tx.tnpi_payment_id}"
        else:
            idem = f"refund:{tx.id}:{refund_amount}"
            refund_result = self._tnpi.refund(
                tnpi_payment_id=tx.tnpi_payment_id,
                amount=refund_amount,
                reason=reason,
                idempotency_key=idem,
            )
            tnpi_refund_id = refund_result.tnpi_refund_id
            if refund_amount >= tx.amount:
                tx.status = PaymentStatus.REFUNDED
            else:
                tx.status = PaymentStatus.PARTIALLY_REFUNDED
        tx.save(update_fields=["status", "updated_at"])
        refund = Refund.objects.create(
            merchant_id=merchant_id,
            transaction=tx,
            tnpi_refund_id=tnpi_refund_id,
            amount=refund_amount,
            currency=tx.currency,
            reason=reason,
            status=RefundStatus.SUCCEEDED,
            is_void=void,
            actor_identity_user_id=actor_id,
        )
        _audit_tx(
            merchant_id=merchant_id,
            tx=tx,
            action="void" if void else "refund",
            actor_id=actor_id,
            metadata={"amount": str(refund_amount), "reason": reason},
        )
        return refund

    def get_receipt(self, *, merchant_id: UUID, receipt_id: UUID) -> Receipt:
        r = Receipt.objects.filter(pk=receipt_id, merchant_id=merchant_id).select_related("transaction").first()
        if r is None:
            raise MerchantAppError("Receipt not found", "not_found", 404)
        return r

    def share_receipt(
        self,
        *,
        merchant_id: UUID,
        receipt_id: UUID,
        channel: str,
        destination: str,
        actor_id: UUID,
    ) -> Receipt:
        receipt = self.get_receipt(merchant_id=merchant_id, receipt_id=receipt_id)
        shared = list(receipt.shared_via)
        shared.append({"channel": channel, "destination": destination, "at": datetime.now(timezone.utc).isoformat()})
        receipt.shared_via = shared
        receipt.save(update_fields=["shared_via"])
        return receipt

    def analytics_today(self, *, merchant_id: UUID) -> dict:
        today = dj_tz.now().date()
        qs = PaymentTransaction.objects.filter(merchant_id=merchant_id, created_at__date=today)
        captured = qs.filter(status=PaymentStatus.CAPTURED)
        failed = qs.filter(status=PaymentStatus.FAILED)
        refunds = Refund.objects.filter(merchant_id=merchant_id, created_at__date=today, status=RefundStatus.SUCCEEDED)
        revenue = captured.aggregate(total=Sum("amount"))["total"] or Decimal("0")
        by_channel = list(captured.values("channel").annotate(count=Count("id"), total=Sum("amount")))
        return {
            "date": today.isoformat(),
            "transaction_count": qs.count(),
            "successful_payments": captured.count(),
            "failed_payments": failed.count(),
            "refund_count": refunds.count(),
            "revenue": str(revenue),
            "currency": "TZS",
            "payment_methods": by_channel,
            "device_activity": Device.objects.filter(merchant_id=merchant_id, status="active").count(),
        }


def _audit_tx_placeholder(merchant_id: UUID, action: str, actor_id: UUID, metadata: dict) -> None:
    record_activity(merchant_id=merchant_id, actor_id=actor_id, activity_type=action, summary=action, metadata=metadata)
