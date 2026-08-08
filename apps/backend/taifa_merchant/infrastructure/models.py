from __future__ import annotations

import uuid

from django.db import models

from taifa_merchant.domain.enums import (
    DeviceHealth,
    DeviceStatus,
    DeviceType,
    EmployeeRole,
    EmployeeStatus,
    MerchantStatus,
    VerificationStatus,
)


class MerchantIdentityUser(models.Model):
    """Local mirror for Taifa Identity users (dev/stub until OIDC federation is wired)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True, db_index=True)
    password_hash = models.CharField(max_length=128)
    full_name = models.CharField(max_length=255, blank=True, default="")
    phone = models.CharField(max_length=32, blank=True, default="")
    email_verified = models.BooleanField(default=False)
    mfa_enabled = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_identity_user"


class Merchant(models.Model):
    """Application merchant workspace. TNPI merchant id is authoritative for payments (future)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    tnpi_merchant_id = models.CharField(max_length=64, blank=True, default="", db_index=True)
    legal_name = models.CharField(max_length=255)
    trading_name = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(max_length=32, choices=MerchantStatus.choices, default=MerchantStatus.DRAFT)
    verification_status = models.CharField(
        max_length=32,
        choices=VerificationStatus.choices,
        default=VerificationStatus.NOT_STARTED,
    )
    owner_identity_user_id = models.UUIDField(db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_account"
        indexes = [models.Index(fields=["status", "verification_status"])]


class MerchantProfile(models.Model):
    """Business profile (Sprint 2 operational workspace)."""

    merchant = models.OneToOneField(Merchant, on_delete=models.CASCADE, related_name="profile")
    description = models.TextField(blank=True, default="")
    business_category = models.CharField(max_length=128, blank=True, default="")
    tin = models.CharField(max_length=64, blank=True, default="")
    operating_hours = models.JSONField(default=dict, blank=True)
    documents = models.JSONField(default=list, blank=True)
    address_line1 = models.CharField(max_length=255, blank=True, default="")
    address_line2 = models.CharField(max_length=255, blank=True, default="")
    city = models.CharField(max_length=128, blank=True, default="")
    region = models.CharField(max_length=128, blank=True, default="")
    country = models.CharField(max_length=2, default="TZ")
    contact_email = models.EmailField(blank=True, default="")
    contact_phone = models.CharField(max_length=32, blank=True, default="")
    logo_s3_key = models.CharField(max_length=512, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_profile"


class Branch(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="branches")
    name = models.CharField(max_length=255)
    code = models.SlugField(max_length=64)
    is_active = models.BooleanField(default=True)
    operating_hours = models.JSONField(default=dict, blank=True)
    address_line1 = models.CharField(max_length=255, blank=True, default="")
    address_line2 = models.CharField(max_length=255, blank=True, default="")
    city = models.CharField(max_length=128, blank=True, default="")
    region = models.CharField(max_length=128, blank=True, default="")
    contact_phone = models.CharField(max_length=32, blank=True, default="")
    manager_employee = models.ForeignKey(
        "Employee",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="managed_branches",
    )
    tnpi_branch_id = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_branch"
        unique_together = [("merchant", "code")]
        indexes = [models.Index(fields=["merchant", "is_active"])]


class Employee(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="employees")
    identity_user_id = models.UUIDField(null=True, blank=True, db_index=True)
    email = models.EmailField()
    full_name = models.CharField(max_length=255, blank=True, default="")
    role = models.CharField(max_length=32, choices=EmployeeRole.choices, default=EmployeeRole.CASHIER)
    status = models.CharField(max_length=32, choices=EmployeeStatus.choices, default=EmployeeStatus.INVITED)
    invited_at = models.DateTimeField(auto_now_add=True)
    activated_at = models.DateTimeField(null=True, blank=True)
    deactivated_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_employee"
        unique_together = [("merchant", "email")]
        indexes = [models.Index(fields=["merchant", "status"])]


class Device(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="devices")
    branch = models.ForeignKey(Branch, null=True, blank=True, on_delete=models.SET_NULL, related_name="devices")
    name = models.CharField(max_length=128)
    device_type = models.CharField(max_length=32, choices=DeviceType.choices, default=DeviceType.MOBILE)
    status = models.CharField(max_length=32, choices=DeviceStatus.choices, default=DeviceStatus.PENDING)
    health = models.CharField(max_length=32, choices=DeviceHealth.choices, default=DeviceHealth.UNKNOWN)
    ownership = models.CharField(max_length=128, blank=True, default="merchant")
    hardware_fingerprint = models.CharField(max_length=255, blank=True, default="")
    tnpi_device_id = models.CharField(max_length=64, blank=True, default="")
    registered_by_employee = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="registered_devices",
    )
    last_seen_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_device"
        indexes = [models.Index(fields=["merchant", "status"])]


class AuditLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="audit_logs")
    actor_identity_user_id = models.UUIDField(null=True, blank=True)
    action = models.CharField(max_length=128)
    resource_type = models.CharField(max_length=64)
    resource_id = models.CharField(max_length=64)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_audit_log"
        indexes = [models.Index(fields=["merchant", "created_at"])]


class MerchantSettings(models.Model):
    merchant = models.OneToOneField(Merchant, on_delete=models.CASCADE, related_name="settings")
    language = models.CharField(max_length=16, default="sw")
    currency = models.CharField(max_length=3, default="TZS")
    timezone = models.CharField(max_length=64, default="Africa/Dar_es_Salaam")
    business_preferences = models.JSONField(default=dict, blank=True)
    payment_preferences = models.JSONField(default=dict, blank=True)
    receipt_branding = models.JSONField(default=dict, blank=True)
    tax_settings = models.JSONField(default=dict, blank=True)
    regional_settings = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_settings"


class NotificationPreference(models.Model):
    merchant = models.OneToOneField(Merchant, on_delete=models.CASCADE, related_name="notification_preferences")
    push_enabled = models.BooleanField(default=True)
    email_enabled = models.BooleanField(default=True)
    sms_enabled = models.BooleanField(default=False)
    system_alerts = models.BooleanField(default=True)
    merchant_announcements = models.BooleanField(default=True)
    device_alerts = models.BooleanField(default=True)
    verification_alerts = models.BooleanField(default=True)
    channels = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_notification_preference"


class MerchantNotification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="notifications")
    category = models.CharField(max_length=64, default="system")
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True, default="")
    is_read = models.BooleanField(default=False)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_notification"
        indexes = [models.Index(fields=["merchant", "is_read", "created_at"])]


class DeviceAssignment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    device = models.ForeignKey(Device, on_delete=models.CASCADE, related_name="assignments")
    branch = models.ForeignKey(Branch, null=True, blank=True, on_delete=models.SET_NULL)
    assigned_employee = models.ForeignKey(
        Employee,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="device_assignments",
    )
    is_active = models.BooleanField(default=True)
    assigned_at = models.DateTimeField(auto_now_add=True)
    assigned_by_identity_user_id = models.UUIDField(null=True, blank=True)

    class Meta:
        db_table = "taifa_merchant_device_assignment"
        indexes = [models.Index(fields=["device", "is_active"])]


class BranchStatistics(models.Model):
    branch = models.OneToOneField(Branch, on_delete=models.CASCADE, related_name="statistics")
    employee_count = models.PositiveIntegerField(default=0)
    device_count = models.PositiveIntegerField(default=0)
    activity_score = models.PositiveIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_branch_statistics"


class EmployeePermission(models.Model):
    employee = models.OneToOneField(Employee, on_delete=models.CASCADE, related_name="permissions")
    extra_permissions = models.JSONField(default=list, blank=True)
    denied_permissions = models.JSONField(default=list, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "taifa_merchant_employee_permissions"


class MerchantActivity(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name="activities")
    branch = models.ForeignKey(Branch, null=True, blank=True, on_delete=models.SET_NULL)
    actor_identity_user_id = models.UUIDField(null=True, blank=True)
    activity_type = models.CharField(max_length=64)
    summary = models.CharField(max_length=512)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "taifa_merchant_activity"
        indexes = [models.Index(fields=["merchant", "created_at"])]
