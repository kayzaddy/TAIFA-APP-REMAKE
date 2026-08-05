from rest_framework import serializers

from .models import (
    DispatchOffer,
    Delivery,
    DispatchStrategy,
    Driver,
    DriverLocation,
    Fleet,
    MobilityNotification,
    PricingRule,
    Rating,
    SafetyIncident,
    SavedLocation,
    Station,
    StationQueueEntry,
    TransportMode,
    Trip,
    TripKind,
    Vehicle,
    VehicleOperationalLog,
    VerificationStatus,
)


class TripSerializer(serializers.ModelSerializer):
    station_id = serializers.UUIDField(read_only=True)
    driver_id = serializers.UUIDField(read_only=True)
    vehicle_id = serializers.UUIDField(read_only=True)

    class Meta:
        model = Trip
        fields = [
            "id",
            "owner",
            "status",
            "lifecycle_version",
            "kind",
            "dispatch_strategy",
            "pickup_name",
            "pickup_lat",
            "pickup_lng",
            "dropoff_name",
            "dropoff_lat",
            "dropoff_lng",
            "product_id",
            "product_name",
            "vehicle_mode",
            "fare_minor",
            "currency",
            "fare_breakdown",
            "pricing_rule_version",
            "driver_name",
            "vehicle_label",
            "driver_id",
            "vehicle_id",
            "station_id",
            "payment_ref",
            "payment_transaction_id",
            "payment_method",
            "distance_meters",
            "duration_seconds",
            "scheduled_at",
            "assigned_at",
            "arrived_at",
            "started_at",
            "completed_at",
            "cancelled_at",
            "cancellation_reason",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class TripCreateSerializer(serializers.Serializer):
    pickup_name = serializers.CharField()
    pickup_lat = serializers.FloatField()
    pickup_lng = serializers.FloatField()
    dropoff_name = serializers.CharField()
    dropoff_lat = serializers.FloatField()
    dropoff_lng = serializers.FloatField()
    vehicle_mode = serializers.ChoiceField(choices=TransportMode.choices)
    kind = serializers.ChoiceField(
        choices=[TripKind.PASSENGER, TripKind.DELIVERY],
        default=TripKind.PASSENGER,
    )
    dispatch_strategy = serializers.ChoiceField(
        choices=[
            DispatchStrategy.STATION_FIRST,
            DispatchStrategy.DIRECT_NEARBY,
            DispatchStrategy.SCHEDULED,
        ],
        default=DispatchStrategy.STATION_FIRST,
    )
    region = serializers.CharField(required=False, allow_blank=True, default="")
    estimated_distance_meters = serializers.IntegerField(min_value=1, max_value=2_000_000)
    estimated_duration_seconds = serializers.IntegerField(min_value=1, max_value=604_800)
    payment_method = serializers.ChoiceField(
        choices=["wallet", "card", "mobile_money", "cash", "corporate"],
        default="wallet",
    )
    scheduled_at = serializers.DateTimeField(required=False, allow_null=True)
    corporate_account = serializers.CharField(required=False, allow_blank=True, default="")
    promo_code = serializers.CharField(required=False, allow_blank=True, default="")
    hybrid_sms_demo = serializers.BooleanField(required=False, default=False)
    passenger_msisdn = serializers.CharField(required=False, allow_blank=True, default="")

    def validate(self, attrs):
        for prefix in ("pickup", "dropoff"):
            lat = attrs[f"{prefix}_lat"]
            lng = attrs[f"{prefix}_lng"]
            if not -90 <= lat <= 90 or not -180 <= lng <= 180:
                raise serializers.ValidationError(f"{prefix} coordinates are invalid")
        if attrs["payment_method"] == "corporate" and not attrs["corporate_account"]:
            raise serializers.ValidationError("corporate_account is required for corporate billing")
        return attrs


class TripPatchSerializer(serializers.Serializer):
    status = serializers.CharField()
    metadata = serializers.DictField(required=False, default=dict)


class StationSerializer(serializers.ModelSerializer):
    current_riders = serializers.SerializerMethodField()
    current_queue = serializers.SerializerMethodField()

    class Meta:
        model = Station
        fields = [
            "id",
            "code",
            "name",
            "latitude",
            "longitude",
            "region",
            "district",
            "ward",
            "street",
            "capacity",
            "operating_hours",
            "waiting_area",
            "service_radius_meters",
            "active",
            "current_riders",
            "current_queue",
        ]

    def get_current_riders(self, obj) -> int:
        return obj.drivers.filter(status="active").count()

    def get_current_queue(self, obj) -> int:
        return obj.queue_entries.filter(active=True).count()


class StationCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Station
        fields = [
            "code",
            "name",
            "latitude",
            "longitude",
            "region",
            "district",
            "ward",
            "street",
            "capacity",
            "operating_hours",
            "manager_principal",
            "waiting_area",
            "service_radius_meters",
            "payment_merchant",
        ]

    def validate(self, attrs):
        if not -90 <= attrs["latitude"] <= 90 or not -180 <= attrs["longitude"] <= 180:
            raise serializers.ValidationError("station coordinates are invalid")
        return attrs


class FleetSerializer(serializers.ModelSerializer):
    class Meta:
        model = Fleet
        fields = "__all__"
        read_only_fields = ["id", "owner_principal", "status", "created_at"]


class DriverSerializer(serializers.ModelSerializer):
    class Meta:
        model = Driver
        fields = [
            "id",
            "owner_principal",
            "full_name",
            "phone_masked",
            "license_number",
            "license_expires_at",
            "identity_status",
            "license_status",
            "status",
            "availability",
            "station",
            "fleet",
            "rating_e2",
            "safety_score_e2",
            "acceptance_rate_e4",
            "completed_trips",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "rating_e2",
            "safety_score_e2",
            "acceptance_rate_e4",
            "completed_trips",
            "created_at",
        ]


class VehicleSerializer(serializers.ModelSerializer):
    class Meta:
        model = Vehicle
        fields = "__all__"
        read_only_fields = [
            "id",
            "owner_principal",
            "insurance_status",
            "road_license_status",
            "inspection_status",
            "status",
            "created_at",
            "updated_at",
        ]


class VehicleOperationalLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = VehicleOperationalLog
        fields = "__all__"
        read_only_fields = ["id", "driver", "created_at"]


class DriverLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DriverLocation
        fields = [
            "id",
            "driver",
            "trip",
            "latitude",
            "longitude",
            "accuracy_meters",
            "heading_degrees",
            "speed_kph_e2",
            "recorded_at",
            "received_at",
        ]
        read_only_fields = ["id", "driver", "received_at"]

    def validate(self, attrs):
        if not -90 <= attrs["latitude"] <= 90 or not -180 <= attrs["longitude"] <= 180:
            raise serializers.ValidationError("location coordinates are invalid")
        if attrs.get("heading_degrees", 0) > 359:
            raise serializers.ValidationError("heading_degrees must be 0..359")
        if attrs.get("accuracy_meters", 0) > 10_000:
            raise serializers.ValidationError("accuracy_meters is implausible")
        if attrs.get("speed_kph_e2", 0) > 30_000:
            raise serializers.ValidationError("speed exceeds supported transport range")
        return attrs


class DispatchOfferSerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source="driver.full_name", read_only=True)
    pickup_name = serializers.CharField(source="trip.pickup_name", read_only=True)
    dropoff_name = serializers.CharField(source="trip.dropoff_name", read_only=True)

    class Meta:
        model = DispatchOffer
        fields = [
            "id",
            "trip",
            "driver",
            "driver_name",
            "pickup_name",
            "dropoff_name",
            "rank",
            "score_e4",
            "distance_meters",
            "eta_seconds",
            "status",
            "expires_at",
            "created_at",
        ]
        read_only_fields = fields


class SavedLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = SavedLocation
        fields = "__all__"
        read_only_fields = ["id", "owner", "created_at"]


class RatingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Rating
        fields = ["id", "trip", "subject_type", "subject_id", "score", "comment", "created_at"]
        read_only_fields = ["id", "created_at"]


class SafetyIncidentSerializer(serializers.ModelSerializer):
    class Meta:
        model = SafetyIncident
        fields = [
            "id",
            "trip",
            "kind",
            "severity",
            "status",
            "latitude",
            "longitude",
            "details",
            "assigned_to",
            "created_at",
            "resolved_at",
        ]
        read_only_fields = ["id", "status", "assigned_to", "created_at", "resolved_at"]


class DeliverySerializer(serializers.ModelSerializer):
    class Meta:
        model = Delivery
        fields = [
            "id",
            "trip",
            "category",
            "recipient_name",
            "recipient_phone_masked",
            "package_notes",
            "proof_status",
            "proof_metadata",
            "delivered_at",
        ]
        read_only_fields = ["id", "proof_status", "proof_metadata", "delivered_at"]


class DeliveryCreateSerializer(serializers.Serializer):
    trip = serializers.PrimaryKeyRelatedField(queryset=Trip.objects.all())
    category = serializers.ChoiceField(
        choices=[
            "food",
            "medicine",
            "documents",
            "package",
            "business",
            "parcel",
            "corporate_logistics",
        ]
    )
    recipient_name = serializers.CharField(max_length=128)
    recipient_phone_masked = serializers.CharField(max_length=32)
    recipient_verification_code = serializers.CharField(
        min_length=4, max_length=12, write_only=True
    )
    package_notes = serializers.CharField(
        max_length=500, required=False, allow_blank=True, default=""
    )


class PricingRuleSerializer(serializers.ModelSerializer):
    class Meta:
        model = PricingRule
        fields = "__all__"
        read_only_fields = ["id", "created_at"]


class QueueEntrySerializer(serializers.ModelSerializer):
    driver_name = serializers.CharField(source="driver.full_name", read_only=True)

    class Meta:
        model = StationQueueEntry
        fields = ["id", "station", "driver", "driver_name", "position", "priority", "joined_at", "active"]
        read_only_fields = ["id", "position", "joined_at", "active"]


class AcceptedLocationBatchSerializer(serializers.Serializer):
    accepted = serializers.IntegerField()


class StationDashboardSerializer(serializers.Serializer):
    station = StationSerializer()
    capacity = serializers.IntegerField()
    queue_length = serializers.IntegerField()
    online_drivers = serializers.IntegerField()
    offline_drivers = serializers.IntegerField()
    drivers_on_trip = serializers.IntegerField()
    available_drivers = serializers.IntegerField()
    active_trips = serializers.IntegerField()
    completed_today = serializers.IntegerField()
    cancelled_today = serializers.IntegerField()
    average_waiting_seconds = serializers.IntegerField()
    gross_fare_today_minor = serializers.IntegerField()
    open_alerts = serializers.IntegerField()
    station_health = serializers.CharField()
    performance = serializers.DictField()


class OperationsDashboardSerializer(serializers.Serializer):
    live_trips = serializers.IntegerField()
    available_drivers = serializers.IntegerField()
    active_stations = serializers.IntegerField()
    open_sos = serializers.IntegerField()
    trips_today = serializers.IntegerField()
    completed_today = serializers.IntegerField()
    fare_today_minor = serializers.IntegerField()
    acceptance_rate_e4 = serializers.IntegerField()
    completion_rate_e4 = serializers.IntegerField()
    queue_length_total = serializers.IntegerField()
    ride_requests_today = serializers.IntegerField()
    system_health = serializers.CharField()


class QueueReorderSerializer(serializers.Serializer):
    ordered_driver_ids = serializers.ListField(
        child=serializers.UUIDField(),
        allow_empty=False,
    )


class MobilityNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = MobilityNotification
        fields = [
            "id",
            "recipient_principal",
            "event_type",
            "trip",
            "station",
            "payload",
            "status",
            "created_at",
            "published_at",
        ]
        read_only_fields = fields


class EarningsWindowSerializer(serializers.Serializer):
    gross_fare_minor = serializers.IntegerField()
    trips = serializers.IntegerField()
    currency = serializers.CharField()


class DriverEarningsSerializer(serializers.Serializer):
    daily = EarningsWindowSerializer()
    weekly = EarningsWindowSerializer()
    monthly = EarningsWindowSerializer()


class FleetDashboardSerializer(serializers.Serializer):
    fleet_id = serializers.UUIDField()
    drivers = serializers.IntegerField()
    vehicles = serializers.IntegerField()
    active_trips = serializers.IntegerField()
    completed_trips = serializers.IntegerField()
    gross_fare_minor = serializers.IntegerField()


class RegulatoryReportRequestSerializer(serializers.Serializer):
    period_start = serializers.DateField()
    period_end = serializers.DateField()
    report_type = serializers.CharField(required=False)
    authority = serializers.CharField(required=False)


class RegulatoryReportResponseSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    payload = serializers.JSONField()


class MobilityIntelligenceSerializer(serializers.Serializer):
    station_id = serializers.UUIDField(required=False)
    vehicle_id = serializers.UUIDField(required=False)
    horizon_minutes = serializers.IntegerField(required=False)
    predicted_requests = serializers.IntegerField(required=False)
    confidence_e4 = serializers.IntegerField(required=False)
    available_drivers = serializers.IntegerField(required=False)
    additional_drivers_recommended = serializers.IntegerField(required=False)
    odometer_km = serializers.IntegerField(required=False)
    remaining_km = serializers.IntegerField(required=False)
    maintenance_due = serializers.BooleanField(required=False)
    model_version = serializers.CharField()


class VerificationDecisionSerializer(serializers.Serializer):
    resource_type = serializers.ChoiceField(
        choices=[
            "driver_identity",
            "driver_license",
            "vehicle_insurance",
            "vehicle_road_license",
            "vehicle_inspection",
        ]
    )
    resource_id = serializers.UUIDField()
    status = serializers.ChoiceField(choices=VerificationStatus.choices)
    evidence_hash = serializers.CharField(max_length=64, required=False, allow_blank=True)
    reason = serializers.CharField(max_length=255, required=False, allow_blank=True)
    expires_at = serializers.DateTimeField(required=False, allow_null=True)
