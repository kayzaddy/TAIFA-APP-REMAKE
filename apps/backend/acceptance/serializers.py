from rest_framework import serializers

from .models import (
    AcceptanceIntent,
    AcceptanceProfile,
    AcceptanceReceipt,
    AcceptanceTerminal,
    CheckoutSession,
    DigitalInvoice,
    PaymentLink,
    QrArtifact,
    TapSession,
    WalletFundingPreference,
)


class AcceptanceProfileSerializer(serializers.ModelSerializer):
    merchant_id = serializers.UUIDField(read_only=True)
    merchant_code = serializers.CharField(source="merchant.code", read_only=True)

    class Meta:
        model = AcceptanceProfile
        fields = [
            "id",
            "merchant_id",
            "merchant_code",
            "display_name",
            "logo_url",
            "default_currency",
            "accepted_methods",
            "receipt_preferences",
            "branding",
            "branch_config",
            "store_config",
            "terminal_config",
            "qr_identity",
            "active",
            "created_at",
            "updated_at",
        ]


class AcceptanceIntentSerializer(serializers.ModelSerializer):
    merchant_code = serializers.CharField(source="merchant.code", read_only=True)
    remaining_minor = serializers.IntegerField(read_only=True)

    class Meta:
        model = AcceptanceIntent
        fields = [
            "id",
            "public_code",
            "merchant_code",
            "channel",
            "status",
            "amount_minor",
            "amount_paid_minor",
            "remaining_minor",
            "currency",
            "description",
            "metadata",
            "sales_order_id",
            "winga_deal_id",
            "trip_id",
            "invoice_id",
            "expires_at",
            "max_uses",
            "use_count",
            "payment_ref",
            "payer_principal",
            "paid_at",
            "created_at",
        ]


class QrArtifactSerializer(serializers.ModelSerializer):
    intent_code = serializers.CharField(source="intent.public_code", read_only=True, allow_null=True)

    class Meta:
        model = QrArtifact
        fields = [
            "id",
            "public_code",
            "kind",
            "payload",
            "signature",
            "intent_code",
            "branch_ref",
            "terminal_ref",
            "expires_at",
            "active",
            "scan_count",
            "created_at",
        ]


class PaymentLinkSerializer(serializers.ModelSerializer):
    intent_code = serializers.CharField(source="intent.public_code", read_only=True)
    pay_path = serializers.SerializerMethodField()

    class Meta:
        model = PaymentLink
        fields = [
            "id",
            "public_code",
            "path_token",
            "pay_path",
            "purpose",
            "intent_code",
            "signature",
            "expires_at",
            "max_uses",
            "use_count",
            "branding",
            "active",
            "created_at",
        ]

    def get_pay_path(self, obj) -> str:
        return f"/map/pay/{obj.path_token}"


class DigitalInvoiceSerializer(serializers.ModelSerializer):
    remaining_minor = serializers.IntegerField(read_only=True)

    class Meta:
        model = DigitalInvoice
        fields = [
            "id",
            "public_code",
            "invoice_number",
            "customer_name",
            "customer_ref",
            "line_items",
            "amount_minor",
            "amount_paid_minor",
            "remaining_minor",
            "currency",
            "allow_partial",
            "installment_plan",
            "due_at",
            "status",
            "reminder_count",
            "created_at",
            "updated_at",
        ]


class CheckoutSessionSerializer(serializers.ModelSerializer):
    intent_code = serializers.CharField(source="intent.public_code", read_only=True)

    class Meta:
        model = CheckoutSession
        fields = [
            "id",
            "public_code",
            "intent_code",
            "mode",
            "return_url",
            "cancel_url",
            "status",
            "expires_at",
            "metadata",
            "created_at",
        ]


class AcceptanceTerminalSerializer(serializers.ModelSerializer):
    class Meta:
        model = AcceptanceTerminal
        fields = [
            "id",
            "code",
            "label",
            "kind",
            "branch_ref",
            "pairing_token",
            "softpos_ready",
            "nfc_ready",
            "active",
            "last_seen_at",
            "created_at",
        ]


class AcceptanceReceiptSerializer(serializers.ModelSerializer):
    class Meta:
        model = AcceptanceReceipt
        fields = [
            "id",
            "public_code",
            "payment_ref",
            "amount_minor",
            "currency",
            "channel",
            "merchant_display",
            "payer_principal",
            "delivery",
            "verification_qr",
            "body",
            "created_at",
        ]


class WalletFundingPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = WalletFundingPreference
        fields = [
            "owner_principal",
            "priority",
            "auto_route",
            "require_confirmation",
            "auth_policy",
            "low_risk_threshold_minor",
            "merchant_overrides",
            "updated_at",
            "created_at",
        ]


class TapSessionSerializer(serializers.ModelSerializer):
    intent_code = serializers.CharField(source="intent.public_code", read_only=True, allow_null=True)
    merchant_code = serializers.CharField(source="merchant.code", read_only=True)

    class Meta:
        model = TapSession
        fields = [
            "id",
            "public_code",
            "merchant_code",
            "intent_code",
            "channel",
            "status",
            "amount_minor",
            "currency",
            "payer_principal",
            "selected_funding",
            "auth_required",
            "auth_method",
            "auth_completed",
            "merchant_display",
            "terminal_capability",
            "nfc_meta",
            "failure_reason",
            "payment_ref",
            "receipt_code",
            "expires_at",
            "completed_at",
            "created_at",
        ]
