"""Demo commerce bookings for the Foundation Sprint.

Food, hotel, flight and tourism bookings persist so history/receipts have a
durable demo backend. Catalog and lifecycle simulation stay on the mobile mocks.
"""
from __future__ import annotations

import uuid

from django.db import models


class FoodOrderStatus(models.TextChoices):
    CONFIRMED = "confirmed"
    PREPARING = "preparing"
    PICKING_UP = "picking_up"
    ON_THE_WAY = "on_the_way"
    DELIVERED = "delivered"
    PAID = "paid"
    CANCELLED = "cancelled"


class FoodOrder(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(max_length=32, choices=FoodOrderStatus.choices, default=FoodOrderStatus.CONFIRMED)
    restaurant_id = models.CharField(max_length=64)
    restaurant_name = models.CharField(max_length=128)
    subtotal_minor = models.BigIntegerField()
    delivery_fee_minor = models.BigIntegerField(default=0)
    total_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    courier_name = models.CharField(max_length=128, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class StayBookingStatus(models.TextChoices):
    RESERVED = "reserved"
    CONFIRMED = "confirmed"
    CHECKED_IN = "checked_in"
    COMPLETED = "completed"
    PAID = "paid"
    CANCELLED = "cancelled"


class StayBooking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32, choices=StayBookingStatus.choices, default=StayBookingStatus.CONFIRMED
    )
    hotel_id = models.CharField(max_length=64)
    hotel_name = models.CharField(max_length=128)
    room_name = models.CharField(max_length=128)
    check_in = models.DateField()
    check_out = models.DateField()
    guests = models.PositiveSmallIntegerField(default=2)
    nights = models.PositiveSmallIntegerField(default=1)
    nightly_rate_minor = models.BigIntegerField()
    taxes_minor = models.BigIntegerField(default=0)
    total_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    confirmation_code = models.CharField(max_length=32, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class FlightBookingStatus(models.TextChoices):
    HELD = "held"
    TICKETED = "ticketed"
    PAID = "paid"
    CANCELLED = "cancelled"


class FlightBooking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32, choices=FlightBookingStatus.choices, default=FlightBookingStatus.TICKETED
    )
    airline = models.CharField(max_length=64)
    flight_number = models.CharField(max_length=32)
    origin_code = models.CharField(max_length=8)
    destination_code = models.CharField(max_length=8)
    depart_at = models.DateTimeField()
    passengers = models.PositiveSmallIntegerField(default=1)
    total_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    pnr = models.CharField(max_length=32, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class TourBookingStatus(models.TextChoices):
    RESERVED = "reserved"
    CONFIRMED = "confirmed"
    PAID = "paid"
    CANCELLED = "cancelled"


class TourBooking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32, choices=TourBookingStatus.choices, default=TourBookingStatus.CONFIRMED
    )
    tour_id = models.CharField(max_length=64)
    tour_title = models.CharField(max_length=128)
    experience_date = models.DateField()
    guests = models.PositiveSmallIntegerField(default=2)
    total_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    confirmation_code = models.CharField(max_length=32, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class WingaOrderStatus(models.TextChoices):
    PLACED = "placed"
    DRIVER_ASSIGNED = "driver_assigned"
    PICKUP = "pickup"
    DELIVERING = "delivering"
    COMPLETED = "completed"


class WingaOrder(models.Model):
    """WINGA marketplace checkout summary (line items stay on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32, choices=WingaOrderStatus.choices, default=WingaOrderStatus.PLACED
    )
    total_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    item_count = models.PositiveSmallIntegerField(default=1)
    summary = models.CharField(max_length=255, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    courier_name = models.CharField(max_length=128, blank=True, default="")
    eta_label = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class WingaServiceBooking(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    service_id = models.CharField(max_length=64)
    service_title = models.CharField(max_length=128)
    slot_label = models.CharField(max_length=64)
    total_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class WingaShopStatus(models.TextChoices):
    DRAFT = "draft"
    PENDING = "pending"
    APPROVED = "approved"


class WingaShopApplication(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    name = models.CharField(max_length=128)
    category = models.CharField(max_length=64, default="Retail")
    address = models.CharField(max_length=255, blank=True, default="")
    status = models.CharField(
        max_length=32, choices=WingaShopStatus.choices, default=WingaShopStatus.PENDING
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class GovRequestStatus(models.TextChoices):
    SUBMITTED = "submitted"
    IN_REVIEW = "in_review"
    APPROVED = "approved"
    PAID = "paid"
    REJECTED = "rejected"


class GovRequest(models.Model):
    """Huduma-style government service request (catalog stays on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32, choices=GovRequestStatus.choices, default=GovRequestStatus.IN_REVIEW
    )
    service_id = models.CharField(max_length=64)
    service_title = models.CharField(max_length=128)
    agency = models.CharField(max_length=128, blank=True, default="")
    category = models.CharField(max_length=64, blank=True, default="")
    applicant_name = models.CharField(max_length=128)
    fee_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    eta_days = models.PositiveSmallIntegerField(default=7)
    reference = models.CharField(max_length=32, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class HealthAppointmentStatus(models.TextChoices):
    BOOKED = "booked"
    CONFIRMED = "confirmed"
    PAID = "paid"
    CANCELLED = "cancelled"


class HealthAppointment(models.Model):
    """Consult appointment summary (facility catalog stays on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=HealthAppointmentStatus.choices,
        default=HealthAppointmentStatus.CONFIRMED,
    )
    facility_id = models.CharField(max_length=64)
    facility_name = models.CharField(max_length=128)
    specialty = models.CharField(max_length=128, blank=True, default="")
    area = models.CharField(max_length=128, blank=True, default="")
    patient_name = models.CharField(max_length=128)
    slot_at = models.DateTimeField()
    fee_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    confirmation_code = models.CharField(max_length=32, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class EduPaymentStatus(models.TextChoices):
    INVOICED = "invoiced"
    PAID = "paid"
    CANCELLED = "cancelled"


class EduPayment(models.Model):
    """School term-fee invoice (school catalog stays on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32, choices=EduPaymentStatus.choices, default=EduPaymentStatus.INVOICED
    )
    school_id = models.CharField(max_length=64)
    school_name = models.CharField(max_length=128)
    level = models.CharField(max_length=64, blank=True, default="")
    area = models.CharField(max_length=128, blank=True, default="")
    student_name = models.CharField(max_length=128)
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    invoice_no = models.CharField(max_length=32, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class HousingInquiryStatus(models.TextChoices):
    SUBMITTED = "submitted"
    SCHEDULED = "scheduled"
    DEPOSIT_PAID = "deposit_paid"
    CANCELLED = "cancelled"


class HousingInquiry(models.Model):
    """Rental viewing / deposit inquiry (listings stay on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=HousingInquiryStatus.choices,
        default=HousingInquiryStatus.SCHEDULED,
    )
    listing_id = models.CharField(max_length=64)
    listing_title = models.CharField(max_length=128)
    area = models.CharField(max_length=128, blank=True, default="")
    beds = models.PositiveSmallIntegerField(default=1)
    baths = models.PositiveSmallIntegerField(default=1)
    monthly_rent_minor = models.BigIntegerField()
    deposit_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    viewing_at = models.DateTimeField(null=True, blank=True)
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class WealthContributionStatus(models.TextChoices):
    CONFIRMED = "confirmed"
    PAID = "paid"


class WealthContribution(models.Model):
    """Harambee / Vault contribution (circles stay on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=WealthContributionStatus.choices,
        default=WealthContributionStatus.PAID,
    )
    circle_id = models.CharField(max_length=64)
    circle_name = models.CharField(max_length=128)
    purpose = models.CharField(max_length=255, blank=True, default="")
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class JobAssignmentStatus(models.TextChoices):
    ACCEPTED = "accepted"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    PAID = "paid"


class JobAssignment(models.Model):
    """Gig / logistics assignment (job catalog stays on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=JobAssignmentStatus.choices,
        default=JobAssignmentStatus.ACCEPTED,
    )
    job_id = models.CharField(max_length=64)
    job_title = models.CharField(max_length=128)
    area = models.CharField(max_length=128, blank=True, default="")
    kind = models.CharField(max_length=32, default="gig")
    summary = models.CharField(max_length=255, blank=True, default="")
    pay_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class InsurancePolicyStatus(models.TextChoices):
    ACTIVE = "active"
    CANCELLED = "cancelled"


class InsurancePolicy(models.Model):
    """Insurance policy purchase (plan catalog stays on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=InsurancePolicyStatus.choices,
        default=InsurancePolicyStatus.ACTIVE,
    )
    plan_id = models.CharField(max_length=64)
    plan_name = models.CharField(max_length=128)
    provider = models.CharField(max_length=128, blank=True, default="")
    category = models.CharField(max_length=64, blank=True, default="")
    premium_minor = models.BigIntegerField()
    coverage_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    policy_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class FamilyTransferStatus(models.TextChoices):
    PENDING = "pending"
    PAID = "paid"


class FamilyTransfer(models.Model):
    """Family wallet send/request (members stay on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=FamilyTransferStatus.choices,
        default=FamilyTransferStatus.PAID,
    )
    member_id = models.CharField(max_length=64)
    member_name = models.CharField(max_length=128)
    member_role = models.CharField(max_length=64, blank=True, default="")
    member_phone = models.CharField(max_length=32, blank=True, default="")
    kind = models.CharField(max_length=16, default="send")
    amount_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    note = models.CharField(max_length=255, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class HudumaBookingStatus(models.TextChoices):
    SCHEDULED = "scheduled"
    PAID = "paid"
    CANCELLED = "cancelled"


class HudumaBooking(models.Model):
    """Home-service booking (service catalog stays on the client)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=HudumaBookingStatus.choices,
        default=HudumaBookingStatus.PAID,
    )
    service_id = models.CharField(max_length=64)
    service_title = models.CharField(max_length=128)
    category = models.CharField(max_length=64, blank=True, default="")
    provider = models.CharField(max_length=128, blank=True, default="")
    slot_label = models.CharField(max_length=64)
    price_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class MerchantOrderStatus(models.TextChoices):
    NEW = "new"
    PREPARING = "preparing"
    READY = "ready"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class MerchantOrder(models.Model):
    """Kitchen/merchant order queue (demo seed can hydrate via POST)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=MerchantOrderStatus.choices,
        default=MerchantOrderStatus.NEW,
    )
    customer_name = models.CharField(max_length=128)
    items_label = models.CharField(max_length=255)
    total_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class DriverJobStatus(models.TextChoices):
    OFFERED = "offered"
    ACCEPTED = "accepted"
    EN_ROUTE = "en_route"
    ARRIVED = "arrived"
    IN_TRIP = "in_trip"
    COMPLETED = "completed"
    DECLINED = "declined"


class DriverJob(models.Model):
    """Driver ride offer / active job (demo seed can hydrate via POST)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32,
        choices=DriverJobStatus.choices,
        default=DriverJobStatus.OFFERED,
    )
    rider_name = models.CharField(max_length=128)
    pickup = models.CharField(max_length=255)
    dropoff = models.CharField(max_length=255)
    fare_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    eta_minutes = models.PositiveSmallIntegerField(default=5)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class ChatThread(models.Model):
    """Inbox thread summary (messages live on ChatMessage)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    title = models.CharField(max_length=128)
    subtitle = models.CharField(max_length=255, blank=True, default="")
    unread = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]


class ChatMessage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    thread = models.ForeignKey(ChatThread, on_delete=models.CASCADE, related_name="messages")
    sender = models.CharField(max_length=16, default="me")  # me | them
    text = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]


class AdminCaseKind(models.TextChoices):
    KYC = "kyc"
    DISPUTE = "dispute"
    FREEZE = "freeze"


class AdminCaseStatus(models.TextChoices):
    OPEN = "open"
    REVIEWING = "reviewing"
    RESOLVED = "resolved"


class AdminCase(models.Model):
    """Ops queue item (KYC / dispute / freeze)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    kind = models.CharField(max_length=16, choices=AdminCaseKind.choices, default=AdminCaseKind.KYC)
    status = models.CharField(
        max_length=16, choices=AdminCaseStatus.choices, default=AdminCaseStatus.OPEN
    )
    title = models.CharField(max_length=128)
    subject = models.CharField(max_length=255)
    detail = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
