"""Tourism DTOS — trip shell and versioned itineraries (bookings stay in commerce)."""
from __future__ import annotations

import uuid

from django.db import models


class TourismTripStatus(models.TextChoices):
    PLANNING = "planning", "Planning"
    READY = "ready", "Ready to travel"
    ACTIVE = "active", "In progress"
    COMPLETED = "completed", "Completed"
    CANCELLED = "cancelled", "Cancelled"


class TourismTrip(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    title = models.CharField(max_length=160, default="My Tanzania trip")
    status = models.CharField(
        max_length=32,
        choices=TourismTripStatus.choices,
        default=TourismTripStatus.PLANNING,
    )
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    party_size = models.PositiveSmallIntegerField(default=2)
    budget_tier = models.CharField(max_length=32, default="mid")  # budget|mid|luxury
    travel_style = models.CharField(max_length=32, default="leisure")
    interests = models.JSONField(default=list, blank=True)
    tour_booking_ids = models.JSONField(default=list, blank=True)
    stay_booking_ids = models.JSONField(default=list, blank=True)
    selected_itinerary = models.ForeignKey(
        "TourismItineraryVersion",
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="+",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]


class TourismItineraryVersion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.ForeignKey(
        TourismTrip,
        on_delete=models.CASCADE,
        related_name="itineraries",
    )
    version = models.PositiveSmallIntegerField()
    label = models.CharField(max_length=160)
    summary = models.CharField(max_length=280, blank=True, default="")
    days = models.JSONField(default=list)
    estimate_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["version"]
        unique_together = [("trip", "version")]


class TourismCheckoutStatus(models.TextChoices):
    DRAFT = "draft", "Draft"
    READY = "ready", "Ready to pay"
    PAID = "paid", "Paid"


class TourismCheckout(models.Model):
    """Unified checkout session for a trip (travel + optional protection)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.OneToOneField(
        TourismTrip,
        on_delete=models.CASCADE,
        related_name="checkout",
    )
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=16,
        choices=TourismCheckoutStatus.choices,
        default=TourismCheckoutStatus.READY,
    )
    include_insurance = models.BooleanField(default=False)
    insurance_plan_id = models.CharField(max_length=64, blank=True, default="")
    insurance_plan_name = models.CharField(max_length=128, blank=True, default="")
    insurance_provider = models.CharField(max_length=128, blank=True, default="")
    insurance_premium_minor = models.BigIntegerField(default=0)
    insurance_coverage_minor = models.BigIntegerField(default=0)
    insurance_policy_id = models.UUIDField(null=True, blank=True)
    include_esim = models.BooleanField(default=False)
    esim_plan_id = models.CharField(max_length=64, blank=True, default="")
    esim_plan_name = models.CharField(max_length=128, blank=True, default="")
    esim_price_minor = models.BigIntegerField(default=0)
    esim_order_id = models.UUIDField(null=True, blank=True)
    travel_subtotal_minor = models.BigIntegerField(default=0)
    protection_subtotal_minor = models.BigIntegerField(default=0)
    connectivity_subtotal_minor = models.BigIntegerField(default=0)
    total_minor = models.BigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    lines = models.JSONField(default=list, blank=True)
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]


class TourismEsimOrderStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    PROVISIONED = "provisioned", "Provisioned"
    ACTIVE = "active", "Active"


class TourismEsimOrder(models.Model):
    """MNO eSIM adapter spike — demo SM-DP+ payload stored server-side."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    trip = models.ForeignKey(
        TourismTrip,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="esim_orders",
    )
    plan_id = models.CharField(max_length=64)
    plan_name = models.CharField(max_length=128)
    data_gb = models.PositiveSmallIntegerField(default=5)
    days = models.PositiveSmallIntegerField(default=7)
    price_minor = models.BigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    status = models.CharField(
        max_length=16,
        choices=TourismEsimOrderStatus.choices,
        default=TourismEsimOrderStatus.PROVISIONED,
    )
    activation_code = models.CharField(max_length=64, blank=True, default="")
    qr_payload = models.TextField(blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]


class TourismAssistanceStatus(models.TextChoices):
    OPEN = "open", "Open"
    ACKNOWLEDGED = "acknowledged", "Acknowledged"
    RESOLVED = "resolved", "Resolved"


class TourismAssistanceCase(models.Model):
    """Tourism help desk / SOS ticket (links to mobility SafetyIncident)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    owner = models.CharField(max_length=128, db_index=True)
    trip = models.ForeignKey(
        TourismTrip,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name="assistance_cases",
    )
    kind = models.CharField(max_length=16, default="sos")
    status = models.CharField(
        max_length=16,
        choices=TourismAssistanceStatus.choices,
        default=TourismAssistanceStatus.OPEN,
    )
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    notes = models.CharField(max_length=500, blank=True, default="")
    safety_incident_id = models.UUIDField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
