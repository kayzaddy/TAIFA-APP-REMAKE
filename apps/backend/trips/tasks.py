"""Celery jobs for scheduled dispatch, retries, projections, and compliance."""
from __future__ import annotations

from datetime import date

from celery import shared_task
from django.db.models import Avg, Count, Q, Sum
from django.utils import timezone

from .models import (
    DispatchOffer,
    DispatchOfferStatus,
    Driver,
    DriverAvailability,
    MobilityDailyMetric,
    Trip,
    TripStatus,
)
from .services import MobilityError, dispatch_trip, redispatch_trip
from .intelligence import refresh_driver_performance_scores
from .passenger_views import materialize_recurring_rides
from .national_ops import build_national_daily_metrics


@shared_task(name="mobility.dispatch_scheduled")
def dispatch_scheduled_trips() -> dict:
    now = timezone.now()
    trips = list(
        Trip.objects.filter(
            status=TripStatus.REQUESTED,
            scheduled_at__isnull=False,
            scheduled_at__lte=now + timezone.timedelta(minutes=15),
        ).values_list("id", flat=True)[:500]
    )
    dispatched = 0
    for trip_id in trips:
        try:
            dispatch_trip(trip_id, actor="celery:scheduled-dispatch")
            dispatched += 1
        except MobilityError:
            continue
    return {"eligible": len(trips), "dispatched": dispatched}


@shared_task(name="mobility.expire_dispatch_offers")
def expire_dispatch_offers() -> dict:
    """Expire timed-out offers and redispatch SEARCHING trips automatically."""
    now = timezone.now()
    offers = list(
        DispatchOffer.objects.filter(
            status=DispatchOfferStatus.PENDING,
            expires_at__lte=now,
        ).values_list("id", "driver_id", "trip_id")[:2000]
    )
    ids = [row[0] for row in offers]
    driver_ids = [row[1] for row in offers]
    trip_ids = sorted({row[2] for row in offers})
    DispatchOffer.objects.filter(id__in=ids).update(
        status=DispatchOfferStatus.EXPIRED,
        responded_at=now,
    )
    Driver.objects.filter(
        id__in=driver_ids,
        availability=DriverAvailability.OFFERED,
    ).update(availability=DriverAvailability.AVAILABLE)

    redispatched = 0
    cancelled = 0
    for trip_id in trip_ids:
        trip = Trip.objects.filter(pk=trip_id, status=TripStatus.SEARCHING).first()
        if trip is None:
            continue
        still_pending = DispatchOffer.objects.filter(
            trip_id=trip_id, status=DispatchOfferStatus.PENDING
        ).exists()
        if still_pending:
            continue
        result = redispatch_trip(
            trip_id,
            actor="celery:expire-offers",
            reason="offer_timeout",
        )
        if result:
            redispatched += 1
        elif Trip.objects.filter(pk=trip_id, status=TripStatus.CANCELLED).exists():
            cancelled += 1
    return {
        "expired": len(ids),
        "redispatched": redispatched,
        "cancelled": cancelled,
    }


@shared_task(name="mobility.refresh_driver_performance")
def refresh_driver_performance() -> dict:
    return refresh_driver_performance_scores()


@shared_task(name="mobility.materialize_recurring_rides")
def materialize_recurring_rides_task() -> dict:
    return materialize_recurring_rides()


@shared_task(name="mobility.build_national_daily_metrics")
def build_national_daily_metrics_task(day_iso: str | None = None) -> dict:
    from datetime import date

    day = date.fromisoformat(day_iso) if day_iso else None
    return build_national_daily_metrics(day=day)


@shared_task(name="mobility.build_daily_metrics")
def build_daily_metrics(day_iso: str | None = None) -> dict:
    day = (
        date.fromisoformat(day_iso)
        if day_iso
        else timezone.localdate() - timezone.timedelta(days=1)
    )
    completed_q = Q(
        status__in=[
            TripStatus.COMPLETED,
            TripStatus.PAYMENT_PENDING,
            TripStatus.PAYMENT_CONFIRMED,
            TripStatus.SETTLED,
        ]
    )
    cancelled_q = Q(status=TripStatus.CANCELLED)
    rows = (
        Trip.objects.filter(created_at__date=day)
        .values("station_id", "station__region", "currency")
        .annotate(
            requested=Count("id"),
            completed=Count("id", filter=completed_q),
            cancelled=Count("id", filter=cancelled_q),
            fare=Sum("fare_minor", filter=completed_q),
            average_duration=Avg("duration_seconds", filter=completed_q),
        )
    )
    # ETA quality: time from request → assigned for completed trips that day.
    eta_by_station: dict = {}
    for trip in Trip.objects.filter(
        created_at__date=day,
        assigned_at__isnull=False,
        requested_at__isnull=False,
    ).only("station_id", "requested_at", "assigned_at")[:20_000]:
        if not trip.station_id or not trip.requested_at or not trip.assigned_at:
            continue
        eta_by_station.setdefault(trip.station_id, []).append(
            max(0, int((trip.assigned_at - trip.requested_at).total_seconds()))
        )
    written = 0
    for row in rows:
        station_id = row["station_id"]
        eta_samples = eta_by_station.get(station_id, [])
        avg_eta = int(sum(eta_samples) / len(eta_samples)) if eta_samples else 0
        MobilityDailyMetric.objects.update_or_create(
            date=day,
            region=row["station__region"] or "unassigned",
            station_id=station_id,
            defaults={
                "requested": row["requested"] or 0,
                "completed": row["completed"] or 0,
                "cancelled": row["cancelled"] or 0,
                "accepted": row["completed"] or 0,
                "fare_minor": row["fare"] or 0,
                "average_eta_seconds": avg_eta,
                "average_trip_seconds": int(row["average_duration"] or 0),
                "currency": row["currency"],
            },
        )
        written += 1
    return {"date": str(day), "rows": written}
