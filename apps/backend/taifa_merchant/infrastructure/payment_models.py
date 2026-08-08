from __future__ import annotations

import uuid

from django.db import models

from taifa_merchant.domain.payment_enums import (
    PaymentChannel,
    PaymentStatus,
    QRType,
    RefundStatus,
    TerminalStatus,
)
from taifa_merchant.infrastructure.models import Branch, Device, Merchant


class MerchantTerminal(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="terminals")
    device = models.OneToOneField(Device, on_delete=models.CASCADE, related_name="terminal")
    tnpi_terminal_id = models.CharField(max_length=64, db_index=True)
    status = models.CharField(max_length=32, choices=TerminalStatus.choices, default=TerminalStatus.INACTIVE)
    softpos_settings = models.JSONField(default=dict, blank=True)
    offline_queue_enabled = models.BooleanField(default=True)
    last_heartbeat_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_terminal"


class PaymentTransaction(models.Model):
    """Merchant-facing transaction mirror; TNPI owns orchestration/settlement SoR."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="transactions")
    branch = models.ForeignKey(Branch, null=True, blank=True, on_delete=models.SET_NULL)
    device = models.ForeignKey(Device, null=True, blank=True, on_delete=models.SET_NULL)
    tnpi_payment_id = models.CharField(max_length=64, db_index=True)
    channel = models.CharField(max_length=32, choices=PaymentChannel.choices)
    status = models.CharField(max_length=32, choices=PaymentStatus.choices, default=PaymentStatus.PENDING)
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    currency = models.CharField(max_length=3, default="TZS")
    merchant_reference = models.CharField(max_length=128, blank=True, default="", db_index=True)
    authorization_code = models.CharField(max_length=32, blank=True, default="")
    failure_code = models.CharField(max_length=64, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    captured_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_payment_transaction"
        indexes = [
            models.Index(fields=["merchant", "created_at"]),
            models.Index(fields=["merchant", "status"]),
        ]


class QRPayment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="qr_payments")
    transaction = models.ForeignKey(
        PaymentTransaction,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="qr_sessions",
    )
    tnpi_qr_id = models.CharField(max_length=64, db_index=True)
    qr_type = models.CharField(max_length=32, choices=QRType.choices)
    payload = models.TextField()
    amount = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    currency = models.CharField(max_length=3, default="TZS")
    expires_at = models.DateTimeField(null=True, blank=True)
    is_revoked = models.BooleanField(default=False)
    signature = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_qr_payment"


class PaymentLink(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="payment_links")
    transaction = models.ForeignKey(
        PaymentTransaction,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="payment_links",
    )
    tnpi_link_id = models.CharField(max_length=64, db_index=True)
    url = models.URLField(max_length=512)
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    currency = models.CharField(max_length=3, default="TZS")
    description = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=32, default="active")
    expires_at = models.DateTimeField()
    share_channels = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_payment_link"


class Refund(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="refunds")
    transaction = models.ForeignKey(PaymentTransaction, on_delete=models.CASCADE, related_name="refunds")
    tnpi_refund_id = models.CharField(max_length=64, db_index=True)
    amount = models.DecimalField(max_digits=14, decimal_places=2)
    currency = models.CharField(max_length=3, default="TZS")
    reason = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=32, choices=RefundStatus.choices, default=RefundStatus.PENDING)
    is_void = models.BooleanField(default=False)
    actor_identity_user_id = models.UUIDField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_refund"


class Receipt(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="receipts")
    transaction = models.OneToOneField(PaymentTransaction, on_delete=models.CASCADE, related_name="receipt")
    receipt_number = models.CharField(max_length=64, unique=True)
    pdf_s3_key = models.CharField(max_length=512, blank=True, default="")
    verification_code = models.CharField(max_length=32, db_index=True)
    branding = models.JSONField(default=dict, blank=True)
    shared_via = models.JSONField(default=list, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_receipt"


class TransactionAudit(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="transaction_audits")
    transaction = models.ForeignKey(PaymentTransaction, on_delete=models.CASCADE, related_name="audits")
    action = models.CharField(max_length=64)
    actor_identity_user_id = models.UUIDField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_transaction_audit"
        indexes = [models.Index(fields=["transaction", "created_at"])]
