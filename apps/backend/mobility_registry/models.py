"""National Mobility Registry — source of truth for participant eligibility."""
from __future__ import annotations

import uuid

from django.db import models
from django.db.models import Q
from django.utils import timezone

from trips.models import TransportMode


class ApplicationType(models.TextChoices):
    DRIVER = "driver"
    VEHICLE = "vehicle"
    STATION = "station"
    FLEET = "fleet"
    TRANSPORT_COMPANY = "transport_company"


class ApplicationStatus(models.TextChoices):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    PENDING_REVIEW = "pending_review"
    DOCUMENTS_MISSING = "documents_missing"
    REJECTED = "rejected"
    SUSPENDED = "suspended"
    APPROVED = "approved"
    BLOCKED = "blocked"


class VerificationStage(models.TextChoices):
    DRAFT = "draft"
    DOCUMENT_VALIDATION = "document_validation"
    IDENTITY_VALIDATION = "identity_validation"
    VEHICLE_VALIDATION = "vehicle_validation"
    STATION_VALIDATION = "station_validation"
    COMPLIANCE_REVIEW = "compliance_review"
    APPROVAL = "approval"
    COMPLETE = "complete"


class DocumentStatus(models.TextChoices):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"
    EXPIRED = "expired"
    SUPERSEDED = "superseded"


class RegistryApplication(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application_number = models.CharField(max_length=32, unique=True, db_index=True)
    application_type = models.CharField(max_length=32, choices=ApplicationType.choices, db_index=True)
    applicant_principal = models.CharField(max_length=128, db_index=True)
    client_reference = models.CharField(max_length=64)
    status = models.CharField(
        max_length=24, choices=ApplicationStatus.choices, default=ApplicationStatus.DRAFT, db_index=True
    )
    stage = models.CharField(
        max_length=32, choices=VerificationStage.choices, default=VerificationStage.DRAFT, db_index=True
    )
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, db_index=True)
    assigned_reviewer = models.CharField(max_length=128, blank=True, default="", db_index=True)
    rejection_reason = models.CharField(max_length=500, blank=True, default="")
    approval_reference = models.CharField(max_length=64, blank=True, default=None, unique=True, null=True)
    operational_object_id = models.UUIDField(null=True, blank=True)
    version = models.PositiveIntegerField(default=1)
    submitted_at = models.DateTimeField(null=True, blank=True)
    approved_at = models.DateTimeField(null=True, blank=True)
    rejected_at = models.DateTimeField(null=True, blank=True)
    suspended_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["application_type", "status", "created_at"]),
            models.Index(fields=["region", "district", "status"]),
            models.Index(fields=["assigned_reviewer", "status"]),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=["applicant_principal", "client_reference"],
                name="registry_unique_client_submission",
            )
        ]

    def __str__(self) -> str:
        return f"{self.application_number} [{self.status}]"


class DriverRegistration(models.Model):
    application = models.OneToOneField(
        RegistryApplication, primary_key=True, on_delete=models.CASCADE, related_name="driver"
    )
    full_name = models.CharField(max_length=255, db_index=True)
    pii_key_version = models.CharField(max_length=32)
    national_id_ciphertext = models.BinaryField()
    national_id_nonce = models.BinaryField(max_length=12)
    national_id_hash = models.CharField(max_length=64, unique=True, db_index=True)
    national_id_masked = models.CharField(max_length=32)
    passport_ciphertext = models.BinaryField(null=True, blank=True)
    passport_nonce = models.BinaryField(max_length=12, null=True, blank=True)
    passport_hash = models.CharField(max_length=64, blank=True, default="", db_index=True)
    phone_ciphertext = models.BinaryField()
    phone_nonce = models.BinaryField(max_length=12)
    phone_hash = models.CharField(max_length=64, db_index=True)
    phone_masked = models.CharField(max_length=32)
    email = models.EmailField(blank=True, default="")
    gender = models.CharField(max_length=24)
    date_of_birth = models.DateField()
    nationality = models.CharField(max_length=64, default="Tanzanian")
    ward = models.CharField(max_length=128, blank=True, default="")
    street = models.CharField(max_length=255, blank=True, default="")
    postal_address = models.CharField(max_length=255, blank=True, default="")
    emergency_contact_name = models.CharField(max_length=128)
    emergency_phone_ciphertext = models.BinaryField()
    emergency_phone_nonce = models.BinaryField(max_length=12)
    emergency_phone_masked = models.CharField(max_length=32)
    preferred_station = models.ForeignKey(
        "trips.Station", null=True, blank=True, on_delete=models.SET_NULL, related_name="registry_applicants"
    )
    preferred_language = models.CharField(max_length=16, default="sw")
    bank_account_ciphertext = models.BinaryField(null=True, blank=True)
    bank_account_nonce = models.BinaryField(max_length=12, null=True, blank=True)
    wallet_account_ref = models.CharField(max_length=128)


class VehicleRegistration(models.Model):
    application = models.OneToOneField(
        RegistryApplication, primary_key=True, on_delete=models.CASCADE, related_name="vehicle"
    )
    pii_key_version = models.CharField(max_length=32)
    mode = models.CharField(max_length=24, choices=TransportMode.choices)
    registration_number = models.CharField(max_length=32, unique=True, db_index=True)
    registration_number_hash = models.CharField(max_length=64, unique=True, db_index=True)
    chassis_number_hash = models.CharField(max_length=64, unique=True, db_index=True)
    chassis_number_ciphertext = models.BinaryField()
    chassis_number_nonce = models.BinaryField(max_length=12)
    engine_number_hash = models.CharField(max_length=64, unique=True, db_index=True)
    engine_number_ciphertext = models.BinaryField()
    engine_number_nonce = models.BinaryField(max_length=12)
    make = models.CharField(max_length=64)
    model = models.CharField(max_length=64)
    year = models.PositiveSmallIntegerField()
    fuel_type = models.CharField(max_length=32)
    color = models.CharField(max_length=32)
    capacity = models.PositiveSmallIntegerField()
    owner_principal = models.CharField(max_length=128, db_index=True)
    assigned_driver_application = models.ForeignKey(
        RegistryApplication,
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="assigned_vehicle_applications",
        limit_choices_to={"application_type": ApplicationType.DRIVER},
    )


class StationRegistration(models.Model):
    application = models.OneToOneField(
        RegistryApplication, primary_key=True, on_delete=models.CASCADE, related_name="station"
    )
    pii_key_version = models.CharField(max_length=32)
    name = models.CharField(max_length=255, db_index=True)
    code = models.SlugField(max_length=64, unique=True, db_index=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    ward = models.CharField(max_length=128, blank=True, default="")
    street = models.CharField(max_length=255, blank=True, default="")
    manager_principal = models.CharField(max_length=128, db_index=True)
    phone_ciphertext = models.BinaryField()
    phone_nonce = models.BinaryField(max_length=12)
    phone_hash = models.CharField(max_length=64, db_index=True)
    phone_masked = models.CharField(max_length=32)
    email = models.EmailField(blank=True, default="")
    operating_hours = models.JSONField(default=dict)
    capacity = models.PositiveIntegerField()
    description = models.TextField(blank=True, default="")

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=Q(latitude__gte=-90, latitude__lte=90),
                name="registry_station_valid_latitude",
            ),
            models.CheckConstraint(
                condition=Q(longitude__gte=-180, longitude__lte=180),
                name="registry_station_valid_longitude",
            ),
        ]


class FleetRegistration(models.Model):
    application = models.OneToOneField(
        RegistryApplication, primary_key=True, on_delete=models.CASCADE, related_name="fleet"
    )
    pii_key_version = models.CharField(max_length=32)
    fleet_type = models.CharField(max_length=24)
    business_name = models.CharField(max_length=255, db_index=True)
    brela_number_hash = models.CharField(max_length=64, blank=True, default="", db_index=True)
    brela_number_ciphertext = models.BinaryField(null=True, blank=True)
    brela_number_nonce = models.BinaryField(max_length=12, null=True, blank=True)
    tin_hash = models.CharField(max_length=64, blank=True, default="", db_index=True)
    tin_ciphertext = models.BinaryField(null=True, blank=True)
    tin_nonce = models.BinaryField(max_length=12, null=True, blank=True)
    business_license_number = models.CharField(max_length=64, blank=True, default="")
    address = models.CharField(max_length=255)
    owner_principal = models.CharField(max_length=128, db_index=True)
    declared_fleet_size = models.PositiveIntegerField(default=1)
    bank_details_ciphertext = models.BinaryField(null=True, blank=True)
    bank_details_nonce = models.BinaryField(max_length=12, null=True, blank=True)
    settlement_wallet_ref = models.CharField(max_length=128)


class RegistryDocument(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application = models.ForeignKey(
        RegistryApplication, on_delete=models.CASCADE, related_name="documents"
    )
    kind = models.CharField(max_length=64, db_index=True)
    version = models.PositiveIntegerField(default=1)
    current = models.BooleanField(default=True, db_index=True)
    original_name = models.CharField(max_length=255)
    content_type = models.CharField(max_length=128)
    size_bytes = models.PositiveBigIntegerField()
    sha256 = models.CharField(max_length=64, db_index=True)
    encrypted_payload = models.BinaryField()
    encryption_nonce = models.BinaryField(max_length=12)
    encryption_key_version = models.CharField(max_length=32)
    document_number_ciphertext = models.BinaryField(null=True, blank=True)
    document_number_nonce = models.BinaryField(max_length=12, null=True, blank=True)
    document_number_hash = models.CharField(max_length=64, blank=True, default="", db_index=True)
    document_number_masked = models.CharField(max_length=32, blank=True, default="")
    issue_date = models.DateField(null=True, blank=True)
    expiry_date = models.DateField(null=True, blank=True, db_index=True)
    status = models.CharField(
        max_length=16, choices=DocumentStatus.choices, default=DocumentStatus.PENDING, db_index=True
    )
    reviewer = models.CharField(max_length=128, blank=True, default="")
    reviewed_at = models.DateTimeField(null=True, blank=True)
    rejection_reason = models.CharField(max_length=500, blank=True, default="")
    uploaded_by = models.CharField(max_length=128)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [
            models.Index(fields=["application", "status"]),
            models.Index(fields=["expiry_date", "status"]),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=["application", "kind"],
                condition=Q(current=True),
                name="registry_one_current_document_kind",
            )
        ]


class CompliancePolicy(models.Model):
    code = models.SlugField(max_length=64, unique=True)
    application_type = models.CharField(max_length=32, choices=ApplicationType.choices)
    required_document_kinds = models.JSONField(default=list)
    expiry_required_kinds = models.JSONField(default=list)
    reminder_days = models.JSONField(default=list)
    suspend_on_expiry = models.BooleanField(default=True)
    police_clearance_required = models.BooleanField(default=False)
    medical_certificate_required = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    version = models.PositiveIntegerField(default=1)
    effective_from = models.DateTimeField(default=timezone.now)


class WorkflowTransition(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application = models.ForeignKey(
        RegistryApplication, on_delete=models.CASCADE, related_name="transitions"
    )
    from_status = models.CharField(max_length=24)
    to_status = models.CharField(max_length=24)
    from_stage = models.CharField(max_length=32)
    to_stage = models.CharField(max_length=32)
    actor = models.CharField(max_length=128, db_index=True)
    reason = models.CharField(max_length=500, blank=True, default="")
    comments = models.TextField(blank=True, default="")
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    device_id = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def save(self, *args, **kwargs):
        if not self._state.adding:
            raise ValueError("WorkflowTransition is append-only")
        return super().save(*args, **kwargs)


class ComplianceFinding(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application = models.ForeignKey(
        RegistryApplication, on_delete=models.CASCADE, related_name="compliance_findings"
    )
    code = models.CharField(max_length=64, db_index=True)
    severity = models.CharField(max_length=16)
    status = models.CharField(max_length=16, default="open", db_index=True)
    details = models.JSONField(default=dict)
    detected_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    resolved_by = models.CharField(max_length=128, blank=True, default="")

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["application", "code"],
                condition=Q(status="open"),
                name="registry_unique_open_finding",
            )
        ]


class BlacklistEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    identifier_type = models.CharField(max_length=32)
    identifier_hash = models.CharField(max_length=64, db_index=True)
    reason = models.CharField(max_length=500)
    active = models.BooleanField(default=True, db_index=True)
    created_by = models.CharField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["identifier_type", "identifier_hash"],
                condition=Q(active=True),
                name="registry_unique_active_blacklist",
            )
        ]


class RegistryNotification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient_principal = models.CharField(max_length=128, db_index=True)
    event_type = models.CharField(max_length=64)
    application = models.ForeignKey(
        RegistryApplication, null=True, blank=True, on_delete=models.CASCADE
    )
    payload = models.JSONField(default=dict)
    status = models.CharField(max_length=16, default="pending", db_index=True)
    deduplication_key = models.CharField(max_length=128, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    published_at = models.DateTimeField(null=True, blank=True)


class ExternalVerificationRequest(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application = models.ForeignKey(
        RegistryApplication, on_delete=models.CASCADE, related_name="external_checks"
    )
    provider = models.CharField(max_length=32)
    check_type = models.CharField(max_length=64)
    request_reference = models.CharField(max_length=128, unique=True)
    status = models.CharField(max_length=16, default="pending", db_index=True)
    request_payload = models.JSONField(default=dict)
    response_payload = models.JSONField(default=dict)
    requested_by = models.CharField(max_length=128)
    requested_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)
