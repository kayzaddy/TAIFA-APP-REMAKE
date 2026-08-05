"""Winga Property — trusted property discovery & transaction foundation."""
from __future__ import annotations

import uuid

from django.db import models


class PropertyVerificationStatus(models.TextChoices):
    DRAFT = "draft"
    PENDING = "pending"
    VERIFIED = "verified"
    REJECTED = "rejected"
    SUSPENDED = "suspended"


class PropertyTransactionType(models.TextChoices):
    RENT = "rent"
    SALE = "sale"
    LEASE = "lease"


class PropertyOwnerRole(models.TextChoices):
    OWNER = "owner"
    LANDLORD = "landlord"
    AGENT = "agent"
    DEVELOPER = "developer"


class MediaKind(models.TextChoices):
    PHOTO = "photo"
    VIDEO = "video"


class TourRoomCode(models.TextChoices):
    LIVING = "living"
    KITCHEN = "kitchen"
    BEDROOM = "bedroom"
    BATHROOM = "bathroom"
    PARKING = "parking"
    COMPOUND = "compound"
    EXTERIOR = "exterior"
    OTHER = "other"


class MediaTourKind(models.TextChoices):
    GALLERY = "gallery"
    WALKTHROUGH = "walkthrough"
    VIDEO_TOUR = "video_tour"
    GUIDED_TOUR = "guided_tour"
    FLOOR_PLAN = "floor_plan"
    PANORAMA_360 = "panorama_360"


class PropertyCategory(models.Model):
    """Top-level property categories (residential, commercial, land, etc.)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    icon = models.CharField(max_length=64, blank=True, default="")
    sort_order = models.PositiveSmallIntegerField(default=0)
    active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order", "name"]
        verbose_name_plural = "property categories"

    def __str__(self) -> str:
        return self.name


class PropertyType(models.Model):
    """Specific property types within a category."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    category = models.ForeignKey(
        PropertyCategory, on_delete=models.CASCADE, related_name="types"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=128)
    description = models.TextField(blank=True, default="")
    active = models.BooleanField(default=True)

    class Meta:
        unique_together = [("category", "code")]
        ordering = ["category__sort_order", "name"]

    def __str__(self) -> str:
        return f"{self.category.code}:{self.name}"


class PropertyOwner(models.Model):
    """Property owner / landlord / agent account — keyed by Taifa Identity principal."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, unique=True, db_index=True)
    display_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=32, blank=True, default="")
    email = models.EmailField(blank=True, default="")
    role = models.CharField(
        max_length=16,
        choices=PropertyOwnerRole.choices,
        default=PropertyOwnerRole.OWNER,
    )
    verification_status = models.CharField(
        max_length=16,
        choices=PropertyVerificationStatus.choices,
        default=PropertyVerificationStatus.DRAFT,
    )
    kyc_ref = models.CharField(max_length=128, blank=True, default="")
    bio = models.TextField(blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return self.display_name


class PropertyListing(models.Model):
    """Core property listing — discovery, map, verification."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.ForeignKey(
        PropertyOwner, on_delete=models.CASCADE, related_name="listings"
    )
    winga_offering = models.ForeignKey(
        "winga.Offering",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="property_listings",
    )
    category = models.ForeignKey(
        PropertyCategory, on_delete=models.PROTECT, related_name="listings"
    )
    property_type = models.ForeignKey(
        PropertyType, on_delete=models.PROTECT, related_name="listings"
    )
    transaction_type = models.CharField(
        max_length=16,
        choices=PropertyTransactionType.choices,
        default=PropertyTransactionType.RENT,
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, default="")
    currency = models.CharField(max_length=8, default="TZS")
    price_minor = models.BigIntegerField(default=0)
    deposit_minor = models.BigIntegerField(default=0)
    beds = models.PositiveSmallIntegerField(default=0)
    baths = models.PositiveSmallIntegerField(default=0)
    area_sqm = models.PositiveIntegerField(default=0)
    # Location — map foundation
    address_line = models.CharField(max_length=255, blank=True, default="")
    ward = models.CharField(max_length=128, blank=True, default="")
    district = models.CharField(max_length=128, blank=True, default="")
    region = models.CharField(max_length=128, blank=True, default="")
    latitude = models.DecimalField(max_digits=10, decimal_places=7, default=0)
    longitude = models.DecimalField(max_digits=10, decimal_places=7, default=0)
    # Trust
    verification_status = models.CharField(
        max_length=16,
        choices=PropertyVerificationStatus.choices,
        default=PropertyVerificationStatus.DRAFT,
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    attributes = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    published_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["active", "verification_status"]),
            models.Index(fields=["region", "district"]),
            models.Index(fields=["transaction_type", "price_minor"]),
            models.Index(fields=["latitude", "longitude"]),
        ]

    def __str__(self) -> str:
        return self.title


class PropertyMedia(models.Model):
    """Photos and videos attached to a listing."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="media"
    )
    kind = models.CharField(max_length=16, choices=MediaKind.choices)
    url = models.URLField(max_length=500)
    caption = models.CharField(max_length=255, blank=True, default="")
    sort_order = models.PositiveSmallIntegerField(default=0)
    is_primary = models.BooleanField(default=False)
    duration_seconds = models.PositiveIntegerField(null=True, blank=True)
    room_code = models.CharField(
        max_length=16,
        choices=TourRoomCode.choices,
        blank=True,
        default="",
    )
    tour_kind = models.CharField(
        max_length=16,
        choices=MediaTourKind.choices,
        blank=True,
        default=MediaTourKind.GALLERY,
    )
    is_hd = models.BooleanField(default=False)
    panorama_url = models.URLField(max_length=500, blank=True, default="")
    floor_plan_data = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["sort_order", "created_at"]
        verbose_name_plural = "property media"


class PropertyFavorite(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, db_index=True)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="favorites"
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("principal", "listing")]
        ordering = ["-created_at"]


class SavedSearch(models.Model):
    """Persisted search filters for alerts (foundation)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, db_index=True)
    name = models.CharField(max_length=128)
    filters = models.JSONField(default=dict)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]


class PropertyVerificationEvent(models.Model):
    """Audit trail for listing verification workflow."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="verification_events"
    )
    from_status = models.CharField(max_length=16)
    to_status = models.CharField(max_length=16)
    actor = models.CharField(max_length=128)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class PropertyViewEvent(models.Model):
    """Recently viewed listings — Phase 2 discovery."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, db_index=True)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="view_events"
    )
    viewed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-viewed_at"]
        indexes = [models.Index(fields=["principal", "-viewed_at"])]


class ViewingPassPlanCode(models.TextChoices):
    SINGLE = "single"
    BUNDLE = "bundle"
    UNLIMITED = "unlimited"


class PropertyViewingPassStatus(models.TextChoices):
    PENDING_PAYMENT = "pending_payment"
    ACTIVE = "active"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class PropertyViewingPass(models.Model):
    """Paid unlock for address, navigation, contact, and scheduling."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    principal = models.CharField(max_length=128, db_index=True)
    listing = models.ForeignKey(
        PropertyListing,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="viewing_passes",
    )
    plan_code = models.CharField(max_length=16, choices=ViewingPassPlanCode.choices)
    status = models.CharField(
        max_length=20,
        choices=PropertyViewingPassStatus.choices,
        default=PropertyViewingPassStatus.PENDING_PAYMENT,
    )
    amount_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    qr_token = models.CharField(max_length=64, unique=True, db_index=True)
    listings_unlocked = models.JSONField(default=list, blank=True)
    unlock_address = models.BooleanField(default=False)
    unlock_navigation = models.BooleanField(default=False)
    unlock_contact = models.BooleanField(default=False)
    unlock_scheduling = models.BooleanField(default=False)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["principal", "status"])]


class PropertyLiveSessionStatus(models.TextChoices):
    REQUESTED = "requested"
    SCHEDULED = "scheduled"
    LIVE = "live"
    ENDED = "ended"
    CANCELLED = "cancelled"


class PropertyLiveSession(models.Model):
    """Live property walkthrough — owner streams, customer joins."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="live_sessions"
    )
    customer_principal = models.CharField(max_length=128, db_index=True)
    owner_principal = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=16,
        choices=PropertyLiveSessionStatus.choices,
        default=PropertyLiveSessionStatus.REQUESTED,
    )
    scheduled_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    ended_at = models.DateTimeField(null=True, blank=True)
    join_code = models.CharField(max_length=16, unique=True, db_index=True)
    stream_url = models.URLField(max_length=500, blank=True, default="")
    recording_url = models.URLField(max_length=500, blank=True, default="")
    ai_transcript = models.JSONField(default=dict, blank=True)
    appointment_notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class PropertyLiveMessage(models.Model):
    """Q&A messages during a live session (feeds AI transcript)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    session = models.ForeignKey(
        PropertyLiveSession, on_delete=models.CASCADE, related_name="messages"
    )
    sender_principal = models.CharField(max_length=128)
    body = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]


class PropertyAssignmentStatus(models.TextChoices):
    ASSIGNED = "assigned"
    ACTIVE = "active"
    CLOSED = "closed"


class PropertyTimelineEventType(models.TextChoices):
    ASSIGNED = "assigned"
    MESSAGE = "message"
    DOCUMENT = "document"
    APPOINTMENT = "appointment"
    NEGOTIATION = "negotiation"
    ADVICE = "advice"
    RELOCATION = "relocation"
    APPLICATION = "application"
    CONTRACT = "contract"
    PAYMENT = "payment"
    MOVE = "move"


class PropertyAppointmentStatus(models.TextChoices):
    REQUESTED = "requested"
    CONFIRMED = "confirmed"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PropertyWingaAssignment(models.Model):
    """Human Winga assigned to help a customer with a listing."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="winga_assignments"
    )
    customer_principal = models.CharField(max_length=128, db_index=True)
    winga_principal = models.CharField(max_length=128, db_index=True)
    winga_profile_id = models.UUIDField(null=True, blank=True)
    status = models.CharField(
        max_length=16,
        choices=PropertyAssignmentStatus.choices,
        default=PropertyAssignmentStatus.ASSIGNED,
    )
    chat_thread_id = models.UUIDField(null=True, blank=True)
    winga_lead_id = models.UUIDField(null=True, blank=True)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["customer_principal", "status"])]


class PropertyTimelineEvent(models.Model):
    """Customer journey timeline — CRM foundation."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    assignment = models.ForeignKey(
        PropertyWingaAssignment, on_delete=models.CASCADE, related_name="timeline"
    )
    event_type = models.CharField(max_length=16, choices=PropertyTimelineEventType.choices)
    title = models.CharField(max_length=255)
    notes = models.TextField(blank=True, default="")
    actor = models.CharField(max_length=128)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]


class PropertySharedDocument(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    assignment = models.ForeignKey(
        PropertyWingaAssignment, on_delete=models.CASCADE, related_name="documents"
    )
    title = models.CharField(max_length=255)
    url = models.URLField(max_length=500)
    shared_by = models.CharField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class PropertyViewingAppointment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    assignment = models.ForeignKey(
        PropertyWingaAssignment, on_delete=models.CASCADE, related_name="appointments"
    )
    scheduled_at = models.DateTimeField()
    status = models.CharField(
        max_length=16,
        choices=PropertyAppointmentStatus.choices,
        default=PropertyAppointmentStatus.REQUESTED,
    )
    location_notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["scheduled_at"]


class PropertyApplicationStatus(models.TextChoices):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    UNDER_REVIEW = "under_review"
    APPROVED = "approved"
    REJECTED = "rejected"
    WITHDRAWN = "withdrawn"


class PropertyVerificationCheckKind(models.TextChoices):
    IDENTITY = "identity"
    INCOME = "income"


class PropertyVerificationCheckStatus(models.TextChoices):
    PENDING = "pending"
    VERIFIED = "verified"
    FAILED = "failed"


class PropertyApplicationDocumentKind(models.TextChoices):
    NATIONAL_ID = "national_id"
    PAYSLIP = "payslip"
    BANK_STATEMENT = "bank_statement"
    EMPLOYMENT_LETTER = "employment_letter"
    OTHER = "other"


class PropertyApplication(models.Model):
    """Tenant rental application — Phase 5 digital transactions."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="applications"
    )
    applicant_principal = models.CharField(max_length=128, db_index=True)
    assignment = models.ForeignKey(
        PropertyWingaAssignment,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="applications",
    )
    status = models.CharField(
        max_length=16,
        choices=PropertyApplicationStatus.choices,
        default=PropertyApplicationStatus.DRAFT,
    )
    employment_status = models.CharField(max_length=64, blank=True, default="")
    monthly_income_minor = models.BigIntegerField(default=0)
    national_id = models.CharField(max_length=64, blank=True, default="")
    move_in_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True, default="")
    submitted_at = models.DateTimeField(null=True, blank=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["applicant_principal", "status"])]


class PropertyApplicationDocument(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application = models.ForeignKey(
        PropertyApplication, on_delete=models.CASCADE, related_name="documents"
    )
    kind = models.CharField(
        max_length=24,
        choices=PropertyApplicationDocumentKind.choices,
        default=PropertyApplicationDocumentKind.OTHER,
    )
    title = models.CharField(max_length=255)
    url = models.URLField(max_length=500)
    uploaded_by = models.CharField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class PropertyApplicationVerification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application = models.ForeignKey(
        PropertyApplication, on_delete=models.CASCADE, related_name="verifications"
    )
    check_kind = models.CharField(max_length=16, choices=PropertyVerificationCheckKind.choices)
    status = models.CharField(
        max_length=16,
        choices=PropertyVerificationCheckStatus.choices,
        default=PropertyVerificationCheckStatus.PENDING,
    )
    provider_ref = models.CharField(max_length=128, blank=True, default="")
    details = models.JSONField(default=dict, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["check_kind"]
        unique_together = [("application", "check_kind")]


class PropertyLeaseStatus(models.TextChoices):
    DRAFT = "draft"
    PENDING_SIGNATURES = "pending_signatures"
    ACTIVE = "active"
    EXPIRED = "expired"
    TERMINATED = "terminated"


class PropertyLease(models.Model):
    """Digital lease contract generated from an approved application."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    application = models.OneToOneField(
        PropertyApplication, on_delete=models.CASCADE, related_name="lease"
    )
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="leases"
    )
    tenant_principal = models.CharField(max_length=128, db_index=True)
    owner_principal = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=20,
        choices=PropertyLeaseStatus.choices,
        default=PropertyLeaseStatus.DRAFT,
    )
    rent_minor = models.BigIntegerField(default=0)
    deposit_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    start_date = models.DateField()
    end_date = models.DateField()
    contract_text = models.TextField(blank=True, default="")
    contract_url = models.URLField(max_length=500, blank=True, default="")
    tenant_signed_at = models.DateTimeField(null=True, blank=True)
    owner_signed_at = models.DateTimeField(null=True, blank=True)
    renewal_of = models.ForeignKey(
        "self",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="renewals",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class PropertyLeasePaymentKind(models.TextChoices):
    DEPOSIT = "deposit"
    FIRST_RENT = "first_rent"
    MONTHLY_RENT = "monthly_rent"
    RENEWAL = "renewal"


class PropertyLeasePaymentStatus(models.TextChoices):
    PENDING_PAYMENT = "pending_payment"
    PAID = "paid"
    FAILED = "failed"


class PropertyLeasePayment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    lease = models.ForeignKey(
        PropertyLease, on_delete=models.CASCADE, related_name="payments"
    )
    kind = models.CharField(max_length=16, choices=PropertyLeasePaymentKind.choices)
    status = models.CharField(
        max_length=20,
        choices=PropertyLeasePaymentStatus.choices,
        default=PropertyLeasePaymentStatus.PENDING_PAYMENT,
    )
    amount_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    due_date = models.DateField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]


class PropertyMovePhase(models.TextChoices):
    MOVE_IN = "move_in"
    MOVE_OUT = "move_out"


class PropertyMoveStatus(models.TextChoices):
    SCHEDULED = "scheduled"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class PropertyMoveWorkflow(models.Model):
    """Move-in / move-out checklist workflow."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    lease = models.ForeignKey(
        PropertyLease, on_delete=models.CASCADE, related_name="move_workflows"
    )
    phase = models.CharField(max_length=16, choices=PropertyMovePhase.choices)
    status = models.CharField(
        max_length=16,
        choices=PropertyMoveStatus.choices,
        default=PropertyMoveStatus.SCHEDULED,
    )
    scheduled_at = models.DateTimeField()
    checklist = models.JSONField(default=list, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["scheduled_at"]


class PropertyReportReason(models.TextChoices):
    FRAUD = "fraud"
    MISLEADING = "misleading"
    DUPLICATE = "duplicate"
    INAPPROPRIATE = "inappropriate"
    OTHER = "other"


class PropertyModerationStatus(models.TextChoices):
    PENDING = "pending"
    UNDER_REVIEW = "under_review"
    ACTION_TAKEN = "action_taken"
    DISMISSED = "dismissed"


class PropertyModerationReport(models.Model):
    """User-reported listing — ops moderation queue."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    listing = models.ForeignKey(
        PropertyListing, on_delete=models.CASCADE, related_name="moderation_reports"
    )
    reporter_principal = models.CharField(max_length=128, db_index=True)
    reason = models.CharField(max_length=16, choices=PropertyReportReason.choices)
    notes = models.TextField(blank=True, default="")
    status = models.CharField(
        max_length=16,
        choices=PropertyModerationStatus.choices,
        default=PropertyModerationStatus.PENDING,
    )
    resolved_by = models.CharField(max_length=128, blank=True, default="")
    resolution_notes = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["status", "-created_at"])]


class PropertyDisputeStatus(models.TextChoices):
    OPEN = "open"
    INVESTIGATING = "investigating"
    RESOLVED = "resolved"
    REJECTED = "rejected"


class PropertyDisputeSubject(models.TextChoices):
    LEASE = "lease"
    APPLICATION = "application"
    LISTING = "listing"


class PropertyDispute(models.Model):
    """Property transaction dispute — ops resolution workflow."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    subject_type = models.CharField(max_length=16, choices=PropertyDisputeSubject.choices)
    subject_id = models.UUIDField(db_index=True)
    listing = models.ForeignKey(
        PropertyListing,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="disputes",
    )
    lease = models.ForeignKey(
        PropertyLease,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="disputes",
    )
    opened_by = models.CharField(max_length=128, db_index=True)
    reason = models.CharField(max_length=255)
    status = models.CharField(
        max_length=16,
        choices=PropertyDisputeStatus.choices,
        default=PropertyDisputeStatus.OPEN,
    )
    assigned_ops = models.CharField(max_length=128, blank=True, default="")
    resolution = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["status", "-created_at"])]


class PropertyOpsAuditEvent(models.Model):
    """Audit trail for ops / moderation / dispute actions."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    actor = models.CharField(max_length=128, db_index=True)
    action = models.CharField(max_length=64)
    entity_type = models.CharField(max_length=32)
    entity_id = models.UUIDField()
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
