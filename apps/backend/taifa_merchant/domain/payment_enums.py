from __future__ import annotations

from django.db import models


class PaymentChannel(models.TextChoices):
    SOFTPOS = "softpos", "SoftPOS / Tap to Pay"
    QR_STATIC = "qr_static", "Static QR"
    QR_DYNAMIC = "qr_dynamic", "Dynamic QR"
    PAYMENT_LINK = "payment_link", "Payment link"


class PaymentStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    AUTHORIZED = "authorized", "Authorized"
    CAPTURED = "captured", "Captured"
    FAILED = "failed", "Failed"
    VOIDED = "voided", "Voided"
    REFUNDED = "refunded", "Refunded"
    PARTIALLY_REFUNDED = "partially_refunded", "Partially refunded"


class QRType(models.TextChoices):
    STATIC = "static", "Static"
    DYNAMIC = "dynamic", "Dynamic"
    MERCHANT = "merchant", "Merchant"
    CUSTOMER = "customer", "Customer"
    INVOICE = "invoice", "Invoice"


class RefundStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    SUCCEEDED = "succeeded", "Succeeded"
    FAILED = "failed", "Failed"


class TerminalStatus(models.TextChoices):
    INACTIVE = "inactive", "Inactive"
    READY = "ready", "Ready"
    BUSY = "busy", "Busy"
    OFFLINE = "offline", "Offline"


PAYMENT_ROLE_PERMISSIONS: dict[str, frozenset[str]] = {
    "payment:read": frozenset({"payment:read"}),
    "payment:accept": frozenset({"payment:accept"}),
    "payment:refund": frozenset({"payment:refund"}),
}
