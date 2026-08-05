"""Auditable mobility intelligence foundations.

These are deterministic baselines, not opaque "AI" claims. They provide stable
interfaces that can later call versioned ML models without changing dispatch.
"""
from __future__ import annotations

from dataclasses import dataclass

from django.db.models import Avg, Sum
from django.utils import timezone

from .models import (
    DispatchOffer,
    DispatchOfferStatus,
    Driver,
    MobilityDailyMetric,
    Rating,
    SafetyIncident,
    Station,
    Trip,
    TripStatus,
    Vehicle,
)


@dataclass(frozen=True)
class DemandForecast:
    station_id: str
    horizon_minutes: int
    predicted_requests: int
    confidence_e4: int
    model_version: str = "seasonal-baseline-v2"


def forecast_station_demand(
    station: Station,
    *,
    horizon_minutes: int = 60,
    lookback_days: int = 28,
) -> DemandForecast:
    since = timezone.localdate() - timezone.timedelta(days=lookback_days)
    now = timezone.localtime()
    metrics = list(
        MobilityDailyMetric.objects.filter(station=station, date__gte=since).values(
            "requested", "date"
        )
    )
    average_daily = (
        sum(row["requested"] for row in metrics) / len(metrics) if metrics else 0
    )
    # Hour-of-day seasonality: peak commute windows carry more weight.
    hour_weight = 1.6 if now.hour in {7, 8, 9, 16, 17, 18, 19} else (
        0.7 if 0 <= now.hour < 5 else 1.0
    )
    weekday_weight = 1.15 if now.weekday() < 5 else 0.85
    predicted = max(
        0,
        round(float(average_daily) * horizon_minutes / (24 * 60) * hour_weight * weekday_weight),
    )
    sample_days = len(metrics)
    confidence = min(9200, 3200 + sample_days * 200)
    return DemandForecast(
        station_id=str(station.id),
        horizon_minutes=horizon_minutes,
        predicted_requests=predicted,
        confidence_e4=confidence,
    )


def forecast_city_demand(*, region: str, district: str = "", horizon_minutes: int = 60) -> dict:
    stations = Station.objects.filter(
        active=True,
        region__iexact=region,
        verification_status="verified",
        registry_approval_id__isnull=False,
    )
    if district:
        stations = stations.filter(district__iexact=district)
    cells = []
    total = 0
    for station in stations[:300]:
        forecast = forecast_station_demand(station, horizon_minutes=horizon_minutes)
        total += forecast.predicted_requests
        cells.append(
            {
                "station_id": str(station.id),
                "code": station.code,
                "name": station.name,
                "latitude": str(station.latitude),
                "longitude": str(station.longitude),
                "predicted_requests": forecast.predicted_requests,
                "confidence_e4": forecast.confidence_e4,
            }
        )
    cells.sort(key=lambda row: -row["predicted_requests"])
    return {
        "region": region,
        "district": district,
        "horizon_minutes": horizon_minutes,
        "predicted_requests_total": total,
        "hotspots": cells[:25],
        "cells": cells,
        "model_version": "city-demand-heatmap-v1",
    }


def driver_positioning_recommendations(station: Station) -> dict:
    forecast = forecast_station_demand(station)
    available = station.drivers.filter(availability="available").count()
    gap = max(0, forecast.predicted_requests - available)
    return {
        "station_id": str(station.id),
        "predicted_requests": forecast.predicted_requests,
        "available_drivers": available,
        "additional_drivers_recommended": gap,
        "model_version": forecast.model_version,
    }


def maintenance_prediction(vehicle: Vehicle) -> dict:
    remaining = max(0, vehicle.next_maintenance_at_km - vehicle.odometer_km)
    due = bool(vehicle.next_maintenance_at_km and remaining == 0)
    return {
        "vehicle_id": str(vehicle.id),
        "odometer_km": vehicle.odometer_km,
        "remaining_km": remaining,
        "maintenance_due": due,
        "model_version": "odometer-threshold-v1",
    }


def trip_fraud_signals(trip: Trip) -> dict:
    signals: list[str] = []
    if trip.distance_meters <= 0:
        signals.append("missing_distance")
    if trip.duration_seconds <= 0:
        signals.append("missing_duration")
    if trip.fare_minor <= 0:
        signals.append("non_positive_fare")
    duplicate_window = Trip.objects.filter(
        owner=trip.owner,
        pickup_lat=trip.pickup_lat,
        pickup_lng=trip.pickup_lng,
        dropoff_lat=trip.dropoff_lat,
        dropoff_lng=trip.dropoff_lng,
        created_at__gte=trip.created_at - timezone.timedelta(minutes=5),
        created_at__lte=trip.created_at + timezone.timedelta(minutes=5),
    ).exclude(pk=trip.pk).count()
    if duplicate_window:
        signals.append("duplicate_route_request")
    return {
        "trip_id": str(trip.id),
        "signals": signals,
        "risk_score_e4": min(10000, len(signals) * 2500),
        "model_version": "mobility-rules-v1",
    }


def driver_performance(driver: Driver, *, lookback_days: int = 30) -> dict:
    since = timezone.now() - timezone.timedelta(days=lookback_days)
    trips = Trip.objects.filter(driver=driver, created_at__gte=since)
    offered = DispatchOffer.objects.filter(driver=driver, created_at__gte=since)
    accepted = offered.filter(status=DispatchOfferStatus.ACCEPTED).count()
    rejected = offered.filter(status=DispatchOfferStatus.REJECTED).count()
    expired = offered.filter(status=DispatchOfferStatus.EXPIRED).count()
    total_offers = offered.count()
    completed = trips.filter(
        status__in=[TripStatus.COMPLETED, TripStatus.PAYMENT_CONFIRMED, TripStatus.SETTLED]
    ).count()
    cancelled = trips.filter(status=TripStatus.CANCELLED).count()
    requested = trips.count()
    revenue = (
        trips.filter(payment_transaction__isnull=False).aggregate(total=Sum("fare_minor"))["total"]
        or 0
    )
    ratings = Rating.objects.filter(trip__driver=driver, created_at__gte=since)
    avg_rating = ratings.aggregate(value=Avg("score"))["value"]
    sos = SafetyIncident.objects.filter(
        trip__driver=driver, created_at__gte=since
    ).count()
    acceptance_rate = int((accepted * 10_000) / total_offers) if total_offers else driver.acceptance_rate_e4
    completion_rate = int((completed * 10_000) / requested) if requested else 0
    cancel_rate = int((cancelled * 10_000) / requested) if requested else 0
    # Reward score used by city rankings (does not auto-suspend).
    reward_score = max(
        0,
        acceptance_rate // 3
        + completion_rate // 3
        + int((avg_rating or 4.0) * 800)
        + min(2_000, completed * 40)
        - cancel_rate // 2
        - sos * 800,
    )
    return {
        "driver_id": str(driver.id),
        "full_name": driver.full_name,
        "lookback_days": lookback_days,
        "offers": total_offers,
        "accepted": accepted,
        "rejected": rejected,
        "expired": expired,
        "acceptance_rate_e4": acceptance_rate,
        "trips": requested,
        "completed": completed,
        "cancelled": cancelled,
        "completion_rate_e4": completion_rate,
        "cancellation_rate_e4": cancel_rate,
        "average_rating": float(avg_rating) if avg_rating is not None else None,
        "trips_per_day": round(completed / max(1, lookback_days), 2),
        "revenue_minor": revenue,
        "safety_incidents": sos,
        "reward_score_e4": reward_score,
        "high_performer": reward_score >= 7_500,
        "model_version": "driver-performance-v1",
    }


def refresh_driver_performance_scores(*, limit: int = 2_000) -> dict:
    """Recompute acceptance_rate_e4 from recent offer outcomes (ops job)."""
    since = timezone.now() - timezone.timedelta(days=30)
    updated = 0
    for driver in Driver.objects.filter(status="active")[:limit]:
        offered = DispatchOffer.objects.filter(driver=driver, created_at__gte=since)
        total = offered.count()
        if not total:
            continue
        accepted = offered.filter(status=DispatchOfferStatus.ACCEPTED).count()
        rate = int((accepted * 10_000) / total)
        Driver.objects.filter(pk=driver.pk).update(acceptance_rate_e4=rate)
        updated += 1
    return {"updated": updated, "model_version": "driver-performance-refresh-v1"}


def rank_drivers_city(*, region: str, district: str = "", limit: int = 50) -> list[dict]:
    drivers = Driver.objects.filter(
        status="active",
        station__region__iexact=region,
        registry_approval_id__isnull=False,
    )
    if district:
        drivers = drivers.filter(station__district__iexact=district)
    rows = [driver_performance(driver) for driver in drivers[:500]]
    rows.sort(key=lambda row: (-row["reward_score_e4"], -row["completed"]))
    for index, row in enumerate(rows[:limit], start=1):
        row["rank"] = index
    return rows[:limit]
