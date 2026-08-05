"""Prometheus metrics for Taifa Mobility."""
from __future__ import annotations

from django.db.models import Count
from django.utils import timezone
from prometheus_client import Gauge

from payments.metrics import _registry

from .models import (
    DispatchOffer,
    DispatchOfferStatus,
    Driver,
    DriverAvailability,
    SafetyIncident,
    Station,
    StationQueueEntry,
    Trip,
    TripStatus,
)

TRIPS_BY_STATUS = Gauge(
    "taifa_mobility_trips",
    "Mobility trips by lifecycle status",
    ["status"],
    registry=_registry,
)
DRIVERS_BY_AVAILABILITY = Gauge(
    "taifa_mobility_drivers",
    "Drivers by availability",
    ["availability"],
    registry=_registry,
)
STATIONS_ACTIVE = Gauge(
    "taifa_mobility_stations_active",
    "Active transport stations",
    registry=_registry,
)
STATION_QUEUE_DEPTH = Gauge(
    "taifa_mobility_station_queue_depth",
    "Active station queue depth aggregated by region",
    ["region"],
    registry=_registry,
)
DISPATCH_OFFERS_PENDING = Gauge(
    "taifa_mobility_dispatch_offers_pending",
    "Pending, unexpired dispatch offers",
    registry=_registry,
)
SAFETY_INCIDENTS_OPEN = Gauge(
    "taifa_mobility_safety_incidents_open",
    "Open safety incidents by severity",
    ["severity"],
    registry=_registry,
)
PAYMENT_PENDING_TRIPS = Gauge(
    "taifa_mobility_payment_pending_trips",
    "Completed trips awaiting Taifa Payment confirmation",
    ["method"],
    registry=_registry,
)


def refresh_mobility_metrics() -> None:
    status_counts = {
        row["status"]: row["count"]
        for row in Trip.objects.values("status").annotate(count=Count("id"))
    }
    for value, _ in TripStatus.choices:
        TRIPS_BY_STATUS.labels(status=value).set(status_counts.get(value, 0))

    availability_counts = {
        row["availability"]: row["count"]
        for row in Driver.objects.values("availability").annotate(count=Count("id"))
    }
    for value, _ in DriverAvailability.choices:
        DRIVERS_BY_AVAILABILITY.labels(availability=value).set(
            availability_counts.get(value, 0)
        )

    STATIONS_ACTIVE.set(Station.objects.filter(active=True).count())
    STATION_QUEUE_DEPTH.clear()
    queue_counts = {
        row["station__region"]: row["count"]
        for row in StationQueueEntry.objects.filter(
            station__active=True,
            active=True,
        )
        .values("station__region")
        .annotate(count=Count("id"))
    }
    for region in Station.objects.filter(active=True).values_list("region", flat=True).distinct():
        STATION_QUEUE_DEPTH.labels(region=region).set(queue_counts.get(region, 0))
    DISPATCH_OFFERS_PENDING.set(
        DispatchOffer.objects.filter(
            status=DispatchOfferStatus.PENDING,
            expires_at__gt=timezone.now(),
        ).count()
    )
    incident_counts = {
        row["severity"]: row["count"]
        for row in SafetyIncident.objects.filter(status="open")
        .values("severity")
        .annotate(count=Count("id"))
    }
    SAFETY_INCIDENTS_OPEN.clear()
    for severity in ("critical", "high", "medium", "low", *incident_counts):
        SAFETY_INCIDENTS_OPEN.labels(severity=severity).set(
            incident_counts.get(severity, 0)
        )
    payment_counts = {
        row["payment_method"]: row["count"]
        for row in Trip.objects.filter(status=TripStatus.PAYMENT_PENDING)
        .values("payment_method")
        .annotate(count=Count("id"))
    }
    PAYMENT_PENDING_TRIPS.clear()
    for method in ("wallet", "card", "mobile_money", "cash", "corporate", *payment_counts):
        PAYMENT_PENDING_TRIPS.labels(method=method).set(payment_counts.get(method, 0))
