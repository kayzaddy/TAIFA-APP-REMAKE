"""Taifa Mobility Hybrid Dispatch — channel orchestration models."""
from __future__ import annotations

import uuid

from django.db import models


class DeviceCapability(models.TextChoices):
    SMARTPHONE = "smartphone"
    FEATURE_PHONE = "feature_phone"


class ChannelKind(models.TextChoices):
    PUSH = "push"
    SMS = "sms"
    USSD = "ussd"
    IVR = "ivr"
    STAGE = "stage"


class ChannelStatus(models.TextChoices):
    PENDING = "pending"
    SENT = "sent"
    DELIVERED = "delivered"
    FAILED = "failed"
    RESPONDED = "responded"
    TIMEOUT = "timeout"


class DriverChannelBinding(models.Model):
    """Maps operational driver → MSISDN + device capabilities for hybrid dispatch."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    driver = models.OneToOneField(
        "trips.Driver", on_delete=models.CASCADE, related_name="channel_binding"
    )
    msisdn = models.CharField(max_length=20, blank=True, default="")
    msisdn_hash = models.CharField(max_length=64, blank=True, default="", db_index=True)
    device_capability = models.CharField(
        max_length=16,
        choices=DeviceCapability.choices,
        default=DeviceCapability.SMARTPHONE,
    )
    has_internet = models.BooleanField(default=True)
    has_gps = models.BooleanField(default=True)
    push_token = models.CharField(max_length=255, blank=True, default="")
    preferred_channel = models.CharField(
        max_length=16, choices=ChannelKind.choices, blank=True, default=""
    )
    battery_pct = models.PositiveSmallIntegerField(null=True, blank=True)
    reliability_score = models.DecimalField(max_digits=4, decimal_places=2, default=1.0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["msisdn_hash", "device_capability"])]


class ChannelDispatchAttempt(models.Model):
    """Audit trail for each dispatch channel attempt per offer."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    offer = models.ForeignKey(
        "trips.DispatchOffer", on_delete=models.CASCADE, related_name="channel_attempts"
    )
    trip = models.ForeignKey("trips.Trip", on_delete=models.CASCADE, related_name="channel_attempts")
    driver = models.ForeignKey("trips.Driver", on_delete=models.CASCADE, related_name="channel_attempts")
    channel = models.CharField(max_length=16, choices=ChannelKind.choices)
    status = models.CharField(
        max_length=16, choices=ChannelStatus.choices, default=ChannelStatus.PENDING
    )
    detail = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    responded_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        indexes = [models.Index(fields=["offer", "channel"])]


class InboundMessage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    channel = models.CharField(max_length=16, choices=ChannelKind.choices)
    msisdn_hash = models.CharField(max_length=64, db_index=True)
    body = models.TextField()
    parsed_action = models.CharField(max_length=32, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)


class UssdSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    msisdn_hash = models.CharField(max_length=64, db_index=True)
    state = models.CharField(max_length=32, default="root")
    data = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    expires_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class TripBoardingPin(models.Model):
    """6-digit trip verification PIN — hashed at rest."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    trip = models.OneToOneField("trips.Trip", on_delete=models.CASCADE, related_name="boarding_pin")
    pin_hash = models.CharField(max_length=128)
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
