"""City-scale mobility operations built on station-first MDMP primitives.

This module does not replace dispatch or registry. It aggregates station,
driver, trip, and incident state into city/region decision surfaces and
feeds overflow / load-balancing recommendations into the existing dispatcher.
"""
from __future__ import annotations

from django.db.models import Q, Sum
from django.utils import timezone

from .models import (
    Driver,
    DriverAvailability,
    DriverLocation,
    DriverStatus,
    Fleet,
    SafetyIncident,
    SafetyIncidentStatus,
    Station,
    StationQueueEntry,
    Trip,
    TripStatus,
    VehicleStatus,
    VerificationStatus,
)
from .services import haversine_meters
from .intelligence import forecast_station_demand, driver_positioning_recommendations


TERMINAL_TRIP = {
    TripStatus.COMPLETED,
    TripStatus.CANCELLED,
    TripStatus.PAYMENT_CONFIRMED,
    TripStatus.SETTLED,
}


def _station_scope(*, region: str = "", district: str = "", ward: str = ""):
    qs = Station.objects.filter(
        active=True,
        verification_status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    )
    if region:
        qs = qs.filter(region__iexact=region)
    if district:
        qs = qs.filter(district__iexact=district)
    if ward:
        qs = qs.filter(ward__iexact=ward)
    return qs


def station_intelligence(station: Station) -> dict:
    """Live smart-station scorecard used by rankings and alerts."""
    today = timezone.localdate()
    drivers = station.drivers.all()
    trips_today = station.trips.filter(created_at__date=today)
    requested = trips_today.count()
    completed = trips_today.filter(completed_at__date=today).count()
    cancelled = trips_today.filter(cancelled_at__date=today).count()
    queue_length = StationQueueEntry.objects.filter(station=station, active=True).count()
    available = drivers.filter(availability=DriverAvailability.AVAILABLE).count()
    online = drivers.filter(
        availability__in=[
            DriverAvailability.AVAILABLE,
            DriverAvailability.OFFERED,
            DriverAvailability.ON_TRIP,
            DriverAvailability.BUSY,
        ]
    ).count()
    on_trip = drivers.filter(availability=DriverAvailability.ON_TRIP).count()
    backlog = trips_today.filter(
        status__in=[TripStatus.REQUESTED, TripStatus.SEARCHING]
    ).count()
    forecast = forecast_station_demand(station)
    utilization = int((queue_length * 10_000) / station.capacity) if station.capacity else 0
    queue_health = max(0, 10_000 - utilization)
    supply_gap = max(0, forecast.predicted_requests - available)
    demand_score = min(10_000, forecast.predicted_requests * 500 + backlog * 800)
    completion_rate = int((completed * 10_000) / requested) if requested else 8_000
    cancel_penalty = int((cancelled * 10_000) / requested) if requested else 0
    performance = max(0, completion_rate - cancel_penalty // 2)
    open_sos = SafetyIncident.objects.filter(
        status=SafetyIncidentStatus.OPEN,
        trip__station=station,
    ).count()
    alerts: list[str] = []
    if open_sos:
        alerts.append("open_sos")
    if utilization >= 9_000:
        alerts.append("queue_saturated")
    if supply_gap >= 3:
        alerts.append("driver_shortage")
    if backlog >= 5:
        alerts.append("passenger_backlog")
    if cancelled > completed and requested >= 5:
        alerts.append("high_cancellation")
    if open_sos or utilization >= 9_500:
        health = "critical"
    elif alerts:
        health = "degraded"
    else:
        health = "healthy"
    rank_score = (
        performance // 2
        + queue_health // 4
        + max(0, 4_000 - supply_gap * 400)
        + max(0, 2_000 - open_sos * 1_000)
    )
    return {
        "station_id": str(station.id),
        "code": station.code,
        "name": station.name,
        "region": station.region,
        "district": station.district,
        "ward": station.ward,
        "capacity": station.capacity,
        "queue_length": queue_length,
        "online_drivers": online,
        "available_drivers": available,
        "drivers_on_trip": on_trip,
        "passenger_backlog": backlog,
        "requested_today": requested,
        "completed_today": completed,
        "cancelled_today": cancelled,
        "demand_score_e4": demand_score,
        "queue_health_e4": queue_health,
        "utilization_e4": utilization,
        "supply_gap": supply_gap,
        "performance_e4": performance,
        "predicted_requests": forecast.predicted_requests,
        "forecast_confidence_e4": forecast.confidence_e4,
        "open_sos": open_sos,
        "station_health": health,
        "alerts": alerts,
        "rank_score_e4": rank_score,
        "positioning": driver_positioning_recommendations(station),
        "model_version": "station-intelligence-v1",
    }


def rank_stations(*, region: str = "", district: str = "", limit: int = 50) -> list[dict]:
    rows = [station_intelligence(station) for station in _station_scope(region=region, district=district)[:200]]
    rows.sort(key=lambda row: (-row["rank_score_e4"], row["name"]))
    for index, row in enumerate(rows[:limit], start=1):
        row["rank"] = index
    return rows[:limit]


def overflow_candidate_stations(station: Station, *, limit: int = 5) -> list[dict]:
    """Nearest approved stations in the same district/region for overflow routing."""
    peers = (
        _station_scope(region=station.region, district=station.district)
        .exclude(pk=station.pk)[:100]
    )
    scored = []
    for peer in peers:
        distance = haversine_meters(
            float(station.latitude),
            float(station.longitude),
            float(peer.latitude),
            float(peer.longitude),
        )
        intel = station_intelligence(peer)
        # Prefer nearby stations with spare capacity and healthy queues.
        score = 20_000 - min(distance, 20_000) + intel["queue_health_e4"] // 2 - intel["supply_gap"] * 300
        scored.append(
            {
                "station_id": str(peer.id),
                "code": peer.code,
                "name": peer.name,
                "distance_meters": distance,
                "available_drivers": intel["available_drivers"],
                "queue_health_e4": intel["queue_health_e4"],
                "score_e4": score,
            }
        )
    scored.sort(key=lambda row: (-row["score_e4"], row["distance_meters"]))
    return scored[:limit]


def load_balance_recommendations(*, region: str, district: str = "") -> list[dict]:
    rankings = rank_stations(region=region, district=district, limit=100)
    stations_by_id = {
        str(s.id): s
        for s in Station.objects.filter(id__in=[row["station_id"] for row in rankings])
    }
    surplus = [row for row in rankings if row["available_drivers"] - row["predicted_requests"] >= 2]
    deficit = [row for row in rankings if row["supply_gap"] >= 2]
    recommendations = []
    for needy in deficit[:20]:
        needy_station = stations_by_id.get(needy["station_id"])
        if needy_station is None:
            continue
        donors = []
        for row in surplus:
            donor_station = stations_by_id.get(row["station_id"])
            if donor_station is None or donor_station.id == needy_station.id:
                continue
            distance = haversine_meters(
                float(needy_station.latitude),
                float(needy_station.longitude),
                float(donor_station.latitude),
                float(donor_station.longitude),
            )
            donors.append((distance, row))
        if not donors:
            continue
        donors.sort(key=lambda item: item[0])
        donor = donors[0][1]
        move = min(donor["available_drivers"] // 2, needy["supply_gap"])
        if move <= 0:
            continue
        recommendations.append(
            {
                "from_station_id": donor["station_id"],
                "from_station": donor["name"],
                "to_station_id": needy["station_id"],
                "to_station": needy["name"],
                "drivers_to_reposition": move,
                "reason": "supply_gap",
                "model_version": "load-balance-v1",
            }
        )
    return recommendations


def city_map_snapshot(
    *,
    region: str,
    district: str = "",
    bbox: tuple[float, float, float, float] | None = None,
) -> dict:
    """Read-only GIS layer for city operations (stations, drivers, trips, SOS)."""
    stations = list(_station_scope(region=region, district=district)[:500])
    station_ids = [s.id for s in stations]
    if bbox:
        min_lat, min_lng, max_lat, max_lng = bbox
        stations = [
            s
            for s in stations
            if min_lat <= float(s.latitude) <= max_lat and min_lng <= float(s.longitude) <= max_lng
        ]
        station_ids = [s.id for s in stations]

    drivers = Driver.objects.filter(
        status=DriverStatus.ACTIVE,
        station_id__in=station_ids,
        registry_approval_id__isnull=False,
    ).select_related("station")[:5_000]
    latest_locations: dict = {}
    for loc in DriverLocation.objects.filter(
        driver_id__in=[d.id for d in drivers]
    ).order_by("-recorded_at")[:20_000]:
        latest_locations.setdefault(loc.driver_id, loc)

    driver_points = []
    idle = 0
    for driver in drivers:
        loc = latest_locations.get(driver.id)
        if loc is None:
            continue
        if driver.availability == DriverAvailability.AVAILABLE:
            idle += 1
        driver_points.append(
            {
                "driver_id": str(driver.id),
                "station_id": str(driver.station_id) if driver.station_id else None,
                "availability": driver.availability,
                "latitude": str(loc.latitude),
                "longitude": str(loc.longitude),
                "recorded_at": loc.recorded_at.isoformat(),
            }
        )

    active_trips = Trip.objects.filter(station_id__in=station_ids).exclude(status__in=TERMINAL_TRIP)
    trip_points = [
        {
            "trip_id": str(trip.id),
            "status": trip.status,
            "station_id": str(trip.station_id) if trip.station_id else None,
            "pickup_lat": str(trip.pickup_lat),
            "pickup_lng": str(trip.pickup_lng),
            "dropoff_lat": str(trip.dropoff_lat),
            "dropoff_lng": str(trip.dropoff_lng),
            "vehicle_mode": trip.vehicle_mode,
        }
        for trip in active_trips[:2_000]
    ]
    sos_qs = SafetyIncident.objects.filter(
        status__in=[
            SafetyIncidentStatus.OPEN,
            SafetyIncidentStatus.ACKNOWLEDGED,
            SafetyIncidentStatus.RESPONDING,
        ],
    ).filter(Q(trip__station_id__in=station_ids) | Q(trip__isnull=True)).order_by("-created_at")
    sos_rows = list(sos_qs[:200])

    station_points = []
    for station in stations:
        intel = station_intelligence(station)
        station_points.append(
            {
                "station_id": str(station.id),
                "code": station.code,
                "name": station.name,
                "latitude": str(station.latitude),
                "longitude": str(station.longitude),
                "region": station.region,
                "district": station.district,
                "demand_score_e4": intel["demand_score_e4"],
                "queue_length": intel["queue_length"],
                "available_drivers": intel["available_drivers"],
                "station_health": intel["station_health"],
            }
        )

    return {
        "region": region,
        "district": district,
        "generated_at": timezone.now().isoformat(),
        "stations": station_points,
        "drivers": driver_points,
        "trips": trip_points,
        "sos": [
            {
                "id": str(row.id),
                "kind": row.kind,
                "severity": row.severity,
                "status": row.status,
                "latitude": str(row.latitude) if row.latitude is not None else None,
                "longitude": str(row.longitude) if row.longitude is not None else None,
                "trip_id": str(row.trip_id) if row.trip_id else None,
            }
            for row in sos_rows
        ],
        "summary": {
            "stations": len(station_points),
            "drivers_visible": len(driver_points),
            "idle_drivers": idle,
            "live_trips": len(trip_points),
            "open_sos": sum(1 for row in sos_rows if row.status == SafetyIncidentStatus.OPEN),
            "transit": _transit_ops_block(region=region),
        },
        "model_version": "city-map-v1",
    }


def regional_kpis(*, region: str, district: str = "") -> dict:
    today = timezone.localdate()
    stations = _station_scope(region=region, district=district)
    station_ids = list(stations.values_list("id", flat=True))
    trips = Trip.objects.filter(station_id__in=station_ids, created_at__date=today)
    requested = trips.count()
    completed = trips.filter(completed_at__date=today).count()
    cancelled = trips.filter(status=TripStatus.CANCELLED).count()
    live = Trip.objects.filter(station_id__in=station_ids).exclude(status__in=TERMINAL_TRIP).count()
    available = Driver.objects.filter(
        station_id__in=station_ids,
        availability=DriverAvailability.AVAILABLE,
        status=DriverStatus.ACTIVE,
    ).count()
    queue_total = StationQueueEntry.objects.filter(station_id__in=station_ids, active=True).count()
    fare = (
        trips.filter(completed_at__date=today).aggregate(total=Sum("fare_minor"))["total"] or 0
    )
    open_sos = SafetyIncident.objects.filter(
        status=SafetyIncidentStatus.OPEN,
        trip__station_id__in=station_ids,
    ).count()
    return {
        "region": region,
        "district": district,
        "stations": len(station_ids),
        "live_trips": live,
        "available_drivers": available,
        "queue_length_total": queue_total,
        "trips_today": requested,
        "completed_today": completed,
        "cancelled_today": cancelled,
        "completion_rate_e4": int((completed * 10_000) / requested) if requested else 0,
        "cancellation_rate_e4": int((cancelled * 10_000) / requested) if requested else 0,
        "fare_today_minor": fare,
        "open_sos": open_sos,
        "system_health": "critical" if open_sos else ("degraded" if cancelled > completed else "healthy"),
        "transit": _transit_ops_block(region=region),
        "model_version": "regional-kpi-v1",
    }


def _transit_ops_block(*, region: str) -> dict:
    from .transit_services import transit_ops_snapshot

    return transit_ops_snapshot(region=region)


def fleet_intelligence(fleet: Fleet) -> dict:
    today = timezone.localdate()
    drivers = fleet.drivers.all()
    vehicles = fleet.vehicles.all()
    trips = Trip.objects.filter(driver__fleet=fleet)
    trips_today = trips.filter(created_at__date=today)
    completed = trips.filter(
        status__in=[TripStatus.COMPLETED, TripStatus.PAYMENT_CONFIRMED, TripStatus.SETTLED]
    )
    maintenance_due = sum(
        1
        for v in vehicles
        if v.next_maintenance_at_km and v.odometer_km >= v.next_maintenance_at_km
    )
    online = drivers.filter(
        availability__in=[
            DriverAvailability.AVAILABLE,
            DriverAvailability.OFFERED,
            DriverAvailability.ON_TRIP,
        ]
    ).count()
    attendance = drivers.filter(
        availability__in=[
            DriverAvailability.AVAILABLE,
            DriverAvailability.OFFERED,
            DriverAvailability.ON_TRIP,
            DriverAvailability.BREAK,
            DriverAvailability.BUSY,
        ]
    ).count()
    gross = (
        trips.filter(payment_transaction__isnull=False).aggregate(total=Sum("fare_minor"))["total"]
        or 0
    )
    requested = trips_today.count()
    completed_today = trips_today.filter(completed_at__date=today).count()
    return {
        "fleet_id": str(fleet.id),
        "name": fleet.name,
        "fleet_type": fleet.fleet_type,
        "status": fleet.status,
        "drivers": drivers.count(),
        "vehicles": vehicles.count(),
        "online_drivers": online,
        "attendance_today": attendance,
        "active_trips": trips.exclude(status__in=TERMINAL_TRIP).count(),
        "trips_today": requested,
        "completed_today": completed_today,
        "completion_rate_e4": int((completed_today * 10_000) / requested) if requested else 0,
        "gross_fare_minor": gross,
        "maintenance_due": maintenance_due,
        "compliant_vehicles": vehicles.filter(
            status=VehicleStatus.ACTIVE,
            insurance_status=VerificationStatus.VERIFIED,
            road_license_status=VerificationStatus.VERIFIED,
            inspection_status=VerificationStatus.VERIFIED,
            registry_approval_id__isnull=False,
        ).count(),
        "model_version": "fleet-intelligence-v1",
    }
