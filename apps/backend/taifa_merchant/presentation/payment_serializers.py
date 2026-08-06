from __future__ import annotations

from decimal import Decimal

from rest_framework import serializers

from taifa_merchant.domain.payment_enums import QRType
from taifa_merchant.infrastructure.payment_models import (
    MerchantTerminal,
    PaymentLink,
    PaymentTransaction,
    QRPayment,
    Receipt,
    Refund,
)


class SoftposSessionSerializer(serializers.Serializer):
    device_id = serializers.UUIDField()
    amount = serializers.DecimalField(max_digits=14, decimal_places=2, min_value=Decimal("1"))
    currency = serializers.CharField(max_length=3, default="TZS")
    merchant_reference = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")
    branch_id = serializers.UUIDField(required=False, allow_null=True)


class SoftposConfirmSerializer(serializers.Serializer):
    nfc_token = serializers.CharField()
    wallet_hint = serializers.CharField(required=False, allow_blank=True, allow_null=True)


class QRCreateSerializer(serializers.Serializer):
    qr_type = serializers.ChoiceField(choices=QRType.choices)
    amount = serializers.DecimalField(
        max_digits=14, decimal_places=2, required=False, allow_null=True, min_value=Decimal("1")
    )
    currency = serializers.CharField(max_length=3, default="TZS")
    expires_in_seconds = serializers.IntegerField(required=False, allow_null=True, min_value=60)


class PaymentLinkCreateSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=14, decimal_places=2, min_value=Decimal("1"))
    currency = serializers.CharField(max_length=3, default="TZS")
    description = serializers.CharField(max_length=255, required=False, allow_blank=True, default="")
    expires_in_hours = serializers.IntegerField(default=24, min_value=1, max_value=168)
    share = serializers.JSONField(required=False)


class RefundSerializer(serializers.Serializer):
    amount = serializers.DecimalField(max_digits=14, decimal_places=2, required=False, allow_null=True)
    reason = serializers.CharField(max_length=255)
    void = serializers.BooleanField(default=False)


class ReceiptShareSerializer(serializers.Serializer):
    channel = serializers.ChoiceField(choices=["email", "sms", "whatsapp", "link"])
    destination = serializers.CharField(max_length=255)


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentTransaction
        fields = [
            "id",
            "tnpi_payment_id",
            "channel",
            "status",
            "amount",
            "currency",
            "merchant_reference",
            "authorization_code",
            "failure_code",
            "branch_id",
            "device_id",
            "captured_at",
            "created_at",
        ]


class QRSerializer(serializers.ModelSerializer):
    class Meta:
        model = QRPayment
        fields = [
            "id",
            "tnpi_qr_id",
            "qr_type",
            "payload",
            "amount",
            "currency",
            "expires_at",
            "signature",
            "is_revoked",
            "transaction_id",
            "created_at",
        ]


class PaymentLinkSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentLink
        fields = [
            "id",
            "tnpi_link_id",
            "url",
            "amount",
            "currency",
            "description",
            "status",
            "expires_at",
            "share_channels",
            "transaction_id",
            "created_at",
        ]


class ReceiptSerializer(serializers.ModelSerializer):
    transaction = TransactionSerializer(read_only=True)

    class Meta:
        model = Receipt
        fields = [
            "id",
            "receipt_number",
            "verification_code",
            "pdf_s3_key",
            "branding",
            "shared_via",
            "transaction",
            "created_at",
        ]


class RefundSerializerOut(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = ["id", "tnpi_refund_id", "amount", "currency", "reason", "status", "is_void", "created_at"]


class TerminalSerializer(serializers.ModelSerializer):
    class Meta:
        model = MerchantTerminal
        fields = [
            "id",
            "device_id",
            "tnpi_terminal_id",
            "status",
            "softpos_settings",
            "offline_queue_enabled",
            "last_heartbeat_at",
        ]
