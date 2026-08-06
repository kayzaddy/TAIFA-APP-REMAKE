from __future__ import annotations

from rest_framework import serializers

from taifa_merchant.domain.enums import DeviceType, EmployeeRole
from taifa_merchant.infrastructure.models import (
    Branch,
    BranchStatistics,
    Device,
    DeviceAssignment,
    Employee,
    Merchant,
    MerchantNotification,
    MerchantProfile,
    MerchantSettings,
    NotificationPreference,
)


class SignUpSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(min_length=8, write_only=True)
    full_name = serializers.CharField(required=False, allow_blank=True, default="")


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)


class MfaLoginSerializer(LoginSerializer):
    mfa_code = serializers.CharField()


class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()


class AuthResponseSerializer(serializers.Serializer):
    access_token = serializers.CharField()
    token_type = serializers.CharField()
    expires_in = serializers.IntegerField()
    merchant_id = serializers.UUIDField(allow_null=True)
    roles = serializers.ListField(child=serializers.CharField())
    mfa_required = serializers.BooleanField()


class MerchantRegisterSerializer(serializers.Serializer):
    legal_name = serializers.CharField(max_length=255)
    trading_name = serializers.CharField(required=False, allow_blank=True, default="")
    business_category = serializers.CharField(required=False, allow_blank=True, default="")
    tin = serializers.CharField(required=False, allow_blank=True, default="")
    address_line1 = serializers.CharField(required=False, allow_blank=True, default="")
    city = serializers.CharField(required=False, allow_blank=True, default="")
    region = serializers.CharField(required=False, allow_blank=True, default="")
    contact_email = serializers.EmailField(required=False, allow_blank=True)
    contact_phone = serializers.CharField(required=False, allow_blank=True, default="")


class MerchantProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = MerchantProfile
        fields = [
            "description",
            "business_category",
            "tin",
            "address_line1",
            "address_line2",
            "city",
            "region",
            "country",
            "contact_email",
            "contact_phone",
            "logo_s3_key",
            "operating_hours",
            "documents",
        ]


class MerchantSerializer(serializers.ModelSerializer):
    profile = MerchantProfileSerializer(read_only=True)

    class Meta:
        model = Merchant
        fields = [
            "id",
            "tnpi_merchant_id",
            "legal_name",
            "trading_name",
            "status",
            "verification_status",
            "profile",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class MerchantUpdateSerializer(serializers.Serializer):
    legal_name = serializers.CharField(required=False)
    trading_name = serializers.CharField(required=False, allow_blank=True)
    description = serializers.CharField(required=False, allow_blank=True)
    business_category = serializers.CharField(required=False, allow_blank=True)
    tin = serializers.CharField(required=False, allow_blank=True)
    address_line1 = serializers.CharField(required=False, allow_blank=True)
    address_line2 = serializers.CharField(required=False, allow_blank=True)
    city = serializers.CharField(required=False, allow_blank=True)
    region = serializers.CharField(required=False, allow_blank=True)
    country = serializers.CharField(required=False, allow_blank=True, max_length=2)
    contact_email = serializers.EmailField(required=False, allow_blank=True)
    contact_phone = serializers.CharField(required=False, allow_blank=True)
    operating_hours = serializers.JSONField(required=False)
    documents = serializers.JSONField(required=False)
    logo_s3_key = serializers.CharField(required=False, allow_blank=True)


class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = [
            "id",
            "name",
            "code",
            "is_active",
            "operating_hours",
            "address_line1",
            "address_line2",
            "city",
            "region",
            "contact_phone",
            "manager_employee_id",
            "tnpi_branch_id",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "tnpi_branch_id", "created_at", "updated_at"]


class BranchCreateSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    code = serializers.SlugField(max_length=64)
    address_line1 = serializers.CharField(required=False, allow_blank=True, default="")
    city = serializers.CharField(required=False, allow_blank=True, default="")
    contact_phone = serializers.CharField(required=False, allow_blank=True, default="")
    manager_employee_id = serializers.UUIDField(required=False, allow_null=True)
    operating_hours = serializers.JSONField(required=False)


class EmployeeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Employee
        fields = [
            "id",
            "email",
            "full_name",
            "role",
            "status",
            "identity_user_id",
            "invited_at",
            "activated_at",
            "deactivated_at",
        ]
        read_only_fields = ["id", "status", "identity_user_id", "invited_at", "activated_at", "deactivated_at"]


class EmployeeInviteSerializer(serializers.Serializer):
    email = serializers.EmailField()
    full_name = serializers.CharField()
    role = serializers.ChoiceField(choices=EmployeeRole.choices)


class EmployeeRoleSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=EmployeeRole.choices)


class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = [
            "id",
            "name",
            "device_type",
            "status",
            "health",
            "ownership",
            "branch_id",
            "hardware_fingerprint",
            "tnpi_device_id",
            "last_seen_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "status", "health", "tnpi_device_id", "last_seen_at", "created_at", "updated_at"]


class DeviceRegisterSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=128)
    device_type = serializers.ChoiceField(choices=DeviceType.choices, default=DeviceType.MOBILE)
    branch_id = serializers.UUIDField(required=False, allow_null=True)
    hardware_fingerprint = serializers.CharField(required=False, allow_blank=True, default="")


class DeviceAssignSerializer(serializers.Serializer):
    branch_id = serializers.UUIDField(required=False, allow_null=True)
    assigned_employee_id = serializers.UUIDField(required=False, allow_null=True)


class MerchantSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = MerchantSettings
        fields = [
            "language",
            "currency",
            "timezone",
            "business_preferences",
            "payment_preferences",
            "receipt_branding",
            "tax_settings",
            "regional_settings",
            "updated_at",
        ]
        read_only_fields = ["updated_at"]


class MerchantSettingsUpdateSerializer(serializers.Serializer):
    language = serializers.CharField(required=False)
    currency = serializers.CharField(required=False, max_length=3)
    timezone = serializers.CharField(required=False)
    business_preferences = serializers.JSONField(required=False)
    payment_preferences = serializers.JSONField(required=False)
    receipt_branding = serializers.JSONField(required=False)
    tax_settings = serializers.JSONField(required=False)
    regional_settings = serializers.JSONField(required=False)


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = [
            "push_enabled",
            "email_enabled",
            "sms_enabled",
            "system_alerts",
            "merchant_announcements",
            "device_alerts",
            "verification_alerts",
            "channels",
            "updated_at",
        ]
        read_only_fields = ["updated_at"]


class MerchantNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = MerchantNotification
        fields = ["id", "category", "title", "body", "is_read", "metadata", "created_at"]
        read_only_fields = fields


class BranchStatisticsSerializer(serializers.ModelSerializer):
    class Meta:
        model = BranchStatistics
        fields = ["employee_count", "device_count", "activity_score", "updated_at"]


class DeviceAssignmentSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceAssignment
        fields = [
            "id",
            "device_id",
            "branch_id",
            "assigned_employee_id",
            "is_active",
            "assigned_at",
        ]
        read_only_fields = fields
