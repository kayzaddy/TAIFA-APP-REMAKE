"""TAIFA Mobility application services.

All state changes pass through this module. Fares are server-calculated and
financial operations delegate to the existing enterprise/payment orchestrator.
"""
from __future__ import annotations

import math
from dataclasses import dataclass
from decimal import Decimal

from django.db import transaction
from django.db.models import F, Max, Q
from django.utils import timezone

from enterprise import event_bus
from enterprise.orchestrator import PlatformContext, default_platform
from payments import audit
from payments.money import Currency, Money

from .models import (
    DispatchOffer,
    DispatchOfferStatus,
    Driver,
    DriverAvailability,
    DriverLocation,
    DriverStatus,
    Fleet,
    MobilityNotification,
    PricingRule,
    Promotion,
    SafetyIncident,
    SafetyIncidentStatus,
    Station,
    StationQueueEntry,
    Trip,
    TripEvent,
    TripKind,
    TripStatus,
    VehicleStatus,
    VerificationStatus,
)
from .realtime import broadcast_trip


class MobilityError(Exception):
    pass


MAX_DISPATCH_ATTEMPTS = 3


def notify_mobility(
    *,
    recipient_principal: str,
    event_type: str,
    deduplication_key: str,
    trip: Trip | None = None,
    station: Station | None = None,
    payload: dict | None = None,
) -> MobilityNotification:
    notification, created = MobilityNotification.objects.get_or_create(
        deduplication_key=deduplication_key[:160],
        defaults={
            "recipient_principal": recipient_principal,
            "event_type": event_type,
            "trip": trip,
            "station": station,
            "payload": payload or {},
        },
    )
    # Best-effort fan-out to configured SMS/email/push providers (never blocks trip flow).
    if created:
        try:
            from integrations.notifications import NotificationNotConfigured, deliver_notification

            meta = dict(payload or {})
            channel = str(meta.get("channel") or "")
            to = str(meta.get("to") or meta.get("msisdn") or meta.get("email") or "")
            if channel and to:
                deliver_notification(
                    channel=channel,
                    to=to,
                    subject=str(meta.get("subject") or event_type),
                    body=str(meta.get("body") or event_type),
                    metadata={"principal": recipient_principal, "event_type": event_type, **meta},
                )
        except NotificationNotConfigured:
            pass
        except Exception:  # noqa: BLE001 — delivery must not break domain writes
            pass
    return notification


@dataclass(frozen=True)
class FareQuote:
    total_minor: int
    currency: str
    breakdown: dict
    rule_code: str
    rule_version: int


@dataclass(frozen=True)
class RankedDriver:
    driver: Driver
    distance_meters: int
    eta_seconds: int
    score_e4: int


ALLOWED_TRANSITIONS: dict[str, set[str]] = {
    TripStatus.REQUESTED: {TripStatus.SEARCHING, TripStatus.CANCELLED},
    TripStatus.REQUESTING: {TripStatus.SEARCHING, TripStatus.CANCELLED},
    TripStatus.SEARCHING: {TripStatus.DRIVER_ASSIGNED, TripStatus.CANCELLED},
    TripStatus.DRIVER_ASSIGNED: {TripStatus.DRIVER_EN_ROUTE, TripStatus.CANCELLED},
    TripStatus.DRIVER_EN_ROUTE: {TripStatus.ARRIVED, TripStatus.DRIVER_ARRIVED, TripStatus.CANCELLED},
    TripStatus.ARRIVED: {TripStatus.PASSENGER_BOARDED, TripStatus.CANCELLED},
    TripStatus.DRIVER_ARRIVED: {TripStatus.PASSENGER_BOARDED, TripStatus.IN_PROGRESS, TripStatus.CANCELLED},
    TripStatus.PASSENGER_BOARDED: {TripStatus.TRIP_STARTED, TripStatus.CANCELLED},
    TripStatus.TRIP_STARTED: {TripStatus.COMPLETED},
    TripStatus.IN_PROGRESS: {TripStatus.COMPLETED},
    TripStatus.COMPLETED: {TripStatus.PAYMENT_PENDING, TripStatus.PAYMENT_CONFIRMED},
    TripStatus.PAYMENT_PENDING: {TripStatus.PAYMENT_CONFIRMED, TripStatus.CANCELLED},
    TripStatus.PAYMENT_CONFIRMED: {TripStatus.SETTLED},
}


def haversine_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> int:
    radius = 6_371_000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return int(radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))


def nearest_station(*, latitude: float, longitude: float, region: str = "") -> Station | None:
    qs = Station.objects.filter(
        active=True,
        verification_status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    )
    if region:
        qs = qs.filter(region=region)
    ranked = sorted(
        qs[:500],
        key=lambda s: haversine_meters(
            latitude, longitude, float(s.latitude), float(s.longitude)
        ),
    )
    if not ranked:
        return None
    station = ranked[0]
    distance = haversine_meters(
        latitude, longitude, float(station.latitude), float(station.longitude)
    )
    return station if distance <= station.service_radius_meters else None


def quote_fare(
    *,
    vehicle_mode: str,
    trip_kind: str,
    region: str,
    distance_meters: int,
    duration_seconds: int,
    waiting_seconds: int = 0,
    at=None,
    corporate_account: str = "",
) -> FareQuote:
    at = at or timezone.now()
    qs = PricingRule.objects.filter(
        active=True,
        vehicle_mode=vehicle_mode,
        trip_kind=trip_kind,
        effective_from__lte=at,
    )
    qs = qs.filter(effective_to__isnull=True) | qs.filter(effective_to__gt=at)
    rule = qs.filter(region=region).order_by("-version", "-effective_from").first()
    if rule is None:
        rule = qs.filter(region="").order_by("-version", "-effective_from").first()
    if rule is None:
        raise MobilityError(f"no active pricing rule for {vehicle_mode}/{region}")

    conditions = dict(rule.conditions or {})
    if corporate_account:
        corp_candidates = list(qs.order_by("-version", "-effective_from")[:50])
        for candidate in corp_candidates:
            allowed = (candidate.conditions or {}).get("corporate_accounts") or []
            if corporate_account in allowed:
                rule = candidate
                conditions = dict(rule.conditions or {})
                break
        allowed = conditions.get("corporate_accounts") or []
        if allowed and corporate_account not in allowed:
            raise MobilityError("corporate account is not authorized on this pricing rule")

    distance_minor = (distance_meters * rule.per_km_minor + 999) // 1000
    time_minor = (duration_seconds * rule.per_minute_minor + 59) // 60
    waiting_minor = (waiting_seconds * rule.waiting_per_minute_minor + 59) // 60
    subtotal = (
        rule.base_fare_minor
        + distance_minor
        + time_minor
        + waiting_minor
        + rule.station_fee_minor
    )
    multiplier_e4 = rule.night_multiplier_e4 if at.hour >= 22 or at.hour < 5 else 10000
    local = timezone.localtime(at)
    peak_hours = conditions.get("peak_hours") or [7, 8, 9, 16, 17, 18, 19]
    holidays = set(conditions.get("holidays") or [])
    is_peak = bool(conditions.get("peak_active")) or local.hour in peak_hours
    is_holiday = local.date().isoformat() in holidays
    if is_peak:
        multiplier_e4 = multiplier_e4 * rule.peak_multiplier_e4 // 10000
    holiday_mult = int(conditions.get("holiday_multiplier_e4") or 10000)
    if is_holiday and holiday_mult != 10000:
        multiplier_e4 = multiplier_e4 * holiday_mult // 10000
    traffic_mult = int(conditions.get("traffic_multiplier_e4") or 10000)
    if traffic_mult != 10000 and is_peak:
        multiplier_e4 = multiplier_e4 * traffic_mult // 10000
    if trip_kind == TripKind.GOVERNMENT:
        gov_mult = int(conditions.get("government_multiplier_e4") or 10000)
        multiplier_e4 = multiplier_e4 * gov_mult // 10000
    if corporate_account:
        corp_mult = int(conditions.get("corporate_multiplier_e4") or 10000)
        multiplier_e4 = multiplier_e4 * corp_mult // 10000
    total = max(rule.minimum_fare_minor, subtotal * multiplier_e4 // 10000)
    return FareQuote(
        total_minor=total,
        currency="TZS",
        rule_code=rule.code,
        rule_version=rule.version,
        breakdown={
            "base_minor": rule.base_fare_minor,
            "distance_minor": distance_minor,
            "time_minor": time_minor,
            "waiting_minor": waiting_minor,
            "station_fee_minor": rule.station_fee_minor,
            "multiplier_e4": multiplier_e4,
            "peak": is_peak,
            "holiday": is_holiday,
            "corporate_account": corporate_account or None,
        },
    )


@transaction.atomic
def create_trip(
    *,
    owner: str,
    pickup_name: str,
    pickup_lat: Decimal,
    pickup_lng: Decimal,
    dropoff_name: str,
    dropoff_lat: Decimal,
    dropoff_lng: Decimal,
    vehicle_mode: str,
    kind: str = TripKind.PASSENGER,
    dispatch_strategy: str = "station_first",
    region: str = "",
    estimated_distance_meters: int,
    estimated_duration_seconds: int,
    payment_method: str = "wallet",
    scheduled_at=None,
    corporate_account: str = "",
    promo_code: str = "",
    actor: str = "",
) -> Trip:
    quote = quote_fare(
        vehicle_mode=vehicle_mode,
        trip_kind=kind,
        region=region,
        distance_meters=estimated_distance_meters,
        duration_seconds=estimated_duration_seconds,
        at=scheduled_at or timezone.now(),
        corporate_account=corporate_account,
    )
    if promo_code:
        now = timezone.now()
        try:
            promotion = Promotion.objects.select_for_update().get(
                code__iexact=promo_code.strip(),
                active=True,
                starts_at__lte=now,
                ends_at__gt=now,
            )
        except Promotion.DoesNotExist as exc:
            raise MobilityError("promotion is invalid or expired") from exc
        if promotion.trip_kind and promotion.trip_kind != kind:
            raise MobilityError("promotion does not apply to this trip type")
        if promotion.region and promotion.region != region:
            raise MobilityError("promotion does not apply in this region")
        if promotion.usage_limit and promotion.usage_count >= promotion.usage_limit:
            raise MobilityError("promotion usage limit reached")
        discount = quote.total_minor * promotion.discount_bps // 10_000
        if promotion.maximum_discount_minor:
            discount = min(discount, promotion.maximum_discount_minor)
        quote = FareQuote(
            total_minor=max(0, quote.total_minor - discount),
            currency=quote.currency,
            breakdown={
                **quote.breakdown,
                "promotion_code": promotion.code,
                "promotion_discount_minor": discount,
            },
            rule_code=quote.rule_code,
            rule_version=quote.rule_version,
        )
        Promotion.objects.filter(pk=promotion.pk).update(usage_count=F("usage_count") + 1)
    pickup_lat = Decimal(str(pickup_lat))
    pickup_lng = Decimal(str(pickup_lng))
    dropoff_lat = Decimal(str(dropoff_lat))
    dropoff_lng = Decimal(str(dropoff_lng))
    station = nearest_station(
        latitude=float(pickup_lat),
        longitude=float(pickup_lng),
        region=region,
    )
    # Always set metadata explicitly — SQLite NOT NULL has no SQL DEFAULT for
    # this JSON column, so omitting it (stale workers / edge cases) 500s.
    trip = Trip.objects.create(
        owner=owner,
        status=TripStatus.REQUESTED,
        kind=kind,
        dispatch_strategy=dispatch_strategy,
        pickup_name=pickup_name,
        pickup_lat=pickup_lat,
        pickup_lng=pickup_lng,
        dropoff_name=dropoff_name,
        dropoff_lat=dropoff_lat,
        dropoff_lng=dropoff_lng,
        product_id=vehicle_mode,
        product_name=vehicle_mode.replace("_", " ").title(),
        vehicle_mode=vehicle_mode,
        fare_minor=quote.total_minor,
        currency=quote.currency,
        fare_breakdown=quote.breakdown or {},
        pricing_rule_version=quote.rule_version,
        distance_meters=estimated_distance_meters,
        duration_seconds=estimated_duration_seconds,
        payment_method=payment_method,
        corporate_account=corporate_account,
        scheduled_at=scheduled_at,
        station=station,
        metadata={},
    )
    TripEvent.objects.create(
        trip=trip,
        event_type="mobility.trip.requested",
        to_status=TripStatus.REQUESTED,
        actor=actor or owner,
        metadata={"pricing_rule": quote.rule_code, "station": str(station.id) if station else ""},
    )
    event_bus.publish(
        "mobility.trip.requested",
        aggregate_type="trip",
        aggregate_id=str(trip.id),
        owner=owner,
        payload={
            "station_id": str(station.id) if station else None,
            "fare_minor": quote.total_minor,
            "vehicle_mode": vehicle_mode,
        },
    )
    audit.record(
        actor=actor or owner,
        action="mobility.trip.request",
        resource_type="trip",
        resource_id=str(trip.id),
        after={"fare_minor": quote.total_minor, "status": trip.status},
    )
    return trip


def _latest_location(driver: Driver) -> DriverLocation | None:
    return driver.locations.order_by("-recorded_at").first()


def rank_drivers(trip: Trip, *, limit: int = 10) -> list[RankedDriver]:
    drivers = Driver.objects.filter(
        status=DriverStatus.ACTIVE,
        availability=DriverAvailability.AVAILABLE,
        identity_status=VerificationStatus.VERIFIED,
        license_status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
        vehicles__status=VehicleStatus.ACTIVE,
        vehicles__mode=trip.vehicle_mode,
        vehicles__registry_approval_id__isnull=False,
    ).filter(
        Q(fleet__isnull=True)
        | Q(
            fleet__status=VerificationStatus.VERIFIED,
            fleet__registry_approval_id__isnull=False,
        )
    ).distinct()

    strategy = trip.dispatch_strategy or "station_first"
    station = trip.station
    allow_cross_station = strategy in {
        "direct_nearby",
        "priority",
        "corporate",
        "emergency",
        "overflow",
    }
    if station and strategy == "station_first":
        drivers = drivers.filter(station=station)
    elif station and allow_cross_station:
        # City dispatch: home station first, then same district/region overflow.
        from .city_ops import overflow_candidate_stations, station_intelligence

        home_intel = station_intelligence(station)
        overflow_ids = [station.id]
        if (
            strategy in {"overflow", "direct_nearby", "emergency", "priority"}
            or home_intel["utilization_e4"] >= 8_000
            or home_intel["supply_gap"] >= 2
        ):
            overflow_ids.extend(
                row["station_id"]
                for row in overflow_candidate_stations(station, limit=8)
            )
        drivers = drivers.filter(
            Q(station_id__in=overflow_ids)
            | Q(station__region=station.region, station__district=station.district)
        )
        if strategy == "corporate" and trip.corporate_account:
            fleet_drivers = drivers.filter(
                fleet__isnull=False,
                fleet__metadata__corporate_account=trip.corporate_account,
            )
            if fleet_drivers.exists():
                drivers = fleet_drivers

    queue_positions = {
        row.driver_id: row.position
        for row in StationQueueEntry.objects.filter(
            station_id=trip.station_id, active=True
        )
    } if trip.station_id else {}
    ranked: list[RankedDriver] = []
    for driver in drivers[:800]:
        loc = _latest_location(driver)
        if loc is None:
            continue
        distance = haversine_meters(
            float(trip.pickup_lat),
            float(trip.pickup_lng),
            float(loc.latitude),
            float(loc.longitude),
        )
        # Traffic proxy: inflate ETA during known peak windows without a live feed.
        hour = timezone.localtime().hour
        traffic_factor = 1.35 if hour in {7, 8, 9, 16, 17, 18, 19} else 1.0
        eta = max(60, int((distance / 6.0) * traffic_factor))
        queue_penalty = queue_positions.get(driver.id, 50) * 150
        rating_bonus = int(driver.rating_e2) * 8
        safety_bonus = int(driver.safety_score_e2) * 6
        acceptance_bonus = int(driver.acceptance_rate_e4) // 5
        distance_penalty = min(distance, 50_000)
        cross_station_penalty = 0
        if station and driver.station_id and driver.station_id != station.id:
            cross_station_penalty = 2_500
        strategy_bonus = 0
        if strategy == "emergency":
            strategy_bonus = safety_bonus * 2 - eta
        elif strategy == "priority":
            priority = 0
            if driver.id in queue_positions:
                entry = StationQueueEntry.objects.filter(
                    driver=driver, active=True
                ).first()
                priority = entry.priority if entry else 0
            strategy_bonus = priority * 400
        elif strategy == "corporate":
            strategy_bonus = 1_500 if driver.fleet_id else 0
        score = (
            50_000
            + rating_bonus
            + safety_bonus
            + acceptance_bonus
            + strategy_bonus
            - distance_penalty
            - queue_penalty
            - cross_station_penalty
        )
        ranked.append(RankedDriver(driver, distance, eta, score))
    ranked.sort(key=lambda r: (-r.score_e4, r.distance_meters, str(r.driver.id)))
    return ranked[:limit]


@transaction.atomic
def dispatch_trip(trip_id, *, actor: str = "dispatch", offer_seconds: int = 30) -> list[DispatchOffer]:
    trip = Trip.objects.select_for_update().get(pk=trip_id)
    if trip.status not in {TripStatus.REQUESTED, TripStatus.REQUESTING, TripStatus.SEARCHING}:
        raise MobilityError(f"cannot dispatch from {trip.status}")
    if not trip.station_id:
        raise MobilityError("no approved station available for dispatch")
    if not Station.objects.filter(
        pk=trip.station_id,
        active=True,
        verification_status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    ).exists():
        raise MobilityError("station registry approval is not active")
    if trip.status != TripStatus.SEARCHING:
        transition_trip(trip.id, to_status=TripStatus.SEARCHING, actor=actor)
        trip.refresh_from_db()
    metadata = dict(trip.metadata or {})
    metadata["dispatch_attempts"] = int(metadata.get("dispatch_attempts", 0)) + 1
    trip.metadata = metadata
    trip.save(update_fields=["metadata", "updated_at"])
    ranked = rank_drivers(trip)
    expires = timezone.now() + timezone.timedelta(seconds=offer_seconds)
    offers = []
    if not ranked:
        notify_mobility(
            recipient_principal=trip.owner,
            event_type="mobility.trip.searching",
            deduplication_key=f"trip-searching:{trip.id}:{metadata['dispatch_attempts']}",
            trip=trip,
            station=trip.station,
            payload={"offers": 0},
        )
        event_bus.publish(
            "mobility.dispatch.offers_created",
            aggregate_type="trip",
            aggregate_id=str(trip.id),
            owner=trip.owner,
            payload={"offers": 0, "attempt": metadata["dispatch_attempts"]},
        )
        return offers
    for index, candidate in enumerate(ranked, start=1):
        offer, created = DispatchOffer.objects.get_or_create(
            trip=trip,
            driver=candidate.driver,
            defaults={
                "rank": index,
                "score_e4": candidate.score_e4,
                "distance_meters": candidate.distance_meters,
                "eta_seconds": candidate.eta_seconds,
                "expires_at": expires,
            },
        )
        if not created and offer.status != DispatchOfferStatus.ACCEPTED:
            offer.rank = index
            offer.score_e4 = candidate.score_e4
            offer.distance_meters = candidate.distance_meters
            offer.eta_seconds = candidate.eta_seconds
            offer.status = DispatchOfferStatus.PENDING
            offer.expires_at = expires
            offer.responded_at = None
            offer.save(
                update_fields=[
                    "rank",
                    "score_e4",
                    "distance_meters",
                    "eta_seconds",
                    "status",
                    "expires_at",
                    "responded_at",
                ]
            )
        offers.append(offer)
        Driver.objects.filter(pk=candidate.driver.id).update(
            availability=DriverAvailability.OFFERED
        )
        notify_mobility(
            recipient_principal=candidate.driver.owner_principal,
            event_type="mobility.dispatch.offer",
            deduplication_key=f"offer:{offer.id}:{expires.isoformat()}",
            trip=trip,
            station=trip.station,
            payload={"offer_id": str(offer.id), "eta_seconds": offer.eta_seconds},
        )
    notify_mobility(
        recipient_principal=trip.owner,
        event_type="mobility.trip.searching",
        deduplication_key=f"trip-searching:{trip.id}:{metadata['dispatch_attempts']}",
        trip=trip,
        station=trip.station,
        payload={"offers": len(offers)},
    )
    event_bus.publish(
        "mobility.dispatch.offers_created",
        aggregate_type="trip",
        aggregate_id=str(trip.id),
        owner=trip.owner,
        payload={"offers": len(offers), "attempt": metadata["dispatch_attempts"]},
    )
    try:
        from mobility_channels.services import fanout_dispatch_offers

        fanout_dispatch_offers(trip=trip, offers=offers)
    except Exception:
        pass
    return offers


@transaction.atomic
def accept_offer(offer_id, *, driver: Driver) -> Trip:
    offer = DispatchOffer.objects.select_for_update().select_related("trip").get(
        pk=offer_id, driver=driver
    )
    trip = Trip.objects.select_for_update().get(pk=offer.trip_id)
    if offer.status != DispatchOfferStatus.PENDING or offer.expires_at <= timezone.now():
        raise MobilityError("offer unavailable or expired")
    if trip.status != TripStatus.SEARCHING:
        raise MobilityError("trip no longer searching")
    driver.refresh_from_db()
    if (
        driver.status != DriverStatus.ACTIVE
        or driver.identity_status != VerificationStatus.VERIFIED
        or driver.license_status != VerificationStatus.VERIFIED
        or not driver.registry_approval_id
    ):
        raise MobilityError("driver registry approval is not active")
    if driver.fleet_id and not Fleet.objects.filter(
        pk=driver.fleet_id,
        status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    ).exists():
        raise MobilityError("fleet registry approval is not active")

    vehicle = driver.vehicles.filter(
        status=VehicleStatus.ACTIVE,
        mode=trip.vehicle_mode,
        insurance_status=VerificationStatus.VERIFIED,
        road_license_status=VerificationStatus.VERIFIED,
        inspection_status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    ).first()
    if vehicle is None:
        raise MobilityError("no compliant vehicle")
    offer.status = DispatchOfferStatus.ACCEPTED
    offer.responded_at = timezone.now()
    offer.save(update_fields=["status", "responded_at"])
    losing_offers = DispatchOffer.objects.filter(
        trip=trip,
        status=DispatchOfferStatus.PENDING,
    ).exclude(pk=offer.pk)
    losing_driver_ids = list(losing_offers.values_list("driver_id", flat=True))
    losing_offers.update(status=DispatchOfferStatus.CANCELLED)
    Driver.objects.filter(
        pk__in=losing_driver_ids,
        availability=DriverAvailability.OFFERED,
    ).update(availability=DriverAvailability.AVAILABLE)
    trip.driver = driver
    trip.vehicle = vehicle
    trip.driver_name = driver.full_name
    trip.vehicle_label = vehicle.registration_number
    trip.assigned_at = timezone.now()
    trip.save(
        update_fields=[
            "driver",
            "vehicle",
            "driver_name",
            "vehicle_label",
            "assigned_at",
            "updated_at",
        ]
    )
    Driver.objects.filter(pk=driver.pk).update(availability=DriverAvailability.ON_TRIP)
    StationQueueEntry.objects.filter(driver=driver, active=True).update(active=False)
    notify_mobility(
        recipient_principal=trip.owner,
        event_type="mobility.trip.driver_assigned",
        deduplication_key=f"trip-assigned:{trip.id}:{driver.id}",
        trip=trip,
        station=trip.station,
        payload={"driver_name": driver.full_name, "vehicle": vehicle.registration_number},
    )
    try:
        from mobility_channels.services import on_trip_accepted

        on_trip_accepted(trip=trip, driver=driver)
    except Exception:
        pass
    return transition_trip(
        trip.id,
        to_status=TripStatus.DRIVER_ASSIGNED,
        actor=driver.owner_principal,
    )


@transaction.atomic
def reject_offer(offer_id, *, driver: Driver, reason: str = "") -> DispatchOffer:
    offer = DispatchOffer.objects.select_for_update().select_related("trip").get(
        pk=offer_id, driver=driver
    )
    if offer.status != DispatchOfferStatus.PENDING:
        raise MobilityError("offer is not pending")
    offer.status = DispatchOfferStatus.REJECTED
    offer.responded_at = timezone.now()
    offer.save(update_fields=["status", "responded_at"])
    Driver.objects.filter(pk=driver.pk, availability=DriverAvailability.OFFERED).update(
        availability=DriverAvailability.AVAILABLE
    )
    # Acceptance rate: track rejects in metadata-style counters via integer fields.
    offered = max(driver.acceptance_rate_e4, 1)
    # Keep a soft downward adjustment so chronic rejection loses ranking priority.
    Driver.objects.filter(pk=driver.pk).update(
        acceptance_rate_e4=max(0, offered - 250)
    )
    audit.record(
        actor=driver.owner_principal,
        action="mobility.dispatch.offer_rejected",
        resource_type="dispatch_offer",
        resource_id=str(offer.id),
        reason=reason,
        after={"trip_id": str(offer.trip_id)},
    )
    pending = DispatchOffer.objects.filter(
        trip_id=offer.trip_id, status=DispatchOfferStatus.PENDING
    ).exists()
    if not pending:
        redispatch_trip(offer.trip_id, actor=driver.owner_principal, reason="all_offers_rejected")
    return offer


@transaction.atomic
def redispatch_trip(
    trip_id,
    *,
    actor: str = "dispatch",
    reason: str = "timeout",
    offer_seconds: int = 30,
) -> list[DispatchOffer]:
    trip = Trip.objects.select_for_update().get(pk=trip_id)
    if trip.status != TripStatus.SEARCHING:
        return []
    metadata = dict(trip.metadata or {})
    attempts = int(metadata.get("dispatch_attempts", 1))
    previously_offered = set(
        DispatchOffer.objects.filter(trip=trip).values_list("driver_id", flat=True)
    )
    DispatchOffer.objects.filter(trip=trip, status=DispatchOfferStatus.PENDING).update(
        status=DispatchOfferStatus.EXPIRED,
        responded_at=timezone.now(),
    )
    Driver.objects.filter(
        id__in=previously_offered,
        availability=DriverAvailability.OFFERED,
    ).update(availability=DriverAvailability.AVAILABLE)

    if attempts >= MAX_DISPATCH_ATTEMPTS:
        # Escalate: station_first → overflow → direct_nearby → cancel.
        if trip.dispatch_strategy == "station_first" and not metadata.get("overflowed"):
            trip.dispatch_strategy = "overflow"
            metadata["overflowed"] = True
            metadata["dispatch_attempts"] = attempts
            trip.metadata = metadata
            trip.save(update_fields=["dispatch_strategy", "metadata", "updated_at"])
        elif trip.dispatch_strategy in {"station_first", "overflow"} and not metadata.get("widened"):
            trip.dispatch_strategy = "direct_nearby"
            metadata["widened"] = True
            metadata["dispatch_attempts"] = attempts
            trip.metadata = metadata
            trip.save(update_fields=["dispatch_strategy", "metadata", "updated_at"])
        else:
            metadata["dispatch_exhausted"] = True
            trip.metadata = metadata
            trip.save(update_fields=["metadata", "updated_at"])
            transition_trip(
                trip.id,
                to_status=TripStatus.CANCELLED,
                actor=actor,
                metadata={"reason": f"dispatch_exhausted:{reason}"},
            )
            notify_mobility(
                recipient_principal=trip.owner,
                event_type="mobility.trip.no_drivers",
                deduplication_key=f"trip-no-drivers:{trip.id}:{attempts}",
                trip=trip,
                station=trip.station,
                payload={"reason": reason},
            )
            return []

    metadata["dispatch_attempts"] = attempts + 1
    trip.metadata = metadata
    trip.save(update_fields=["metadata", "updated_at"])

    # Prefer drivers not already offered on earlier attempts.
    ranked = [
        candidate
        for candidate in rank_drivers(trip, limit=20)
        if candidate.driver.id not in previously_offered
    ]
    if not ranked:
        ranked = rank_drivers(trip, limit=10)
    if not ranked:
        transition_trip(
            trip.id,
            to_status=TripStatus.CANCELLED,
            actor=actor,
            metadata={"reason": f"no_eligible_drivers:{reason}"},
        )
        return []

    expires = timezone.now() + timezone.timedelta(seconds=offer_seconds)
    offers: list[DispatchOffer] = []
    for index, candidate in enumerate(ranked[:5], start=1):
        offer, created = DispatchOffer.objects.get_or_create(
            trip=trip,
            driver=candidate.driver,
            defaults={
                "rank": index,
                "score_e4": candidate.score_e4,
                "distance_meters": candidate.distance_meters,
                "eta_seconds": candidate.eta_seconds,
                "expires_at": expires,
            },
        )
        if not created:
            offer.rank = index
            offer.score_e4 = candidate.score_e4
            offer.distance_meters = candidate.distance_meters
            offer.eta_seconds = candidate.eta_seconds
            offer.status = DispatchOfferStatus.PENDING
            offer.expires_at = expires
            offer.responded_at = None
            offer.save(
                update_fields=[
                    "rank",
                    "score_e4",
                    "distance_meters",
                    "eta_seconds",
                    "status",
                    "expires_at",
                    "responded_at",
                ]
            )
        offers.append(offer)
        Driver.objects.filter(pk=candidate.driver.id).update(
            availability=DriverAvailability.OFFERED
        )
        notify_mobility(
            recipient_principal=candidate.driver.owner_principal,
            event_type="mobility.dispatch.offer",
            deduplication_key=f"offer:{offer.id}:{offer.expires_at.isoformat()}",
            trip=trip,
            station=trip.station,
            payload={"offer_id": str(offer.id), "eta_seconds": offer.eta_seconds},
        )
    event_bus.publish(
        "mobility.dispatch.redispatched",
        aggregate_type="trip",
        aggregate_id=str(trip.id),
        owner=trip.owner,
        payload={"offers": len(offers), "attempt": attempts + 1, "reason": reason},
    )
    return offers


def _normalize_queue(station_id) -> None:
    entries = list(
        StationQueueEntry.objects.select_for_update()
        .filter(station_id=station_id, active=True)
        .order_by("-priority", "position", "joined_at")
    )
    for index, entry in enumerate(entries, start=1):
        if entry.position != index:
            entry.position = index
            entry.save(update_fields=["position"])


@transaction.atomic
def join_station_queue(*, station: Station, driver: Driver) -> StationQueueEntry:
    if not station.active or station.verification_status != VerificationStatus.VERIFIED:
        raise MobilityError("station is not approved for queue operations")
    if not station.registry_approval_id:
        raise MobilityError("station registry approval is inactive")
    if driver.station_id != station.id:
        raise MobilityError("driver is not assigned to this station")
    if (
        driver.status != DriverStatus.ACTIVE
        or not driver.registry_approval_id
        or driver.availability
        not in {
            DriverAvailability.AVAILABLE,
            DriverAvailability.OFFLINE,
            DriverAvailability.BREAK,
        }
    ):
        raise MobilityError("driver is not eligible to join the queue")
    active_count = StationQueueEntry.objects.filter(station=station, active=True).count()
    if active_count >= station.capacity:
        raise MobilityError("station queue is at capacity")
    max_position = (
        StationQueueEntry.objects.filter(station=station, active=True).aggregate(
            p=Max("position")
        )["p"]
        or 0
    )
    entry, _ = StationQueueEntry.objects.update_or_create(
        driver=driver,
        defaults={
            "station": station,
            "position": max_position + 1,
            "active": True,
            "priority": 0,
        },
    )
    if driver.availability == DriverAvailability.OFFLINE:
        Driver.objects.filter(pk=driver.pk).update(availability=DriverAvailability.AVAILABLE)
    notify_mobility(
        recipient_principal=driver.owner_principal,
        event_type="mobility.queue.joined",
        deduplication_key=f"queue-join:{station.id}:{driver.id}:{entry.position}",
        station=station,
        payload={"position": entry.position},
    )
    return entry


@transaction.atomic
def leave_station_queue(*, driver: Driver) -> None:
    entry = StationQueueEntry.objects.select_for_update().filter(driver=driver, active=True).first()
    if entry is None:
        return
    station_id = entry.station_id
    entry.active = False
    entry.save(update_fields=["active"])
    _normalize_queue(station_id)


@transaction.atomic
def reorder_station_queue(
    *,
    station: Station,
    ordered_driver_ids: list,
    actor: str,
) -> list[StationQueueEntry]:
    if station.manager_principal != actor:
        raise MobilityError("only the station manager may reorder the queue")
    entries = {
        str(row.driver_id): row
        for row in StationQueueEntry.objects.select_for_update()
        .select_related("driver")
        .filter(station=station, active=True)
    }
    if set(map(str, ordered_driver_ids)) != set(entries):
        raise MobilityError("queue reorder must include every active driver exactly once")
    # Two-phase update avoids unique active position collisions.
    for offset, driver_id in enumerate(ordered_driver_ids, start=1):
        entry = entries[str(driver_id)]
        entry.position = 10_000 + offset
        entry.save(update_fields=["position"])
    result = []
    for position, driver_id in enumerate(ordered_driver_ids, start=1):
        entry = entries[str(driver_id)]
        entry.position = position
        entry.save(update_fields=["position"])
        result.append(entry)
        notify_mobility(
            recipient_principal=entry.driver.owner_principal,
            event_type="mobility.queue.position",
            deduplication_key=f"queue-pos:{station.id}:{entry.driver_id}:{position}:{timezone.now().timestamp()}",
            station=station,
            payload={"position": position},
        )
    audit.record(
        actor=actor,
        action="mobility.queue.reorder",
        resource_type="station",
        resource_id=str(station.id),
        after={"order": [str(value) for value in ordered_driver_ids]},
    )
    return result


def return_driver_to_station_queue(driver: Driver) -> None:
    if not driver.station_id:
        Driver.objects.filter(pk=driver.pk).update(availability=DriverAvailability.AVAILABLE)
        return
    station = Station.objects.filter(
        pk=driver.station_id,
        active=True,
        verification_status=VerificationStatus.VERIFIED,
        registry_approval_id__isnull=False,
    ).first()
    if station is None:
        Driver.objects.filter(pk=driver.pk).update(availability=DriverAvailability.AVAILABLE)
        return
    Driver.objects.filter(pk=driver.pk).update(availability=DriverAvailability.AVAILABLE)
    driver.availability = DriverAvailability.AVAILABLE
    try:
        join_station_queue(station=station, driver=driver)
    except MobilityError:
        pass


@transaction.atomic
def transition_trip(trip_id, *, to_status: str, actor: str, metadata: dict | None = None) -> Trip:
    trip = Trip.objects.select_for_update().get(pk=trip_id)
    previous = trip.status
    if to_status not in ALLOWED_TRANSITIONS.get(previous, set()):
        raise MobilityError(f"illegal trip transition {previous} → {to_status}")
    trip.status = to_status
    trip.lifecycle_version += 1
    now = timezone.now()
    timestamp_fields: list[str] = []
    if to_status == TripStatus.DRIVER_ASSIGNED:
        trip.assigned_at = trip.assigned_at or now
        timestamp_fields.append("assigned_at")
    elif to_status in {TripStatus.ARRIVED, TripStatus.DRIVER_ARRIVED}:
        trip.arrived_at = now
        timestamp_fields.append("arrived_at")
    elif to_status in {TripStatus.TRIP_STARTED, TripStatus.IN_PROGRESS}:
        trip.started_at = now
        timestamp_fields.append("started_at")
    elif to_status == TripStatus.COMPLETED:
        trip.completed_at = now
        timestamp_fields.append("completed_at")
    elif to_status == TripStatus.CANCELLED:
        trip.cancelled_at = now
        timestamp_fields.append("cancelled_at")
    trip.save(update_fields=["status", "lifecycle_version", "updated_at", *timestamp_fields])
    TripEvent.objects.create(
        trip=trip,
        event_type=f"mobility.trip.{to_status}",
        from_status=previous,
        to_status=to_status,
        actor=actor,
        metadata=metadata or {},
    )
    event_bus.publish(
        f"mobility.trip.{to_status}",
        aggregate_type="trip",
        aggregate_id=str(trip.id),
        owner=trip.owner,
        payload={"from": previous, "to": to_status, **(metadata or {})},
    )
    audit.record(
        actor=actor,
        action=f"mobility.trip.{to_status}",
        resource_type="trip",
        resource_id=str(trip.id),
        before={"status": previous},
        after={"status": to_status},
    )
    broadcast_trip(
        trip.id,
        f"mobility.trip.{to_status}",
        {
            "trip_id": str(trip.id),
            "from": previous,
            "to": to_status,
            **(metadata or {}),
        },
    )
    notify_mobility(
        recipient_principal=trip.owner,
        event_type=f"mobility.trip.{to_status}",
        deduplication_key=f"trip-status:{trip.id}:{to_status}:{trip.lifecycle_version}",
        trip=trip,
        station=trip.station,
        payload={"from": previous, "to": to_status},
    )
    if to_status in {TripStatus.COMPLETED, TripStatus.CANCELLED} and trip.driver_id:
        driver = Driver.objects.filter(pk=trip.driver_id).first()
        if driver is not None:
            return_driver_to_station_queue(driver)
            notify_mobility(
                recipient_principal=driver.owner_principal,
                event_type=f"mobility.trip.{to_status}",
                deduplication_key=f"driver-trip:{trip.id}:{to_status}:{trip.lifecycle_version}",
                trip=trip,
                station=trip.station,
                payload={"from": previous, "to": to_status},
            )
    return trip


@transaction.atomic
def collect_trip_payment(trip_id, *, actor: str, idempotency_key: str) -> Trip:
    """Collect a completed trip through Taifa Enterprise Payments.

    Cash is never synthesized as a ledger payment. It remains PAYMENT_PENDING
    until a station/merchant collection is reconciled by the payment platform.
    """
    trip = Trip.objects.select_for_update().select_related("station__payment_merchant").get(
        pk=trip_id
    )
    if trip.payment_transaction_id:
        return trip
    if trip.status != TripStatus.COMPLETED:
        raise MobilityError("trip must be completed before payment")
    if trip.payment_method == "cash":
        return transition_trip(
            trip.id,
            to_status=TripStatus.PAYMENT_PENDING,
            actor=actor,
            metadata={"reason": "cash awaiting station reconciliation"},
        )
    merchant = trip.station.payment_merchant if trip.station_id else None
    if merchant is None:
        raise MobilityError("station has no Taifa merchant settlement account")
    payment_txn = default_platform().capture_merchant_payment(
        ctx=PlatformContext(actor=actor),
        merchant=merchant,
        payer_owner=trip.owner,
        amount=Money(trip.fare_minor, Currency.from_code(trip.currency)),
        idempotency_key=idempotency_key,
        note=f"Mobility trip {trip.id}",
    )
    trip.payment_transaction = payment_txn
    trip.payment_ref = str(payment_txn.id)
    trip.save(update_fields=["payment_transaction", "payment_ref", "updated_at"])
    trip = transition_trip(
        trip.id,
        to_status=TripStatus.PAYMENT_CONFIRMED,
        actor=actor,
        metadata={"payment_transaction_id": str(payment_txn.id)},
    )
    if trip.driver_id:
        Driver.objects.filter(pk=trip.driver_id).update(
            completed_trips=F("completed_trips") + 1
        )
        driver = Driver.objects.filter(pk=trip.driver_id).first()
        if driver is not None:
            return_driver_to_station_queue(driver)
        notify_mobility(
            recipient_principal=trip.owner,
            event_type="mobility.payment.received",
            deduplication_key=f"payment:{trip.id}:{payment_txn.id}",
            trip=trip,
            station=trip.station,
            payload={"payment_transaction_id": str(payment_txn.id)},
        )
    return trip


ALLOWED_INCIDENT_TRANSITIONS = {
    SafetyIncidentStatus.OPEN: {
        SafetyIncidentStatus.ACKNOWLEDGED,
        SafetyIncidentStatus.FALSE_ALARM,
        SafetyIncidentStatus.RESOLVED,
    },
    SafetyIncidentStatus.ACKNOWLEDGED: {
        SafetyIncidentStatus.RESPONDING,
        SafetyIncidentStatus.RESOLVED,
        SafetyIncidentStatus.FALSE_ALARM,
    },
    SafetyIncidentStatus.RESPONDING: {
        SafetyIncidentStatus.RESOLVED,
        SafetyIncidentStatus.FALSE_ALARM,
    },
}


@transaction.atomic
def transition_incident(
    incident_id,
    *,
    to_status: str,
    actor: str,
    assigned_to: str = "",
    notes: str = "",
) -> SafetyIncident:
    incident = SafetyIncident.objects.select_for_update().get(pk=incident_id)
    allowed = ALLOWED_INCIDENT_TRANSITIONS.get(incident.status, set())
    if to_status not in allowed:
        raise MobilityError(f"illegal incident transition {incident.status} → {to_status}")
    before = incident.status
    incident.status = to_status
    if assigned_to:
        incident.assigned_to = assigned_to
    elif not incident.assigned_to:
        incident.assigned_to = actor
    details = dict(incident.details or {})
    history = list(details.get("workflow", []))
    history.append(
        {
            "from": before,
            "to": to_status,
            "actor": actor,
            "notes": notes,
            "at": timezone.now().isoformat(),
        }
    )
    details["workflow"] = history[-40:]
    incident.details = details
    fields = ["status", "assigned_to", "details"]
    if to_status in {SafetyIncidentStatus.RESOLVED, SafetyIncidentStatus.FALSE_ALARM}:
        incident.resolved_at = timezone.now()
        fields.append("resolved_at")
    incident.save(update_fields=fields)
    audit.record(
        actor=actor,
        action=f"mobility.incident.{to_status}",
        resource_type="safety_incident",
        resource_id=str(incident.id),
        before={"status": before},
        after={"status": to_status, "assigned_to": incident.assigned_to},
        reason=notes,
    )
    notify_mobility(
        recipient_principal=incident.assigned_to or actor,
        event_type=f"mobility.incident.{to_status}",
        deduplication_key=f"incident:{incident.id}:{to_status}:{len(history)}",
        trip=incident.trip,
        payload={"incident_id": str(incident.id), "kind": incident.kind},
    )
    return incident
