"""National Operations Center aggregations — extends city_ops, does not replace it."""
from __future__ import annotations

from django.db.models import Count, Sum
from django.utils import timezone

from .city_ops import city_map_snapshot, regional_kpis
from .models import (
    Driver,
    DriverAvailability,
    DriverStatus,
    Fleet,
    SafetyIncident,
    SafetyIncidentStatus,
    Station,
    Trip,
    TripStatus,
    VerificationStatus,
)
from .national_models import (
    EmergencyDispatchRequest,
    IntercityDeparture,
    LogisticsShipment,
    NationalDailyMetric,
    PublicTransitRoute,
)


TERMINAL = {
    TripStatus.COMPLETED,
    TripStatus.CANCELLED,
    TripStatus.PAYMENT_CONFIRMED,
    TripStatus.SETTLED,
}


def list_regions() -> list[str]:
    return sorted(
        Station.objects.filter(active=True)
        .values_list("region", flat=True)
        .distinct()
    )


def national_command_center() -> dict:
    today = timezone.localdate()
    regions = list_regions()
    regional = [regional_kpis(region=region) for region in regions]
    live_trips = Trip.objects.exclude(status__in=TERMINAL).count()
    available_drivers = Driver.objects.filter(
        status=DriverStatus.ACTIVE,
        availability=DriverAvailability.AVAILABLE,
        registry_approval_id__isnull=False,
    ).count()
    stations = Station.objects.filter(
        active=True,
        verification_status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    ).count()
    fleets = Fleet.objects.filter(
        status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    ).count()
    open_sos = SafetyIncident.objects.filter(status=SafetyIncidentStatus.OPEN).count()
    emergency_open = EmergencyDispatchRequest.objects.exclude(
        status__in=["resolved", "cancelled"]
    ).count()
    intercity_today = IntercityDeparture.objects.filter(departs_at__date=today).count()
    logistics_open = LogisticsShipment.objects.exclude(
        status__in=["delivered", "cancelled"]
    ).count()
    pt_routes = PublicTransitRoute.objects.filter(active=True).count()
    from .transit_services import transit_ops_snapshot

    transit = transit_ops_snapshot()
    fare_today = (
        Trip.objects.filter(completed_at__date=today).aggregate(total=Sum("fare_minor"))["total"]
        or 0
    )
    completed_today = Trip.objects.filter(completed_at__date=today).count()
    requested_today = Trip.objects.filter(created_at__date=today).count()
    degraded = sum(1 for row in regional if row["system_health"] != "healthy")
    if open_sos or emergency_open:
        health = "critical"
    elif degraded:
        health = "degraded"
    else:
        health = "healthy"
    return {
        "generated_at": timezone.now().isoformat(),
        "regions": regions,
        "regional_kpis": regional,
        "national": {
            "regions": len(regions),
            "stations": stations,
            "fleets": fleets,
            "available_drivers": available_drivers,
            "live_trips": live_trips,
            "trips_today": requested_today,
            "completed_today": completed_today,
            "fare_today_minor": fare_today,
            "open_sos": open_sos,
            "emergency_open": emergency_open,
            "intercity_departures_today": intercity_today,
            "logistics_open": logistics_open,
            "public_transit_routes": pt_routes,
            "transit": transit,
            "system_health": health,
            "completion_rate_e4": int((completed_today * 10_000) / requested_today)
            if requested_today
            else 0,
        },
        "model_version": "national-command-center-v1",
    }


def national_map_layers(*, region: str | None = None) -> dict:
    regions = [region] if region else list_regions()
    layers = []
    for reg in regions:
        snap = city_map_snapshot(region=reg)
        layers.append(
            {
                "region": reg,
                "summary": snap["summary"],
                "stations": snap["stations"],
                "sos": snap["sos"],
                "trips_sample": snap["trips"][:100],
                "drivers_sample": snap["drivers"][:200],
            }
        )
    return {
        "generated_at": timezone.now().isoformat(),
        "layers": layers,
        "model_version": "national-map-v1",
    }


def build_national_daily_metrics(*, day=None) -> dict:
    day = day or (timezone.localdate() - timezone.timedelta(days=1))
    completed_statuses = [
        TripStatus.COMPLETED,
        TripStatus.PAYMENT_PENDING,
        TripStatus.PAYMENT_CONFIRMED,
        TripStatus.SETTLED,
    ]
    rows = (
        Trip.objects.filter(created_at__date=day)
        .values(
            "station__region",
            "station__district",
            "vehicle_mode",
            "kind",
            "currency",
        )
        .annotate(
            requested=Count("id"),
            completed=Count("id", filter=models_Q_status(completed_statuses)),
            cancelled=Count("id", filter=models_Q_status([TripStatus.CANCELLED])),
            fare=Sum("fare_minor", filter=models_Q_status(completed_statuses)),
        )
    )
    written = 0
    for row in rows:
        region = row["station__region"] or "unassigned"
        district = row["station__district"] or ""
        sos = SafetyIncident.objects.filter(
            created_at__date=day,
            trip__station__region=region,
        ).count()
        NationalDailyMetric.objects.update_or_create(
            date=day,
            region=region,
            district=district,
            vehicle_mode=row["vehicle_mode"] or "",
            trip_kind=row["kind"] or "",
            defaults={
                "requested": row["requested"] or 0,
                "completed": row["completed"] or 0,
                "cancelled": row["cancelled"] or 0,
                "fare_minor": row["fare"] or 0,
                "sos_count": sos,
                "currency": row["currency"] or "TZS",
            },
        )
        written += 1
    return {"date": str(day), "rows": written}


def models_Q_status(statuses):
    from django.db.models import Q

    return Q(status__in=statuses)


def national_analytics(*, region: str = "", days: int = 30) -> dict:
    since = timezone.localdate() - timezone.timedelta(days=days)
    qs = NationalDailyMetric.objects.filter(date__gte=since)
    if region:
        qs = qs.filter(region__iexact=region)
    by_region = (
        qs.values("region")
        .annotate(
            requested=Sum("requested"),
            completed=Sum("completed"),
            cancelled=Sum("cancelled"),
            fare=Sum("fare_minor"),
            sos=Sum("sos_count"),
        )
        .order_by("-requested")
    )
    by_mode = (
        qs.values("vehicle_mode")
        .annotate(requested=Sum("requested"), completed=Sum("completed"), fare=Sum("fare_minor"))
        .order_by("-requested")
    )
    by_kind = (
        qs.values("trip_kind")
        .annotate(requested=Sum("requested"), completed=Sum("completed"))
        .order_by("-requested")
    )
    return {
        "lookback_days": days,
        "region_filter": region or "national",
        "by_region": list(by_region),
        "by_vehicle_mode": list(by_mode),
        "by_trip_kind": list(by_kind),
        "model_version": "national-analytics-v1",
    }


def national_optimization_recommendations() -> dict:
    """AI platform recommendations aggregated from city intelligence contracts."""
    from .intelligence import forecast_city_demand
    from .city_ops import load_balance_recommendations

    regions = list_regions()
    demand = []
    balance = []
    expansion = []
    for region in regions:
        forecast = forecast_city_demand(region=region, horizon_minutes=120)
        demand.append(
            {
                "region": region,
                "predicted_requests": forecast["predicted_requests_total"],
                "hotspots": forecast["hotspots"][:5],
            }
        )
        recs = load_balance_recommendations(region=region)
        balance.extend([{**row, "region": region} for row in recs[:5]])
        for hot in forecast["hotspots"][:3]:
            if hot["predicted_requests"] >= 5:
                expansion.append(
                    {
                        "region": region,
                        "station_id": hot["station_id"],
                        "station": hot["name"],
                        "reason": "sustained_high_demand",
                        "predicted_requests": hot["predicted_requests"],
                    }
                )
    return {
        "demand": demand,
        "fleet_balancing": balance[:50],
        "station_expansion": expansion[:50],
        "model_version": "national-optimization-v1",
    }
