"""Taifa Express models — orchestration control plane only.

Money → commerce pay → enterprise capture (settlement plan recorded here).
Delivery → trips.create_trip / dispatch_trip + trips.Delivery POD.
"""
from __future__ import annotations

import secrets
import uuid

from django.db import models


class StoreCategory(models.TextChoices):
    GROCERIES = "groceries"
    PHARMACY = "pharmacy"
    HARDWARE = "hardware"
    ELECTRONICS = "electronics"
    HOME = "home"
    BABY = "baby"
    PETS = "pets"
    VEGETABLES = "vegetables"
    FRUITS = "fruits"
    BAKERY = "bakery"
    RESTAURANT = "restaurant"
    FASHION = "fashion"
    STATIONERY = "stationery"
    OTHER = "other"


class ExpressOrderStatus(models.TextChoices):
    DRAFT = "draft"
    RANKED = "ranked"
    PLACED = "placed"
    MERCHANT_FOUND = "merchant_found"
    MERCHANT_ACCEPTED = "merchant_accepted"
    PREPARING = "preparing"
    READY = "ready"
    RIDER_ASSIGNED = "rider_assigned"
    RIDER_ARRIVING = "rider_arriving"
    PICKED_UP = "picked_up"
    DELIVERING = "delivering"
    ARRIVING = "arriving"
    DELIVERED = "delivered"
    COMPLETED = "completed"
    PAID = "paid"
    CANCELLED = "cancelled"
    FAILED = "failed"


class PaymentTiming(models.TextChoices):
    PREPAID = "prepaid"
    ON_DELIVERY = "on_delivery"


class SettlementStatus(models.TextChoices):
    PENDING = "pending"
    ALLOCATED = "allocated"
    SETTLED = "settled"
    FAILED = "failed"


def _code(prefix: str) -> str:
    return f"{prefix}_{secrets.token_urlsafe(6)}"


class ExpressStore(models.Model):
    """Hyperlocal storefront profile — may link to enterprise.Merchant / MOS."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.SlugField(max_length=64, unique=True)
    name = models.CharField(max_length=255)
    category = models.CharField(
        max_length=32, choices=StoreCategory.choices, default=StoreCategory.GROCERIES
    )
    merchant = models.ForeignKey(
        "enterprise.Merchant",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="express_stores",
    )
    logo_url = models.URLField(blank=True, default="")
    banner_url = models.URLField(blank=True, default="")
    lat = models.DecimalField(max_digits=9, decimal_places=6, default=0)
    lng = models.DecimalField(max_digits=9, decimal_places=6, default=0)
    delivery_radius_m = models.PositiveIntegerField(default=3000)
    prep_minutes = models.PositiveIntegerField(default=15)
    rating = models.DecimalField(max_digits=3, decimal_places=2, default=4.5)
    reliability = models.DecimalField(max_digits=3, decimal_places=2, default=0.9)
    workload = models.PositiveIntegerField(default=0)
    operating_hours = models.JSONField(default=dict, blank=True)
    verified = models.BooleanField(default=True)
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["category", "active"])]

    def __str__(self) -> str:
        return self.name


class ExpressProduct(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    store = models.ForeignKey(ExpressStore, on_delete=models.CASCADE, related_name="products")
    sku = models.CharField(max_length=64)
    name = models.CharField(max_length=255)
    category = models.CharField(max_length=64, blank=True, default="")
    price_minor = models.PositiveBigIntegerField()
    currency = models.CharField(max_length=8, default="TZS")
    stock_qty = models.PositiveIntegerField(default=10)
    stock_status = models.CharField(max_length=24, default="available")
    image_url = models.URLField(blank=True, default="")
    tags = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=True)

    class Meta:
        unique_together = [("store", "sku")]
        indexes = [models.Index(fields=["name", "active"])]


class ExpressOrder(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    public_code = models.CharField(max_length=48, unique=True, db_index=True)
    package_code = models.CharField(max_length=48, unique=True, blank=True, default="")
    package_qr = models.CharField(max_length=255, blank=True, default="")
    packing_checklist = models.JSONField(default=list, blank=True)
    owner = models.CharField(max_length=128, db_index=True)
    status = models.CharField(
        max_length=32, choices=ExpressOrderStatus.choices, default=ExpressOrderStatus.DRAFT
    )
    store = models.ForeignKey(
        ExpressStore, on_delete=models.PROTECT, null=True, blank=True, related_name="orders"
    )
    lines = models.JSONField(default=list, blank=True)
    subtotal_minor = models.PositiveBigIntegerField(default=0)
    delivery_fee_minor = models.PositiveBigIntegerField(default=0)
    platform_fee_minor = models.PositiveBigIntegerField(default=0)
    total_minor = models.PositiveBigIntegerField(default=0)
    currency = models.CharField(max_length=8, default="TZS")
    urgency = models.CharField(max_length=16, blank=True, default="standard")
    payment_timing = models.CharField(
        max_length=16, choices=PaymentTiming.choices, default=PaymentTiming.PREPAID
    )
    payment_method = models.CharField(max_length=24, blank=True, default="wallet")
    customer_lat = models.DecimalField(max_digits=9, decimal_places=6, default=0)
    customer_lng = models.DecimalField(max_digits=9, decimal_places=6, default=0)
    customer_address = models.CharField(max_length=255, blank=True, default="")
    customer_phone = models.CharField(max_length=32, blank=True, default="")
    customer_notes = models.CharField(max_length=500, blank=True, default="")
    promo_code = models.CharField(max_length=32, blank=True, default="")
    ranking = models.JSONField(default=list, blank=True)
    # Downstream refs (no duplicated money/trip engines)
    food_order_id = models.UUIDField(null=True, blank=True, db_index=True)
    mos_order_id = models.UUIDField(null=True, blank=True, db_index=True)
    trip_id = models.UUIDField(null=True, blank=True, db_index=True)
    delivery_id = models.UUIDField(null=True, blank=True, db_index=True)
    payment_ref = models.CharField(max_length=64, blank=True, default="")
    tap_session_code = models.CharField(max_length=48, blank=True, default="")
    delivery_pin = models.CharField(max_length=12, blank=True, default="")
    settlement_plan = models.JSONField(default=dict, blank=True)
    settlement_status = models.CharField(
        max_length=16, choices=SettlementStatus.choices, default=SettlementStatus.PENDING
    )
    eta_minutes = models.PositiveIntegerField(default=0)
    merchant_notes = models.TextField(blank=True, default="")
    timeline = models.JSONField(default=list, blank=True)
    ai_prompt = models.CharField(max_length=512, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["owner", "status"])]

    def save(self, *args, **kwargs):
        if not self.public_code:
            self.public_code = _code("xp")
        if not self.package_code:
            self.package_code = _code("pkg")
            self.package_qr = f"taifa://express/pkg/{self.package_code}"
        super().save(*args, **kwargs)
