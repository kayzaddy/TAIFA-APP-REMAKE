"""TAIFA Mobility domain models.

Mobility owns transport operations, never money. Financial state is represented
only by protected references to the existing Taifa Payment Platform.
"""
from __future__ import annotations

import uuid

from django.db import models
from django.db.models import Q
from django.utils import timezone

from payments.models import CURRENCY_CHOICES, Transaction


class TransportMode(models.TextChoices):
    MOTORCYCLE = "motorcycle"
    BAJAJI = "bajaji"
    TAXI = "taxi"
    PRIVATE_CAR = "private_car"
    VAN = "van"
    MINIBUS = "minibus"
    PICKUP = "pickup"
    TRUCK = "truck"
    BUS = "bus"
    DELIVERY_BIKE = "delivery_bike"
    AMBULANCE = "ambulance"
    SCHOOL_BUS = "school_bus"
    ELECTRIC_VEHICLE = "electric_vehicle"


class VerificationStatus(models.TextChoices):
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"
    EXPIRED = "expired"
    SUSPENDED = "suspended"


class FleetType(models.TextChoices):
    INDEPENDENT = "independent"
    SMALL = "small"
    CORPORATE = "corporate"
    GOVERNMENT = "government"
    BUSINESS = "business"
    RENTAL = "rental"


class Fleet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    fleet_type = models.CharField(max_length=24, choices=FleetType.choices)
    owner_principal = models.CharField(max_length=128, db_index=True)
    registration_number = models.CharField(max_length=64, blank=True, default="")
    status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.PENDING
    )
    registry_approval_id = models.UUIDField(null=True, blank=True, unique=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self) -> str:
        return self.name


class Station(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, db_index=True)
    ward = models.CharField(max_length=128, blank=True, default="")
    street = models.CharField(max_length=255, blank=True, default="")
    capacity = models.PositiveIntegerField(default=50)
    operating_hours = models.JSONField(default=dict, blank=True)
    manager_principal = models.CharField(max_length=128, db_index=True)
    waiting_area = models.CharField(max_length=255, blank=True, default="")
    service_radius_meters = models.PositiveIntegerField(default=5000)
    active = models.BooleanField(default=True, db_index=True)
    verification_status = models.CharField(
        max_length=16,
        choices=VerificationStatus.choices,
        default=VerificationStatus.PENDING,
        db_index=True,
    )
    registry_approval_id = models.UUIDField(null=True, blank=True, unique=True)
    # Merchant settlement remains owned by enterprise/payments.
    payment_merchant = models.ForeignKey(
        "enterprise.Merchant",
        null=True,
        blank=True,
        on_delete=models.PROTECT,
        related_name="mobility_stations",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["region", "district", "active"]),
            models.Index(fields=["latitude", "longitude"]),
        ]
        constraints = [
            models.CheckConstraint(
                condition=Q(latitude__gte=-90, latitude__lte=90),
                name="trips_station_valid_latitude",
            ),
            models.CheckConstraint(
                condition=Q(longitude__gte=-180, longitude__lte=180),
                name="trips_station_valid_longitude",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.code} — {self.name}"


class DriverStatus(models.TextChoices):
    PENDING = "pending"
    ACTIVE = "active"
    SUSPENDED = "suspended"
    OFFBOARDING = "offboarding"


class DriverAvailability(models.TextChoices):
    OFFLINE = "offline"
    AVAILABLE = "available"
    OFFERED = "offered"
    ON_TRIP = "on_trip"
    BREAK = "break"
    BUSY = "busy"
    EMERGENCY = "emergency"


class Driver(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner_principal = models.CharField(max_length=128, unique=True)
    full_name = models.CharField(max_length=255)
    phone_masked = models.CharField(max_length=32, blank=True, default="")
    national_id_hash = models.CharField(max_length=64, blank=True, default="")
    license_number = models.CharField(max_length=64, blank=True, default="")
    license_expires_at = models.DateField(null=True, blank=True)
    identity_status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.PENDING
    )
    license_status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.PENDING
    )
    status = models.CharField(max_length=16, choices=DriverStatus.choices, default=DriverStatus.PENDING)
    availability = models.CharField(
        max_length=16, choices=DriverAvailability.choices, default=DriverAvailability.OFFLINE
    )
    station = models.ForeignKey(
        Station, null=True, blank=True, on_delete=models.SET_NULL, related_name="drivers"
    )
    fleet = models.ForeignKey(
        Fleet, null=True, blank=True, on_delete=models.SET_NULL, related_name="drivers"
    )
    rating_e2 = models.PositiveIntegerField(default=500)
    safety_score_e2 = models.PositiveIntegerField(default=500)
    acceptance_rate_e4 = models.PositiveIntegerField(default=10000)
    completed_trips = models.PositiveBigIntegerField(default=0)
    registry_approval_id = models.UUIDField(null=True, blank=True, unique=True)
    last_identity_check_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["availability", "status"]),
            models.Index(fields=["station", "availability"]),
        ]
        constraints = [
            models.CheckConstraint(condition=Q(rating_e2__lte=500), name="trips_driver_rating_max"),
            models.CheckConstraint(
                condition=Q(safety_score_e2__lte=500),
                name="trips_driver_safety_score_max",
            ),
            models.CheckConstraint(
                condition=Q(acceptance_rate_e4__lte=10000),
                name="trips_driver_acceptance_rate_max",
            ),
        ]

    def __str__(self) -> str:
        return self.full_name


class VehicleStatus(models.TextChoices):
    DRAFT = "draft"
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"
    ACTIVE = "active"
    EXPIRED_INSURANCE = "expired_insurance"
    EXPIRED_ROAD_LICENSE = "expired_road_license"
    EXPIRED_INSPECTION = "expired_inspection"
    MAINTENANCE = "maintenance"
    SUSPENDED = "suspended"
    RETIRED = "retired"


class Vehicle(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    registration_number = models.CharField(max_length=32, unique=True)
    mode = models.CharField(max_length=24, choices=TransportMode.choices)
    make = models.CharField(max_length=64, blank=True, default="")
    model = models.CharField(max_length=64, blank=True, default="")
    color = models.CharField(max_length=32, blank=True, default="")
    capacity = models.PositiveSmallIntegerField(default=1)
    owner_principal = models.CharField(max_length=128, db_index=True)
    fleet = models.ForeignKey(
        Fleet, null=True, blank=True, on_delete=models.SET_NULL, related_name="vehicles"
    )
    assigned_driver = models.ForeignKey(
        Driver, null=True, blank=True, on_delete=models.SET_NULL, related_name="vehicles"
    )
    insurance_status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.PENDING
    )
    insurance_expires_at = models.DateField(null=True, blank=True)
    road_license_status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.PENDING
    )
    road_license_expires_at = models.DateField(null=True, blank=True)
    inspection_status = models.CharField(
        max_length=16, choices=VerificationStatus.choices, default=VerificationStatus.PENDING
    )
    inspection_expires_at = models.DateField(null=True, blank=True)
    status = models.CharField(max_length=24, choices=VehicleStatus.choices, default=VehicleStatus.PENDING)
    odometer_km = models.PositiveBigIntegerField(default=0)
    next_maintenance_at_km = models.PositiveBigIntegerField(default=0)
    registry_approval_id = models.UUIDField(null=True, blank=True, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["mode", "status"])]


class VehicleOperationalLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vehicle = models.ForeignKey(Vehicle, on_delete=models.CASCADE, related_name="operational_logs")
    driver = models.ForeignKey(
        Driver, null=True, blank=True, on_delete=models.SET_NULL, related_name="vehicle_logs"
    )
    kind = models.CharField(max_length=24)  # fuel|maintenance|inspection|incident
    odometer_km = models.PositiveBigIntegerField(default=0)
    quantity_e2 = models.PositiveBigIntegerField(default=0)
    cost_minor = models.PositiveBigIntegerField(default=0)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    notes = models.CharField(max_length=500, blank=True, default="")
    occurred_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["vehicle", "kind", "-occurred_at"])]


class DriverSchedule(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name="schedules")
    station = models.ForeignKey(
        Station, null=True, blank=True, on_delete=models.SET_NULL, related_name="driver_schedules"
    )
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()
    status = models.CharField(max_length=16, default="scheduled")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["driver", "starts_at", "ends_at"])]
        constraints = [
            models.CheckConstraint(
                condition=Q(ends_at__gt=models.F("starts_at")),
                name="trips_schedule_end_after_start",
            )
        ]


class DriverVerification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name="verifications")
    kind = models.CharField(max_length=32)
    status = models.CharField(max_length=16, choices=VerificationStatus.choices)
    document_hash = models.CharField(max_length=64, blank=True, default="")
    reviewed_by = models.CharField(max_length=128, blank=True, default="")
    reason = models.CharField(max_length=255, blank=True, default="")
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class StationQueueEntry(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    station = models.ForeignKey(Station, on_delete=models.CASCADE, related_name="queue_entries")
    driver = models.OneToOneField(Driver, on_delete=models.CASCADE, related_name="queue_entry")
    position = models.PositiveIntegerField()
    priority = models.IntegerField(default=0)
    joined_at = models.DateTimeField(auto_now_add=True)
    active = models.BooleanField(default=True, db_index=True)

    class Meta:
        ordering = ["-priority", "position", "joined_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["station", "position"],
                condition=Q(active=True),
                name="trips_unique_active_station_queue_position",
            )
        ]


class SavedLocation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    label = models.CharField(max_length=64)
    address = models.CharField(max_length=255)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    created_at = models.DateTimeField(auto_now_add=True)


class TrustedContact(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    name = models.CharField(max_length=128)
    phone_encrypted = models.TextField()
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)


class TripStatus(models.TextChoices):
    REQUESTED = "requested"
    REQUESTING = "requesting"  # legacy API compatibility
    SEARCHING = "searching"
    DRIVER_ASSIGNED = "driver_assigned"
    DRIVER_EN_ROUTE = "driver_en_route"
    ARRIVED = "arrived"
    DRIVER_ARRIVED = "driver_arrived"  # legacy
    PASSENGER_BOARDED = "passenger_boarded"
    TRIP_STARTED = "trip_started"
    IN_PROGRESS = "in_progress"  # legacy
    COMPLETED = "completed"
    PAYMENT_PENDING = "payment_pending"
    CANCELLED = "cancelled"
    PAYMENT_CONFIRMED = "payment_confirmed"
    SETTLED = "settled"


class TripKind(models.TextChoices):
    PASSENGER = "passenger"
    DELIVERY = "delivery"
    CORPORATE = "corporate"
    GOVERNMENT = "government"
    EMERGENCY = "emergency"


class DispatchStrategy(models.TextChoices):
    STATION_FIRST = "station_first"
    DIRECT_NEARBY = "direct_nearby"
    SCHEDULED = "scheduled"
    PRIORITY = "priority"
    CORPORATE = "corporate"
    EMERGENCY = "emergency"
    OVERFLOW = "overflow"
    INTERCITY = "intercity"
    PUBLIC_TRANSIT = "public_transit"


class Trip(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(max_length=32, choices=TripStatus.choices, default=TripStatus.REQUESTED)
    lifecycle_version = models.PositiveIntegerField(default=1)
    kind = models.CharField(max_length=16, choices=TripKind.choices, default=TripKind.PASSENGER)
    dispatch_strategy = models.CharField(
        max_length=24, choices=DispatchStrategy.choices, default=DispatchStrategy.STATION_FIRST
    )

    pickup_name = models.CharField(max_length=255)
    pickup_lat = models.DecimalField(max_digits=9, decimal_places=6)
    pickup_lng = models.DecimalField(max_digits=9, decimal_places=6)
    dropoff_name = models.CharField(max_length=255)
    dropoff_lat = models.DecimalField(max_digits=9, decimal_places=6)
    dropoff_lng = models.DecimalField(max_digits=9, decimal_places=6)

    product_id = models.CharField(max_length=32)
    product_name = models.CharField(max_length=64)
    vehicle_mode = models.CharField(
        max_length=24, choices=TransportMode.choices, default=TransportMode.MOTORCYCLE
    )
    fare_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    fare_breakdown = models.JSONField(default=dict, blank=True)
    pricing_rule_version = models.PositiveIntegerField(default=1)
    metadata = models.JSONField(default=dict, blank=True)

    driver_name = models.CharField(max_length=128, blank=True, default="")
    vehicle_label = models.CharField(max_length=128, blank=True, default="")
    driver = models.ForeignKey(
        Driver, null=True, blank=True, on_delete=models.PROTECT, related_name="trips"
    )
    vehicle = models.ForeignKey(
        Vehicle, null=True, blank=True, on_delete=models.PROTECT, related_name="trips"
    )
    station = models.ForeignKey(
        Station, null=True, blank=True, on_delete=models.PROTECT, related_name="trips"
    )
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    payment_transaction = models.ForeignKey(
        Transaction, null=True, blank=True, on_delete=models.PROTECT, related_name="mobility_trips"
    )
    payment_method = models.CharField(max_length=24, default="wallet")
    corporate_account = models.CharField(max_length=128, blank=True, default="")

    distance_meters = models.IntegerField(default=0)
    duration_seconds = models.IntegerField(default=0)
    scheduled_at = models.DateTimeField(null=True, blank=True, db_index=True)
    requested_at = models.DateTimeField(default=timezone.now)
    assigned_at = models.DateTimeField(null=True, blank=True)
    arrived_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancellation_reason = models.CharField(max_length=255, blank=True, default="")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["owner", "-created_at"]),
            models.Index(fields=["status", "scheduled_at"]),
            models.Index(fields=["station", "status"]),
            models.Index(fields=["driver", "status"]),
        ]
        constraints = [
            models.CheckConstraint(condition=Q(fare_minor__gte=0), name="trips_fare_non_negative"),
            models.CheckConstraint(
                condition=Q(pickup_lat__gte=-90, pickup_lat__lte=90),
                name="trips_pickup_valid_latitude",
            ),
            models.CheckConstraint(
                condition=Q(pickup_lng__gte=-180, pickup_lng__lte=180),
                name="trips_pickup_valid_longitude",
            ),
            models.CheckConstraint(
                condition=Q(dropoff_lat__gte=-90, dropoff_lat__lte=90),
                name="trips_dropoff_valid_latitude",
            ),
            models.CheckConstraint(
                condition=Q(dropoff_lng__gte=-180, dropoff_lng__lte=180),
                name="trips_dropoff_valid_longitude",
            ),
        ]

    def __str__(self) -> str:
        return f"{self.pickup_name} → {self.dropoff_name} [{self.status}]"


class TripEvent(models.Model):
    """Append-only lifecycle/audit event."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="events")
    event_type = models.CharField(max_length=64, db_index=True)
    from_status = models.CharField(max_length=32, blank=True, default="")
    to_status = models.CharField(max_length=32, blank=True, default="")
    actor = models.CharField(max_length=128)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]
        indexes = [models.Index(fields=["trip", "created_at"])]

    def save(self, *args, **kwargs):
        if not self._state.adding:
            raise ValueError("TripEvent is append-only")
        return super().save(*args, **kwargs)


class DispatchOfferStatus(models.TextChoices):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class DispatchOffer(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="offers")
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name="dispatch_offers")
    rank = models.PositiveIntegerField()
    score_e4 = models.IntegerField()
    distance_meters = models.PositiveIntegerField(default=0)
    eta_seconds = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=16, choices=DispatchOfferStatus.choices, default=DispatchOfferStatus.PENDING
    )
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    responded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["trip", "driver"], name="trips_unique_trip_driver_offer")
        ]
        indexes = [models.Index(fields=["driver", "status", "expires_at"])]


class DriverLocation(models.Model):
    id = models.BigAutoField(primary_key=True)
    driver = models.ForeignKey(Driver, on_delete=models.CASCADE, related_name="locations")
    trip = models.ForeignKey(
        Trip, null=True, blank=True, on_delete=models.CASCADE, related_name="locations"
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    accuracy_meters = models.PositiveIntegerField(default=0)
    heading_degrees = models.PositiveSmallIntegerField(default=0)
    speed_kph_e2 = models.PositiveIntegerField(default=0)
    recorded_at = models.DateTimeField(db_index=True)
    received_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-recorded_at"]
        indexes = [models.Index(fields=["driver", "-recorded_at"])]
        constraints = [
            models.CheckConstraint(
                condition=Q(latitude__gte=-90, latitude__lte=90),
                name="trips_location_valid_latitude",
            ),
            models.CheckConstraint(
                condition=Q(longitude__gte=-180, longitude__lte=180),
                name="trips_location_valid_longitude",
            ),
            models.CheckConstraint(
                condition=Q(heading_degrees__lte=359),
                name="trips_location_valid_heading",
            ),
        ]


class PricingRule(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64)
    version = models.PositiveIntegerField(default=1)
    vehicle_mode = models.CharField(max_length=24, choices=TransportMode.choices)
    region = models.CharField(max_length=128, blank=True, default="")
    trip_kind = models.CharField(max_length=16, choices=TripKind.choices, default=TripKind.PASSENGER)
    base_fare_minor = models.PositiveBigIntegerField()
    per_km_minor = models.PositiveBigIntegerField(default=0)
    per_minute_minor = models.PositiveBigIntegerField(default=0)
    waiting_per_minute_minor = models.PositiveBigIntegerField(default=0)
    station_fee_minor = models.PositiveBigIntegerField(default=0)
    night_multiplier_e4 = models.PositiveIntegerField(default=10000)
    peak_multiplier_e4 = models.PositiveIntegerField(default=10000)
    minimum_fare_minor = models.PositiveBigIntegerField(default=0)
    conditions = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True, db_index=True)
    effective_from = models.DateTimeField()
    effective_to = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["code", "version"], name="trips_unique_pricing_rule_version")
        ]
        indexes = [models.Index(fields=["vehicle_mode", "region", "active"])]


class Promotion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=32, unique=True)
    description = models.CharField(max_length=255, blank=True, default="")
    discount_bps = models.PositiveIntegerField(default=0)
    maximum_discount_minor = models.PositiveBigIntegerField(default=0)
    trip_kind = models.CharField(max_length=16, choices=TripKind.choices, blank=True, default="")
    region = models.CharField(max_length=128, blank=True, default="")
    usage_limit = models.PositiveIntegerField(default=0)
    usage_count = models.PositiveIntegerField(default=0)
    active = models.BooleanField(default=True)
    starts_at = models.DateTimeField()
    ends_at = models.DateTimeField()

    class Meta:
        constraints = [
            models.CheckConstraint(
                condition=Q(ends_at__gt=models.F("starts_at")),
                name="trips_promotion_end_after_start",
            ),
            models.CheckConstraint(
                condition=Q(discount_bps__lte=10000),
                name="trips_promotion_discount_max_100_percent",
            ),
        ]


class Rating(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(Trip, on_delete=models.CASCADE, related_name="ratings")
    rater_principal = models.CharField(max_length=128)
    subject_type = models.CharField(max_length=16)  # driver|customer
    subject_id = models.CharField(max_length=128)
    score = models.PositiveSmallIntegerField()
    comment = models.CharField(max_length=500, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["trip", "rater_principal", "subject_type"],
                name="trips_unique_rating_per_subject",
            ),
            models.CheckConstraint(condition=Q(score__gte=1, score__lte=5), name="trips_rating_1_to_5"),
        ]


class SafetyIncidentStatus(models.TextChoices):
    OPEN = "open"
    ACKNOWLEDGED = "acknowledged"
    RESPONDING = "responding"
    RESOLVED = "resolved"
    FALSE_ALARM = "false_alarm"


class SafetyIncident(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(
        Trip, null=True, blank=True, on_delete=models.PROTECT, related_name="safety_incidents"
    )
    reporter_principal = models.CharField(max_length=128, db_index=True)
    kind = models.CharField(max_length=32)  # sos|panic|crash|harassment|fraud
    severity = models.CharField(max_length=16, default="critical")
    status = models.CharField(
        max_length=16, choices=SafetyIncidentStatus.choices, default=SafetyIncidentStatus.OPEN
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    details = models.JSONField(default=dict, blank=True)
    assigned_to = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)


class MobilityNotification(models.Model):
    """Operational notifications for passengers, drivers, and station managers."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient_principal = models.CharField(max_length=128, db_index=True)
    event_type = models.CharField(max_length=64, db_index=True)
    trip = models.ForeignKey(
        Trip, null=True, blank=True, on_delete=models.CASCADE, related_name="notifications"
    )
    station = models.ForeignKey(
        Station, null=True, blank=True, on_delete=models.CASCADE, related_name="notifications"
    )
    payload = models.JSONField(default=dict, blank=True)
    status = models.CharField(max_length=16, default="pending", db_index=True)
    deduplication_key = models.CharField(max_length=160, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    published_at = models.DateTimeField(null=True, blank=True)


class Delivery(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.OneToOneField(Trip, on_delete=models.CASCADE, related_name="delivery")
    category = models.CharField(max_length=24)  # food|medicine|document|package
    recipient_name = models.CharField(max_length=128)
    recipient_phone_masked = models.CharField(max_length=32)
    verification_hash = models.CharField(max_length=128, blank=True, default="")
    package_notes = models.CharField(max_length=500, blank=True, default="")
    proof_status = models.CharField(max_length=16, default="pending")
    proof_metadata = models.JSONField(default=dict, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)


class MobilityDailyMetric(models.Model):
    date = models.DateField()
    region = models.CharField(max_length=128)
    station = models.ForeignKey(
        Station, null=True, blank=True, on_delete=models.CASCADE, related_name="daily_metrics"
    )
    requested = models.PositiveBigIntegerField(default=0)
    completed = models.PositiveBigIntegerField(default=0)
    cancelled = models.PositiveBigIntegerField(default=0)
    accepted = models.PositiveBigIntegerField(default=0)
    fare_minor = models.BigIntegerField(default=0)
    average_eta_seconds = models.PositiveIntegerField(default=0)
    average_trip_seconds = models.PositiveIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["date", "region", "station"], name="trips_unique_daily_metric")
        ]


class MobilityRegulatoryReport(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    report_type = models.CharField(max_length=64, db_index=True)
    authority = models.CharField(max_length=128)
    period_start = models.DateField()
    period_end = models.DateField()
    payload = models.JSONField(default=dict)
    created_at = models.DateTimeField(auto_now_add=True)


class MobilityFavorite(models.Model):
    """Passenger favorites for drivers and stations (identity via principal)."""

    class SubjectType(models.TextChoices):
        DRIVER = "driver"
        STATION = "station"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    subject_type = models.CharField(max_length=16, choices=SubjectType.choices)
    subject_id = models.CharField(max_length=64, db_index=True)
    label = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["owner", "subject_type", "subject_id"],
                name="trips_unique_mobility_favorite",
            )
        ]


class RecurringRidePlan(models.Model):
    """Weekly recurring passenger trip template materialized by Celery."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    label = models.CharField(max_length=128)
    pickup_name = models.CharField(max_length=255)
    pickup_lat = models.DecimalField(max_digits=9, decimal_places=6)
    pickup_lng = models.DecimalField(max_digits=9, decimal_places=6)
    dropoff_name = models.CharField(max_length=255)
    dropoff_lat = models.DecimalField(max_digits=9, decimal_places=6)
    dropoff_lng = models.DecimalField(max_digits=9, decimal_places=6)
    vehicle_mode = models.CharField(
        max_length=24, choices=TransportMode.choices, default=TransportMode.MOTORCYCLE
    )
    region = models.CharField(max_length=128, blank=True, default="")
    estimated_distance_meters = models.PositiveIntegerField(default=0)
    estimated_duration_seconds = models.PositiveIntegerField(default=0)
    payment_method = models.CharField(max_length=24, default="wallet")
    corporate_account = models.CharField(max_length=128, blank=True, default="")
    weekdays = models.JSONField(default=list)
    local_time = models.TimeField()
    active = models.BooleanField(default=True, db_index=True)
    last_materialized_on = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class MobilityZone(models.Model):
    """Operational zone within a ward/district for regional supervision."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=255)
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, db_index=True)
    ward = models.CharField(max_length=128, blank=True, default="")
    polygon = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)


class RegionalSupervisorAssignment(models.Model):
    """Maps a principal to a region/district/zone for supervisor apps."""

    class Scope(models.TextChoices):
        REGION = "region"
        DISTRICT = "district"
        ZONE = "zone"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, db_index=True)
    scope = models.CharField(max_length=16, choices=Scope.choices)
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, blank=True, default="")
    zone = models.ForeignKey(
        MobilityZone, null=True, blank=True, on_delete=models.CASCADE, related_name="supervisors"
    )
    role_title = models.CharField(max_length=64, default="regional_supervisor")
    active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["principal", "active", "region"])]


class MobilityAccountLink(models.Model):
    """Family or corporate billing/account membership for passengers."""

    class AccountType(models.TextChoices):
        FAMILY = "family"
        CORPORATE = "corporate"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    account_code = models.SlugField(max_length=64, db_index=True)
    account_type = models.CharField(max_length=16, choices=AccountType.choices)
    member_principal = models.CharField(max_length=128, db_index=True)
    role = models.CharField(max_length=32, default="member")
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["account_code", "member_principal"],
                name="trips_unique_account_member",
            )
        ]

from .national_models import *  # noqa: F401,F403 — Phase 3 national domain

