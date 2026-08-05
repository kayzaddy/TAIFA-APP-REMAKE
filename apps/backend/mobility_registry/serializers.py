from datetime import date

from rest_framework import serializers

from trips.models import FleetType, TransportMode

from .models import (
    ApplicationType,
    BlacklistEntry,
    DocumentStatus,
    RegistryApplication,
    RegistryDocument,
    WorkflowTransition,
)


class ApplicationSerializer(serializers.ModelSerializer):
    document_counts = serializers.SerializerMethodField()
    profile = serializers.SerializerMethodField()

    class Meta:
        model = RegistryApplication
        fields = [
            "id", "application_number", "application_type", "applicant_principal",
            "status", "stage", "region", "district", "assigned_reviewer",
            "rejection_reason", "approval_reference", "operational_object_id",
            "version", "submitted_at", "approved_at", "rejected_at",
            "suspended_at", "created_at", "updated_at", "document_counts", "profile",
        ]
        read_only_fields = fields

    def get_document_counts(self, obj) -> dict:
        current = obj.documents.filter(current=True)
        return {
            "total": current.count(),
            "verified": current.filter(status=DocumentStatus.VERIFIED).count(),
            "rejected": current.filter(status=DocumentStatus.REJECTED).count(),
        }

    def get_profile(self, obj) -> dict:
        if obj.application_type == ApplicationType.DRIVER and hasattr(obj, "driver"):
            return {
                "full_name": obj.driver.full_name,
                "national_id_masked": obj.driver.national_id_masked,
                "phone_masked": obj.driver.phone_masked,
                "preferred_language": obj.driver.preferred_language,
            }
        if obj.application_type == ApplicationType.VEHICLE and hasattr(obj, "vehicle"):
            return {
                "registration_number": obj.vehicle.registration_number,
                "mode": obj.vehicle.mode,
                "make": obj.vehicle.make,
                "model": obj.vehicle.model,
                "year": obj.vehicle.year,
            }
        if obj.application_type == ApplicationType.STATION and hasattr(obj, "station"):
            return {
                "name": obj.station.name,
                "code": obj.station.code,
                "phone_masked": obj.station.phone_masked,
                "capacity": obj.station.capacity,
            }
        if hasattr(obj, "fleet"):
            return {
                "business_name": obj.fleet.business_name,
                "fleet_type": obj.fleet.fleet_type,
                "declared_fleet_size": obj.fleet.declared_fleet_size,
            }
        return {}


class DriverRegistrationSerializer(serializers.Serializer):
    client_reference = serializers.CharField(max_length=64)
    full_name = serializers.CharField(max_length=255)
    national_id_number = serializers.CharField(max_length=64, write_only=True)
    passport_number = serializers.CharField(
        max_length=64, required=False, allow_blank=True, write_only=True
    )
    phone_number = serializers.CharField(max_length=32, write_only=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    gender = serializers.CharField(max_length=24)
    date_of_birth = serializers.DateField()
    nationality = serializers.CharField(max_length=64, default="Tanzanian")
    region = serializers.CharField(max_length=128)
    district = serializers.CharField(max_length=128)
    ward = serializers.CharField(max_length=128, required=False, allow_blank=True)
    street = serializers.CharField(max_length=255, required=False, allow_blank=True)
    postal_address = serializers.CharField(max_length=255, required=False, allow_blank=True)
    emergency_contact_name = serializers.CharField(max_length=128)
    emergency_contact_phone = serializers.CharField(max_length=32, write_only=True)
    preferred_station = serializers.UUIDField(required=False, allow_null=True)
    preferred_language = serializers.ChoiceField(choices=["sw", "en"], default="sw")
    bank_account = serializers.CharField(
        max_length=128, required=False, allow_blank=True, write_only=True
    )
    wallet_account_ref = serializers.CharField(max_length=128, required=False)

    def validate_date_of_birth(self, value):
        today = date.today()
        age = today.year - value.year - ((today.month, today.day) < (value.month, value.day))
        if age < 18 or age > 100:
            raise serializers.ValidationError("driver must be between 18 and 100 years old")
        return value


class VehicleRegistrationSerializer(serializers.Serializer):
    client_reference = serializers.CharField(max_length=64)
    mode = serializers.ChoiceField(choices=TransportMode.choices)
    registration_number = serializers.CharField(max_length=32)
    chassis_number = serializers.CharField(max_length=128, write_only=True)
    engine_number = serializers.CharField(max_length=128, write_only=True)
    make = serializers.CharField(max_length=64)
    model = serializers.CharField(max_length=64)
    year = serializers.IntegerField(min_value=1950, max_value=date.today().year + 1)
    fuel_type = serializers.ChoiceField(
        choices=["petrol", "diesel", "electric", "hybrid", "cng", "other"]
    )
    color = serializers.CharField(max_length=32)
    capacity = serializers.IntegerField(min_value=1, max_value=120)
    owner_principal = serializers.CharField(max_length=128, required=False)
    assigned_driver_application = serializers.UUIDField(required=False, allow_null=True)
    region = serializers.CharField(max_length=128)
    district = serializers.CharField(max_length=128)


class StationRegistrationSerializer(serializers.Serializer):
    client_reference = serializers.CharField(max_length=64)
    name = serializers.CharField(max_length=255)
    code = serializers.SlugField(max_length=64)
    latitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    longitude = serializers.DecimalField(max_digits=9, decimal_places=6)
    region = serializers.CharField(max_length=128)
    district = serializers.CharField(max_length=128)
    ward = serializers.CharField(max_length=128)
    street = serializers.CharField(max_length=255)
    manager_principal = serializers.CharField(max_length=128, required=False)
    phone_number = serializers.CharField(max_length=32, write_only=True)
    email = serializers.EmailField(required=False, allow_blank=True)
    operating_hours = serializers.JSONField()
    capacity = serializers.IntegerField(min_value=1, max_value=10000)
    description = serializers.CharField(required=False, allow_blank=True)


class FleetRegistrationSerializer(serializers.Serializer):
    client_reference = serializers.CharField(max_length=64)
    fleet_type = serializers.ChoiceField(
        choices=[value for value, _ in FleetType.choices]
    )
    business_name = serializers.CharField(max_length=255)
    brela_number = serializers.CharField(
        max_length=64, required=False, allow_blank=True, write_only=True
    )
    tin = serializers.CharField(
        max_length=64, required=False, allow_blank=True, write_only=True
    )
    business_license_number = serializers.CharField(
        max_length=64, required=False, allow_blank=True
    )
    address = serializers.CharField(max_length=255)
    owner_principal = serializers.CharField(max_length=128, required=False)
    declared_fleet_size = serializers.IntegerField(min_value=1, max_value=1_000_000)
    bank_details = serializers.CharField(
        max_length=500, required=False, allow_blank=True, write_only=True
    )
    settlement_wallet_ref = serializers.CharField(max_length=128, required=False)
    region = serializers.CharField(max_length=128)
    district = serializers.CharField(max_length=128)
    application_type = serializers.ChoiceField(
        choices=[ApplicationType.FLEET, ApplicationType.TRANSPORT_COMPANY],
        default=ApplicationType.FLEET,
    )


class DocumentUploadSerializer(serializers.Serializer):
    kind = serializers.CharField(max_length=64)
    document = serializers.FileField()
    document_number = serializers.CharField(
        max_length=128, required=False, allow_blank=True, write_only=True
    )
    issue_date = serializers.DateField(required=False, allow_null=True)
    expiry_date = serializers.DateField(required=False, allow_null=True)

    def validate(self, attrs):
        issue = attrs.get("issue_date")
        expiry = attrs.get("expiry_date")
        if issue and expiry and expiry <= issue:
            raise serializers.ValidationError("expiry_date must be after issue_date")
        return attrs


class DocumentSerializer(serializers.ModelSerializer):
    class Meta:
        model = RegistryDocument
        fields = [
            "id", "application", "kind", "version", "current", "original_name",
            "content_type", "size_bytes", "sha256", "document_number_masked",
            "issue_date", "expiry_date", "status", "reviewer", "reviewed_at",
            "rejection_reason", "uploaded_by", "uploaded_at",
        ]
        read_only_fields = fields


class DocumentDecisionSerializer(serializers.Serializer):
    decision = serializers.ChoiceField(
        choices=[DocumentStatus.VERIFIED, DocumentStatus.REJECTED]
    )
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)


class WorkflowActionSerializer(serializers.Serializer):
    reason = serializers.CharField(max_length=500, required=False, allow_blank=True)
    comments = serializers.CharField(required=False, allow_blank=True)


class ExternalVerificationSerializer(serializers.Serializer):
    provider = serializers.ChoiceField(
        choices=[
            "nida", "brela", "tra", "police", "insurance",
            "inspection", "local_government",
        ]
    )
    check_type = serializers.CharField(max_length=64)
    attributes = serializers.JSONField(default=dict)


class BlacklistCreateSerializer(serializers.Serializer):
    identifier_type = serializers.ChoiceField(
        choices=["national_id", "registration_number", "chassis_number", "engine_number"]
    )
    identifier = serializers.CharField(max_length=128, write_only=True)
    reason = serializers.CharField(max_length=500)


class BlacklistSerializer(serializers.ModelSerializer):
    class Meta:
        model = BlacklistEntry
        fields = [
            "id", "identifier_type", "reason", "active",
            "created_by", "created_at", "expires_at",
        ]
        read_only_fields = fields


class WorkflowTransitionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WorkflowTransition
        fields = "__all__"


class VerificationQueueSerializer(serializers.Serializer):
    new_applications = serializers.IntegerField()
    pending_verification = serializers.IntegerField()
    rejected_applications = serializers.IntegerField()
    expired_documents = serializers.IntegerField()
    suspended_drivers = serializers.IntegerField()
    suspended_vehicles = serializers.IntegerField()
    pending_stations = serializers.IntegerField()
    pending_fleets = serializers.IntegerField()


class ComplianceDashboardSerializer(serializers.Serializer):
    open_findings = serializers.DictField(child=serializers.IntegerField())
    documents_expiring = serializers.DictField(child=serializers.IntegerField())
    expired_documents = serializers.IntegerField()
    suspended_applications = serializers.IntegerField()
    blocked_applications = serializers.IntegerField()
    notification_backlog = serializers.IntegerField()


class RegistrySearchResultSerializer(serializers.Serializer):
    application = ApplicationSerializer()
    display_name = serializers.CharField()
    phone_masked = serializers.CharField(required=False)
    registration_number = serializers.CharField(required=False)
