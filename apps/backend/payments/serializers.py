from __future__ import annotations

from rest_framework import serializers

from .models import Transaction


class TransactionSerializer(serializers.ModelSerializer):
    amount_display = serializers.SerializerMethodField()

    class Meta:
        model = Transaction
        fields = [
            "id", "type", "status", "direction", "amount_minor", "fee_minor",
            "currency", "amount_display", "counterparty", "method_kind",
            "method_ref", "operator", "provider", "provider_ref", "note",
            "parent", "ledger_entry", "created_at", "updated_at",
        ]

    def get_amount_display(self, obj: Transaction) -> str:
        return obj.amount.format()


class TopUpRequestSerializer(serializers.Serializer):
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    msisdn = serializers.CharField()
    operator = serializers.CharField(default="mpesa")
    note = serializers.CharField(required=False, allow_blank=True, default="")


class TransferRequestSerializer(serializers.Serializer):
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    counterparty = serializers.CharField()
    method_kind = serializers.ChoiceField(choices=["mobile_money", "card", "bank", "wallet"])
    method_ref = serializers.CharField(allow_blank=True, default="")
    operator = serializers.CharField(required=False, allow_blank=True, default="")
    note = serializers.CharField(required=False, allow_blank=True, default="")


class WithdrawalRequestSerializer(serializers.Serializer):
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    method_kind = serializers.ChoiceField(choices=["mobile_money", "bank"])
    method_ref = serializers.CharField()
    operator = serializers.CharField(required=False, allow_blank=True, default="")
    counterparty = serializers.CharField(required=False, allow_blank=True, default="")
    note = serializers.CharField(required=False, allow_blank=True, default="")


class RefundRequestSerializer(serializers.Serializer):
    original_transaction_id = serializers.UUIDField()
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.CharField(default="TZS")
    note = serializers.CharField(required=False, allow_blank=True, default="")


class ReverseRequestSerializer(serializers.Serializer):
    note = serializers.CharField(required=False, allow_blank=True, default="")


class DeviceRegisterSerializer(serializers.Serializer):
    device_id = serializers.CharField(max_length=128)
    label = serializers.CharField(required=False, allow_blank=True, default="")
    platform = serializers.CharField(required=False, allow_blank=True, default="")
    push_token = serializers.CharField(required=False, allow_blank=True, default="")


class DevicePushTokenSerializer(serializers.Serializer):
    push_token = serializers.CharField(max_length=255)


class DeviceRegisterResponseSerializer(serializers.Serializer):
    """Response shape for device registration (documentation only)."""

    token = serializers.CharField()
    device_id = serializers.CharField()
    owner = serializers.CharField()
    currency = serializers.CharField()
    balance_minor = serializers.IntegerField()
    balance_display = serializers.CharField()


class WalletSerializer(serializers.Serializer):
    """Response shape for `GET /wallet` (documentation only)."""

    owner = serializers.CharField()
    currency = serializers.CharField()
    balance_minor = serializers.IntegerField()
    balance_display = serializers.CharField()
    transactions = TransactionSerializer(many=True)
