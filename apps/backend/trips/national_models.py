"""National mobility domain models (Phase 3).

Uses string ForeignKeys to avoid circular imports with core trip models.
Money settlement remains Taifa Payments; eligibility remains Mobility Registry.
"""
from __future__ import annotations

import uuid

from django.db import models

from payments.models import CURRENCY_CHOICES


class IntercityCorridor(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=255)
    origin_region = models.CharField(max_length=128, db_index=True)
    origin_district = models.CharField(max_length=128, blank=True, default="")
    destination_region = models.CharField(max_length=128, db_index=True)
    destination_district = models.CharField(max_length=128, blank=True, default="")
    origin_station = models.ForeignKey(
        "trips.Station",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="intercity_origins",
    )
    destination_station = models.ForeignKey(
        "trips.Station",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="intercity_destinations",
    )
    distance_km = models.PositiveIntegerField(default=0)
    typical_duration_minutes = models.PositiveIntegerField(default=0)
    vehicle_modes = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=True, db_index=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class IntercityDeparture(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    corridor = models.ForeignKey(
        IntercityCorridor, on_delete=models.CASCADE, related_name="departures"
    )
    vehicle_mode = models.CharField(max_length=24)
    operator_principal = models.CharField(max_length=128, db_index=True)
    fleet = models.ForeignKey(
        "trips.Fleet", null=True, blank=True, on_delete=models.SET_NULL, related_name="intercity_departures"
    )
    departs_at = models.DateTimeField(db_index=True)
    arrives_at = models.DateTimeField()
    seats_total = models.PositiveIntegerField(default=1)
    seats_available = models.PositiveIntegerField(default=1)
    fare_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    transfer_station = models.ForeignKey(
        "trips.Station",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="intercity_transfers",
    )
    status = models.CharField(max_length=16, default="scheduled", db_index=True)
    trip = models.ForeignKey(
        "trips.Trip", null=True, blank=True, on_delete=models.SET_NULL, related_name="intercity_departures"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["corridor", "departs_at", "status"])]


class IntercityBooking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    departure = models.ForeignKey(
        IntercityDeparture, on_delete=models.PROTECT, related_name="bookings"
    )
    owner = models.CharField(max_length=128, db_index=True)
    seats = models.PositiveIntegerField(default=1)
    fare_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    status = models.CharField(max_length=16, default="reserved", db_index=True)
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    ticket_code = models.CharField(max_length=64, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)


class PublicTransitRoute(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=255)
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, blank=True, default="")
    operator_principal = models.CharField(max_length=128, db_index=True)
    vehicle_mode = models.CharField(max_length=24, default="bus")
    stops = models.JSONField(default=list)  # [{code,name,lat,lng,sequence}]
    metadata = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)


class PublicTransitTimetable(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    route = models.ForeignKey(
        PublicTransitRoute, on_delete=models.CASCADE, related_name="timetables"
    )
    weekday = models.PositiveSmallIntegerField()  # 0-6
    departure_time = models.TimeField()
    seats = models.PositiveIntegerField(default=40)
    fare_minor = models.PositiveBigIntegerField(default=0)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    active = models.BooleanField(default=True)

    class Meta:
        indexes = [models.Index(fields=["route", "weekday", "departure_time"])]


class TransportTicket(models.Model):
    """Digital ticket / pass media — payment captured via Taifa Payments ref only."""

    class TicketType(models.TextChoices):
        SINGLE = "single"
        QR = "qr"
        NFC = "nfc"
        WALLET = "wallet"
        CORPORATE_PASS = "corporate_pass"
        MONTHLY_PASS = "monthly_pass"
        STUDENT_PASS = "student_pass"
        GOVERNMENT_CARD = "government_card"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    ticket_type = models.CharField(max_length=24, choices=TicketType.choices)
    media_code = models.CharField(max_length=128, unique=True)
    route = models.ForeignKey(
        PublicTransitRoute, null=True, blank=True, on_delete=models.SET_NULL, related_name="tickets"
    )
    intercity_booking = models.ForeignKey(
        IntercityBooking, null=True, blank=True, on_delete=models.SET_NULL, related_name="tickets"
    )
    trip = models.ForeignKey(
        "trips.Trip", null=True, blank=True, on_delete=models.SET_NULL, related_name="tickets"
    )
    fare_minor = models.PositiveBigIntegerField(default=0)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    valid_from = models.DateTimeField()
    valid_to = models.DateTimeField()
    status = models.CharField(max_length=16, default="active", db_index=True)
    origin_stop = models.CharField(max_length=64, blank=True, default="")
    destination_stop = models.CharField(max_length=64, blank=True, default="")
    token_hash = models.CharField(max_length=128, blank=True, default="", db_index=True)
    signature = models.CharField(max_length=128, blank=True, default="")
    media_payload = models.JSONField(default=dict, blank=True)
    validation_count = models.PositiveSmallIntegerField(default=0)
    max_validations = models.PositiveSmallIntegerField(default=1)
    product_code = models.CharField(max_length=64, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class TransitStationProfile(models.Model):
    """Rich BRT / transit stop profile for passenger information."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    stop_code = models.CharField(max_length=64, unique=True, db_index=True)
    name = models.CharField(max_length=255)
    region = models.CharField(max_length=128, db_index=True)
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    image_url = models.URLField(max_length=500, blank=True, default="")
    facilities = models.JSONField(default=list, blank=True)
    accessibility = models.JSONField(default=dict, blank=True)
    platform = models.CharField(max_length=64, blank=True, default="")
    exit_map = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["stop_code"]


class TransitAlert(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    region = models.CharField(max_length=128, db_index=True)
    route = models.ForeignKey(
        PublicTransitRoute,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="alerts",
    )
    severity = models.CharField(max_length=16, default="info")
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True, default="")
    active = models.BooleanField(default=True, db_index=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class TransitTicketProduct(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    ticket_type = models.CharField(max_length=24, default="single")
    fare_minor = models.PositiveBigIntegerField(default=0)
    currency = models.CharField(max_length=8, choices=CURRENCY_CHOICES, default="TZS")
    validity_hours = models.PositiveIntegerField(default=2)
    max_validations = models.PositiveSmallIntegerField(default=1)
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["code"]


class TransitAuditEvent(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    action = models.CharField(max_length=64, db_index=True)
    actor = models.CharField(max_length=128)
    ticket = models.ForeignKey(
        TransportTicket,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="audit_events",
    )
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class TransitScheduledRun(models.Model):
    """Fixed-route BRT shift assigned to a driver (Phase 2)."""

    class Status(models.TextChoices):
        SCHEDULED = "scheduled"
        BOARDING = "boarding"
        DEPARTED = "departed"
        COMPLETED = "completed"
        CANCELLED = "cancelled"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    route = models.ForeignKey(
        PublicTransitRoute, on_delete=models.CASCADE, related_name="scheduled_runs"
    )
    driver_owner = models.CharField(max_length=128, db_index=True)
    vehicle_label = models.CharField(max_length=64, blank=True, default="")
    scheduled_at = models.DateTimeField(db_index=True)
    origin_stop = models.CharField(max_length=64, blank=True, default="")
    destination_stop = models.CharField(max_length=64, blank=True, default="")
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.SCHEDULED, db_index=True
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["scheduled_at"]
        indexes = [models.Index(fields=["driver_owner", "scheduled_at", "status"])]


class TransitAvlVehicle(models.Model):
    """Latest known GPS fix for a fixed-route transit vehicle (Phase 3 AVL)."""

    class Status(models.TextChoices):
        IN_SERVICE = "in_service"
        AT_STATION = "at_station"
        OFFLINE = "offline"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    vehicle_label = models.CharField(max_length=64, unique=True, db_index=True)
    route = models.ForeignKey(
        PublicTransitRoute, on_delete=models.CASCADE, related_name="avl_vehicles"
    )
    scheduled_run = models.ForeignKey(
        TransitScheduledRun,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="avl_snapshots",
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6)
    longitude = models.DecimalField(max_digits=9, decimal_places=6)
    heading = models.SmallIntegerField(default=0)
    speed_kmh = models.PositiveSmallIntegerField(default=0)
    progress_e4 = models.PositiveIntegerField(default=0)  # 0..10000 corridor progress
    next_stop_code = models.CharField(max_length=64, blank=True, default="")
    eta_next_stop_seconds = models.PositiveIntegerField(default=0)
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.IN_SERVICE, db_index=True
    )
    active = models.BooleanField(default=True, db_index=True)
    recorded_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["vehicle_label"]
        indexes = [models.Index(fields=["route", "active", "status"])]


class TransitPassengerProfile(models.Model):
    """BRT passenger preferences and accessibility (Phase 4)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, unique=True, db_index=True)
    home_stop = models.CharField(max_length=64, blank=True, default="")
    work_stop = models.CharField(max_length=64, blank=True, default="")
    preferred_language = models.CharField(max_length=8, default="sw")
    accessibility = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class TransitFavorite(models.Model):
    class SubjectType(models.TextChoices):
        STATION = "station"
        ROUTE = "route"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    subject_type = models.CharField(max_length=16, choices=SubjectType.choices)
    subject_code = models.CharField(max_length=64, db_index=True)
    label = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["owner", "subject_type", "subject_code"],
                name="trips_unique_transit_favorite",
            )
        ]


class TransitNotification(models.Model):
    """Transit event outbox for push/in-app delivery (Phase 4)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    event_type = models.CharField(max_length=64, db_index=True)
    title = models.CharField(max_length=255)
    body = models.TextField(blank=True, default="")
    payload = models.JSONField(default=dict, blank=True)
    read = models.BooleanField(default=False, db_index=True)
    deduplication_key = models.CharField(max_length=160, unique=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)


class TransitFeedback(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    route = models.ForeignKey(
        PublicTransitRoute, null=True, blank=True, on_delete=models.SET_NULL, related_name="feedback"
    )
    ticket = models.ForeignKey(
        TransportTicket, null=True, blank=True, on_delete=models.SET_NULL, related_name="feedback"
    )
    rating = models.PositiveSmallIntegerField()
    comment = models.TextField(blank=True, default="")
    tags = models.JSONField(default=list, blank=True)
    sentiment = models.CharField(max_length=16, default="neutral")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class TransitDailyMetric(models.Model):
    """BRT corridor daily rollup for ops dashboards (Phase 5)."""

    date = models.DateField(db_index=True)
    region = models.CharField(max_length=128, db_index=True)
    route_code = models.CharField(max_length=64, blank=True, default="")
    product_code = models.CharField(max_length=64, blank=True, default="")
    tickets_issued = models.PositiveIntegerField(default=0)
    tickets_validated = models.PositiveIntegerField(default=0)
    nfc_validations = models.PositiveIntegerField(default=0)
    qr_validations = models.PositiveIntegerField(default=0)
    fare_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["date", "region", "route_code", "product_code"],
                name="trips_unique_transit_daily_metric",
            )
        ]


class TransitFamilyMember(models.Model):
    """Guardian-linked dependent for family BRT ticketing (Phase 7)."""

    class Relationship(models.TextChoices):
        CHILD = "child"
        SPOUSE = "spouse"
        PARENT = "parent"
        OTHER = "other"

    class Status(models.TextChoices):
        ACTIVE = "active"
        REMOVED = "removed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    guardian_owner = models.CharField(max_length=128, db_index=True)
    member_owner = models.CharField(max_length=128, db_index=True)
    display_name = models.CharField(max_length=128)
    relationship = models.CharField(
        max_length=16, choices=Relationship.choices, default=Relationship.CHILD
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.ACTIVE, db_index=True
    )
    can_purchase = models.BooleanField(default=True)
    monthly_limit_minor = models.PositiveBigIntegerField(default=0)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["guardian_owner", "member_owner"],
                name="trips_unique_transit_family_member",
            )
        ]
        ordering = ["display_name"]


class TransitLostFoundItem(models.Model):
    """Lost & found reports at BRT stations (Phase 8)."""

    class Kind(models.TextChoices):
        LOST = "lost"
        FOUND = "found"

    class Category(models.TextChoices):
        PHONE = "phone"
        WALLET = "wallet"
        BAG = "bag"
        ID_CARD = "id_card"
        CLOTHING = "clothing"
        KEYS = "keys"
        OTHER = "other"

    class Status(models.TextChoices):
        OPEN = "open"
        CLAIMED = "claimed"
        MATCHED = "matched"
        CLOSED = "closed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    reporter_owner = models.CharField(max_length=128, db_index=True)
    kind = models.CharField(max_length=8, choices=Kind.choices, db_index=True)
    category = models.CharField(
        max_length=16, choices=Category.choices, default=Category.OTHER, db_index=True
    )
    title = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    stop_code = models.CharField(max_length=64, blank=True, default="", db_index=True)
    route = models.ForeignKey(
        PublicTransitRoute,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="lost_found_items",
    )
    status = models.CharField(
        max_length=16, choices=Status.choices, default=Status.OPEN, db_index=True
    )
    contact_hint = models.CharField(max_length=128, blank=True, default="")
    claimant_owner = models.CharField(max_length=128, blank=True, default="", db_index=True)
    claim_message = models.TextField(blank=True, default="")
    claimed_at = models.DateTimeField(null=True, blank=True)
    resolved_at = models.DateTimeField(null=True, blank=True)
    photo_url = models.URLField(max_length=500, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True, db_index=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class EnterpriseOrganization(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    legal_name = models.CharField(max_length=255)
    organization_type = models.CharField(
        max_length=32,
        default="corporate",
    )  # corporate|ngo|hospital|university|factory|mining|construction|government
    billing_account = models.CharField(max_length=128, db_index=True)
    region = models.CharField(max_length=128, blank=True, default="")
    fleet = models.ForeignKey(
        "trips.Fleet", null=True, blank=True, on_delete=models.SET_NULL, related_name="enterprises"
    )
    active = models.BooleanField(default=True)
    policy = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class EnterpriseEmployee(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    organization = models.ForeignKey(
        EnterpriseOrganization, on_delete=models.CASCADE, related_name="employees"
    )
    principal = models.CharField(max_length=128, db_index=True)
    department = models.CharField(max_length=128, blank=True, default="")
    employee_code = models.CharField(max_length=64, blank=True, default="")
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["organization", "principal"],
                name="trips_unique_enterprise_employee",
            )
        ]


class EmergencyDispatchRequest(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    requester_principal = models.CharField(max_length=128, db_index=True)
    kind = models.CharField(max_length=32)  # ambulance|medical|disaster|escort
    severity = models.CharField(max_length=16, default="critical")
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, blank=True, default="")
    pickup_name = models.CharField(max_length=255)
    pickup_lat = models.DecimalField(max_digits=9, decimal_places=6)
    pickup_lng = models.DecimalField(max_digits=9, decimal_places=6)
    dropoff_name = models.CharField(max_length=255, blank=True, default="")
    dropoff_lat = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    dropoff_lng = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    status = models.CharField(max_length=16, default="requested", db_index=True)
    trip = models.ForeignKey(
        "trips.Trip", null=True, blank=True, on_delete=models.SET_NULL, related_name="emergency_requests"
    )
    incident = models.ForeignKey(
        "trips.SafetyIncident",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="emergency_dispatches",
    )
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)


class LogisticsShipment(models.Model):
    """National logistics layer atop trip Delivery proof flow."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    category = models.CharField(max_length=32)  # courier|cargo|medical|agriculture|warehouse|last_mile
    origin_name = models.CharField(max_length=255)
    origin_lat = models.DecimalField(max_digits=9, decimal_places=6)
    origin_lng = models.DecimalField(max_digits=9, decimal_places=6)
    destination_name = models.CharField(max_length=255)
    destination_lat = models.DecimalField(max_digits=9, decimal_places=6)
    destination_lng = models.DecimalField(max_digits=9, decimal_places=6)
    region = models.CharField(max_length=128, blank=True, default="")
    vehicle_mode = models.CharField(max_length=24, default="truck")
    weight_kg_e2 = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=16, default="created", db_index=True)
    trip = models.ForeignKey(
        "trips.Trip", null=True, blank=True, on_delete=models.SET_NULL, related_name="logistics_shipments"
    )
    delivery = models.ForeignKey(
        "trips.Delivery", null=True, blank=True, on_delete=models.SET_NULL, related_name="shipments"
    )
    warehouse_code = models.CharField(max_length=64, blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)


class PartnerApiCredential(models.Model):
    """Open platform partner credentials (scoped RBAC via enterprise roles still applies)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    partner_code = models.SlugField(max_length=64, unique=True)
    legal_name = models.CharField(max_length=255)
    owner_principal = models.CharField(max_length=128, db_index=True)
    api_key_prefix = models.CharField(max_length=16)
    api_key_hash = models.CharField(max_length=128, unique=True)
    scopes = models.JSONField(default=list)  # e.g. mobility.read, mobility.trips.write
    active = models.BooleanField(default=True)
    rate_limit_per_minute = models.PositiveIntegerField(default=120)
    created_at = models.DateTimeField(auto_now_add=True)


class NationalDailyMetric(models.Model):
    date = models.DateField(db_index=True)
    region = models.CharField(max_length=128, db_index=True)
    district = models.CharField(max_length=128, blank=True, default="")
    vehicle_mode = models.CharField(max_length=24, blank=True, default="")
    trip_kind = models.CharField(max_length=16, blank=True, default="")
    requested = models.PositiveBigIntegerField(default=0)
    completed = models.PositiveBigIntegerField(default=0)
    cancelled = models.PositiveBigIntegerField(default=0)
    fare_minor = models.BigIntegerField(default=0)
    sos_count = models.PositiveIntegerField(default=0)
    average_eta_seconds = models.PositiveIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["date", "region", "district", "vehicle_mode", "trip_kind"],
                name="trips_unique_national_daily_metric",
            )
        ]
