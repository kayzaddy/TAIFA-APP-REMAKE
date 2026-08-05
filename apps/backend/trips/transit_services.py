"""Taifa Mobility BRT — Phase 1 transit home, ticketing, and validation."""
from __future__ import annotations

import hashlib
import hmac
import json
import math
import re
import secrets
from typing import Any

from django.conf import settings
from django.db import transaction
from django.db.models import Sum
from django.utils import timezone

from commerce.services import CommerceError, ensure_platform_commerce_merchant
from enterprise.orchestrator import PlatformContext, default_platform
from payments.money import Currency, Money

from .national_models import (
    PublicTransitRoute,
    PublicTransitTimetable,
    TransitAlert,
    TransitAuditEvent,
    TransitAvlVehicle,
    TransitDailyMetric,
    TransitFavorite,
    TransitFamilyMember,
    TransitFeedback,
    TransitLostFoundItem,
    TransitNotification,
    TransitPassengerProfile,
    TransitScheduledRun,
    TransitStationProfile,
    TransitTicketProduct,
    TransportTicket,
)
from .services import MobilityError
from .transit_realtime import broadcast_transit_avl


def _signing_key() -> bytes:
    return settings.SECRET_KEY.encode("utf-8")


def _haversine_m(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    r = 6_371_000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlng / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def _ticket_code(prefix: str = "BRT") -> str:
    return f"{prefix}-{secrets.token_hex(8).upper()}"


def _canonical_payload(*, ticket_id: str, media_code: str, expires_at: int) -> str:
    return f"{ticket_id}:{media_code}:{expires_at}"


def _sign_payload(*, ticket_id: str, media_code: str, expires_at: int) -> str:
    body = _canonical_payload(ticket_id=ticket_id, media_code=media_code, expires_at=expires_at)
    return hmac.new(_signing_key(), body.encode("utf-8"), hashlib.sha256).hexdigest()


def _build_media_payload(ticket: TransportTicket) -> dict[str, Any]:
    expires_at = int(ticket.valid_to.timestamp())
    sig = _sign_payload(
        ticket_id=str(ticket.id),
        media_code=ticket.media_code,
        expires_at=expires_at,
    )
    return {
        "ticket_id": str(ticket.id),
        "media_code": ticket.media_code,
        "route_code": ticket.route.code if ticket.route_id else "",
        "expires_at": expires_at,
        "signature": sig,
        "kid": "brt.v1",
    }


def ticket_to_dict(ticket: TransportTicket) -> dict[str, Any]:
    route = ticket.route
    payload = ticket.media_payload or _build_media_payload(ticket)
    return {
        "id": str(ticket.id),
        "media_code": ticket.media_code,
        "ticket_type": ticket.ticket_type,
        "status": ticket.status,
        "fare_minor": ticket.fare_minor,
        "currency": ticket.currency,
        "payment_ref": ticket.payment_ref,
        "valid_from": ticket.valid_from.isoformat(),
        "valid_to": ticket.valid_to.isoformat(),
        "origin_stop": ticket.origin_stop,
        "destination_stop": ticket.destination_stop,
        "route": {
            "id": str(route.id),
            "code": route.code,
            "name": route.name,
            "metadata": route.metadata,
        }
        if route
        else None,
        "qr": payload,
        "validation_count": ticket.validation_count,
        "max_validations": ticket.max_validations,
        "product_code": ticket.product_code,
        "guardian_owner": (ticket.metadata or {}).get("guardian_owner", ""),
        "beneficiary_display_name": (ticket.metadata or {}).get("beneficiary_display_name", ""),
    }


def route_to_dict(route: PublicTransitRoute, *, include_departures: bool = False) -> dict[str, Any]:
    data: dict[str, Any] = {
        "id": str(route.id),
        "code": route.code,
        "name": route.name,
        "region": route.region,
        "district": route.district,
        "operator_principal": route.operator_principal,
        "vehicle_mode": route.vehicle_mode,
        "stops": route.stops,
        "metadata": route.metadata or {},
        "active": route.active,
    }
    if include_departures:
        weekday = timezone.localdate().weekday()
        rows = PublicTransitTimetable.objects.filter(
            route=route, weekday=weekday, active=True
        ).order_by("departure_time")[:12]
        data["departures"] = [
            {
                "weekday": row.weekday,
                "departure_time": row.departure_time.isoformat(),
                "fare_minor": row.fare_minor,
                "currency": row.currency,
                "seats": row.seats,
            }
            for row in rows
        ]
        if rows:
            data["fare_minor"] = rows[0].fare_minor
            data["currency"] = rows[0].currency
    return data


def list_transit_routes(
    *,
    region: str = "",
    mode: str = "",
) -> list[dict[str, Any]]:
    qs = PublicTransitRoute.objects.filter(active=True)
    if region:
        qs = qs.filter(region__icontains=region)
    if mode:
        qs = qs.filter(metadata__mode=mode)
    return [route_to_dict(row) for row in qs.order_by("name")[:100]]


def search_transit(*, query: str, region: str = "") -> dict[str, Any]:
    q = (query or "").strip().lower()
    routes = PublicTransitRoute.objects.filter(active=True)
    if region:
        routes = routes.filter(region__icontains=region)
    matched_routes = []
    matched_stops = []
    for route in routes[:200]:
        if q and q in route.name.lower():
            matched_routes.append(route_to_dict(route))
            continue
        for stop in route.stops or []:
            name = str(stop.get("name", "")).lower()
            code = str(stop.get("code", "")).lower()
            if q and (q in name or q in code):
                matched_stops.append({**stop, "route_id": str(route.id), "route_name": route.name})
                if route.id not in {r["id"] for r in matched_routes}:
                    matched_routes.append(route_to_dict(route))
    return {"query": query, "routes": matched_routes[:20], "stops": matched_stops[:30]}


def nearby_stations(
    *,
    lat: float,
    lng: float,
    limit: int = 8,
    radius_m: float = 5000,
) -> list[dict[str, Any]]:
    profiles = TransitStationProfile.objects.filter(active=True)
    ranked: list[tuple[float, TransitStationProfile]] = []
    for row in profiles:
        dist = _haversine_m(lat, lng, float(row.latitude), float(row.longitude))
        if dist <= radius_m:
            ranked.append((dist, row))
    ranked.sort(key=lambda item: item[0])
    out = []
    for dist, row in ranked[:limit]:
        out.append(
            {
                "stop_code": row.stop_code,
                "name": row.name,
                "region": row.region,
                "latitude": float(row.latitude),
                "longitude": float(row.longitude),
                "distance_meters": int(dist),
                "image_url": row.image_url,
                "facilities": row.facilities,
                "accessibility": row.accessibility,
                "platform": row.platform,
            }
        )
    return out


def station_detail(*, stop_code: str) -> dict[str, Any]:
    profile = TransitStationProfile.objects.get(stop_code=stop_code, active=True)
    upcoming = []
    weekday = timezone.localdate().weekday()
    for route in PublicTransitRoute.objects.filter(active=True, region=profile.region):
        stop_codes = {str(s.get("code", "")) for s in (route.stops or [])}
        if profile.stop_code not in stop_codes:
            continue
        for row in PublicTransitTimetable.objects.filter(
            route=route, weekday=weekday, active=True
        ).order_by("departure_time")[:6]:
            upcoming.append(
                {
                    "route_code": route.code,
                    "route_name": route.name,
                    "departure_time": row.departure_time.isoformat(),
                    "fare_minor": row.fare_minor,
                    "metadata": route.metadata,
                }
            )
    return {
        "stop_code": profile.stop_code,
        "name": profile.name,
        "region": profile.region,
        "latitude": float(profile.latitude),
        "longitude": float(profile.longitude),
        "image_url": profile.image_url,
        "facilities": profile.facilities,
        "accessibility": profile.accessibility,
        "platform": profile.platform,
        "exit_map": profile.exit_map,
        "upcoming": upcoming[:12],
    }


def active_alerts(*, region: str = "") -> list[dict[str, Any]]:
    now = timezone.now()
    qs = TransitAlert.objects.filter(active=True)
    if region:
        qs = qs.filter(region__icontains=region)
    rows = []
    for alert in qs[:20]:
        if alert.starts_at and alert.starts_at > now:
            continue
        if alert.ends_at and alert.ends_at < now:
            continue
        rows.append(
            {
                "id": str(alert.id),
                "severity": alert.severity,
                "title": alert.title,
                "body": alert.body,
                "route_id": str(alert.route_id) if alert.route_id else None,
            }
        )
    return rows


def transit_home_bundle(
    *,
    principal: str,
    lat: float | None = None,
    lng: float | None = None,
    region: str = "Dar es Salaam",
    mode: str = "",
) -> dict[str, Any]:
    stations = []
    if lat is not None and lng is not None:
        stations = nearby_stations(lat=lat, lng=lng, limit=6)
    recent = TransportTicket.objects.filter(owner=principal).order_by("-created_at")[:5]
    if mode:
        routes = list_transit_routes(region=region, mode=mode)[:4]
        products = list_transit_products(mode=mode)
    else:
        routes = list_transit_routes(region=region)[:6]
        products = list_transit_products()
    unread = TransitNotification.objects.filter(owner=principal, read=False).count()
    return {
        "region": region,
        "mode": mode,
        "nearby_stations": stations,
        "featured_routes": routes,
        "alerts": active_alerts(region=region),
        "recent_tickets": [ticket_to_dict(t) for t in recent],
        "products": products,
        "unread_notifications": unread,
        "model_version": "mobility.transit.home.v3",
    }


def transit_modes_catalog(*, region: str = "") -> dict[str, Any]:
    catalog = [
        {"id": "brt", "label": "Mwendokasi BRT", "operator": "DART", "color": "#00A651"},
        {"id": "daladala", "label": "Daladala", "operator": "LATRA", "color": "#F7941D"},
    ]
    modes = []
    for row in catalog:
        qs = PublicTransitRoute.objects.filter(active=True, metadata__mode=row["id"])
        if region:
            qs = qs.filter(region__icontains=region)
        modes.append(
            {
                **row,
                "routes": qs.count(),
                "products": list_transit_products(mode=row["id"])[:3],
            }
        )
    return {"modes": modes, "model_version": "mobility.transit.modes.v1"}


def _audit(*, action: str, actor: str, ticket: TransportTicket | None, payload: dict | None = None) -> None:
    TransitAuditEvent.objects.create(
        action=action,
        actor=actor,
        ticket=ticket,
        payload=payload or {},
    )


@transaction.atomic
def purchase_transit_ticket(
    *,
    owner: str,
    actor: str,
    route_id,
    product_code: str,
    origin_stop: str = "",
    destination_stop: str = "",
    idempotency_key: str,
    beneficiary_owner: str = "",
) -> TransportTicket:
    route = PublicTransitRoute.objects.get(pk=route_id, active=True)
    product = TransitTicketProduct.objects.get(code=product_code, active=True)
    route_mode = (route.metadata or {}).get("mode", "")
    product_mode = (product.metadata or {}).get("mode", "")
    if product_mode and route_mode and product_mode != route_mode:
        raise MobilityError("product not valid for route mode")
    ticket_owner = (beneficiary_owner or owner).strip()
    family_member = None
    if beneficiary_owner and beneficiary_owner != owner:
        family_member = _require_active_family_member(
            guardian_owner=owner,
            member_owner=beneficiary_owner,
        )
    existing = TransportTicket.objects.filter(
        owner=ticket_owner,
        metadata__idempotency_key=idempotency_key,
    ).first()
    if existing:
        return existing

    timetable = (
        PublicTransitTimetable.objects.filter(route=route, active=True)
        .order_by("fare_minor")
        .first()
    )
    amount_minor = product.fare_minor or (timetable.fare_minor if timetable else 0)
    if amount_minor <= 0:
        raise MobilityError("fare not configured for route")
    if family_member and family_member.monthly_limit_minor:
        spent = _family_member_spend_minor(
            guardian_owner=owner,
            member_owner=ticket_owner,
        )
        if spent + amount_minor > family_member.monthly_limit_minor:
            raise MobilityError("family monthly travel limit exceeded")

    merchant = ensure_platform_commerce_merchant(sector="mobility_transit")
    try:
        txn = default_platform().capture_merchant_payment(
            ctx=PlatformContext(actor=actor),
            merchant=merchant,
            payer_owner=owner,
            amount=Money(amount_minor, Currency.from_code(product.currency)),
            idempotency_key=idempotency_key,
            note=f"Transit {product.code} {route.code}",
        )
    except Exception as exc:
        raise CommerceError(str(exc)) from exc

    now = timezone.now()
    mode_prefix = {"brt": "BRT", "daladala": "DALA"}.get(route_mode or "brt", "TRN")
    media_code = _ticket_code(mode_prefix)
    ticket = TransportTicket.objects.create(
        owner=ticket_owner,
        ticket_type=product.ticket_type,
        media_code=media_code,
        route=route,
        fare_minor=amount_minor,
        currency=product.currency,
        payment_ref=str(txn.id),
        valid_from=now,
        valid_to=now + timezone.timedelta(hours=product.validity_hours),
        status="active",
        origin_stop=origin_stop,
        destination_stop=destination_stop,
        product_code=product.code,
        max_validations=product.max_validations,
        token_hash=hashlib.sha256(media_code.encode("utf-8")).hexdigest(),
        metadata={
            "idempotency_key": idempotency_key,
            "route_code": route.code,
            "guardian_owner": owner if family_member else "",
            "purchased_by": actor,
            "beneficiary_display_name": family_member.display_name if family_member else "",
        },
    )
    payload = _build_media_payload(ticket)
    ticket.signature = payload["signature"]
    ticket.media_payload = payload
    ticket.save(update_fields=["signature", "media_payload"])
    _audit(action="ticket.issued", actor=actor, ticket=ticket, payload={"product": product.code})
    _emit_transit_notification(
        owner=ticket_owner,
        event_type="transit.ticket.purchased",
        title="Mwendokasi ticket ready",
        body=f"Your pass for {route.name} is active until {ticket.valid_to.strftime('%H:%M')}.",
        deduplication_key=f"ticket-{ticket.id}-issued",
        payload={"ticket_id": str(ticket.id), "media_code": ticket.media_code},
    )
    if family_member:
        _emit_transit_notification(
            owner=owner,
            event_type="transit.family.ticket_purchased",
            title="Family ticket purchased",
            body=f"You bought a pass for {family_member.display_name} on {route.name}.",
            deduplication_key=f"family-ticket-{ticket.id}-guardian",
            payload={
                "ticket_id": str(ticket.id),
                "member_owner": ticket_owner,
                "display_name": family_member.display_name,
            },
        )
    return ticket


@transaction.atomic
def validate_transit_ticket(
    *,
    media_code: str,
    actor: str,
    qr_payload: dict | None = None,
    media_type: str = "qr",
) -> TransportTicket:
    ticket = TransportTicket.objects.select_for_update().get(media_code=media_code)
    now = timezone.now()
    if ticket.status != "active":
        raise MobilityError("ticket is not active")
    if not (ticket.valid_from <= now <= ticket.valid_to):
        ticket.status = "expired"
        ticket.save(update_fields=["status"])
        raise MobilityError("ticket expired")
    if ticket.validation_count >= ticket.max_validations:
        ticket.status = "used"
        ticket.save(update_fields=["status"])
        raise MobilityError("ticket already used")

    normalized_media = (media_type or "qr").strip().lower()
    if normalized_media == "nfc":
        token = str((qr_payload or {}).get("nfc_token") or media_code)
        if ticket.token_hash and ticket.token_hash != hashlib.sha256(token.encode()).hexdigest():
            raise MobilityError("invalid nfc token")
    else:
        payload = qr_payload or ticket.media_payload or {}
        expires_at = int(payload.get("expires_at") or ticket.valid_to.timestamp())
        expected_sig = _sign_payload(
            ticket_id=str(ticket.id),
            media_code=ticket.media_code,
            expires_at=expires_at,
        )
        if payload.get("signature") and payload.get("signature") != expected_sig:
            raise MobilityError("invalid ticket signature")

    ticket.validation_count += 1
    if ticket.validation_count >= ticket.max_validations:
        ticket.status = "used"
    ticket.save(update_fields=["validation_count", "status"])
    _audit(
        action="ticket.validated",
        actor=actor,
        ticket=ticket,
        payload={"count": ticket.validation_count, "media_type": normalized_media},
    )
    _emit_transit_notification(
        owner=ticket.owner,
        event_type="transit.ticket.validated",
        title="Boarding confirmed",
        body=f"Your ticket {ticket.media_code} was scanned successfully.",
        deduplication_key=f"ticket-{ticket.id}-validated-{ticket.validation_count}",
        payload={"ticket_id": str(ticket.id), "status": ticket.status},
    )
    return ticket


def list_my_tickets(*, owner: str, limit: int = 20) -> list[dict[str, Any]]:
    rows = TransportTicket.objects.filter(owner=owner).select_related("route").order_by("-created_at")[:limit]
    return [ticket_to_dict(row) for row in rows]


def product_to_dict(product: TransitTicketProduct) -> dict[str, Any]:
    return {
        "code": product.code,
        "name": product.name,
        "description": product.description,
        "ticket_type": product.ticket_type,
        "fare_minor": product.fare_minor,
        "currency": product.currency,
        "validity_hours": product.validity_hours,
        "max_validations": product.max_validations,
        "metadata": product.metadata or {},
    }


def list_transit_products(*, mode: str = "") -> list[dict[str, Any]]:
    qs = TransitTicketProduct.objects.filter(active=True)
    if mode:
        qs = qs.filter(metadata__mode=mode)
    return [product_to_dict(row) for row in qs.order_by("fare_minor")]


def _stop_index(stops: list[dict], code: str) -> int | None:
    code = code.lower()
    for idx, stop in enumerate(stops):
        if str(stop.get("code", "")).lower() == code:
            return idx
    return None


def _route_fare(route: PublicTransitRoute) -> tuple[int, str]:
    weekday = timezone.localdate().weekday()
    row = (
        PublicTransitTimetable.objects.filter(route=route, weekday=weekday, active=True)
        .order_by("fare_minor")
        .first()
    )
    if row:
        return row.fare_minor, row.currency
    return 0, "TZS"


def _multimodal_plans(
    *,
    origin: str,
    destination: str,
    routes,
) -> list[dict[str, Any]]:
    """Build transfer plans via shared stops (e.g. daladala + BRT at Posta/Kariakoo)."""
    route_list = list(routes)
    transfer_stops: set[str] = set()
    for route in route_list:
        for stop in route.stops or []:
            code = str(stop.get("code", "")).lower()
            if code:
                transfer_stops.add(code)
    transfer_stops.discard(origin)
    transfer_stops.discard(destination)

    plans: list[dict[str, Any]] = []
    for transfer in transfer_stops:
        leg1_options: list[tuple[PublicTransitRoute, int, int]] = []
        leg2_options: list[tuple[PublicTransitRoute, int, int]] = []
        for route in route_list:
            stops = route.stops or []
            o_idx = _stop_index(stops, origin)
            t_idx = _stop_index(stops, transfer)
            d_idx = _stop_index(stops, destination)
            if o_idx is not None and t_idx is not None and o_idx < t_idx:
                leg1_options.append((route, o_idx, t_idx))
            if t_idx is not None and d_idx is not None and t_idx < d_idx:
                leg2_options.append((route, t_idx, d_idx))
        for r1, o_idx, t_idx in leg1_options:
            for r2, _, d_idx in leg2_options:
                if r1.id == r2.id:
                    continue
                fare1, cur1 = _route_fare(r1)
                fare2, cur2 = _route_fare(r2)
                currency = cur1 or cur2 or "TZS"
                mode1 = (r1.metadata or {}).get("mode", r1.vehicle_mode)
                mode2 = (r2.metadata or {}).get("mode", r2.vehicle_mode)
                plans.append(
                    {
                        "kind": "transfer",
                        "route_id": str(r1.id),
                        "route_code": r1.code,
                        "route_name": f"{r1.name} → {r2.name}",
                        "mode": f"{mode1}+{mode2}",
                        "brand": "Multi-modal",
                        "origin_stop": origin,
                        "destination_stop": destination,
                        "transfer_stop": transfer,
                        "stops_count": (t_idx - o_idx) + (d_idx - t_idx) + 1,
                        "fare_minor": fare1 + fare2,
                        "currency": currency,
                        "duration_minutes": max(10, (t_idx - o_idx + d_idx - t_idx) * 8 + 5),
                        "legs": [
                            {
                                "route_id": str(r1.id),
                                "route_code": r1.code,
                                "route_name": r1.name,
                                "origin_stop": origin,
                                "destination_stop": transfer,
                                "mode": mode1,
                            },
                            {
                                "route_id": str(r2.id),
                                "route_code": r2.code,
                                "route_name": r2.name,
                                "origin_stop": transfer,
                                "destination_stop": destination,
                                "mode": mode2,
                            },
                        ],
                    }
                )
    return plans


def plan_transit_journey(
    *,
    origin_stop: str,
    destination_stop: str,
    region: str = "",
) -> dict[str, Any]:
    origin = origin_stop.strip().lower()
    destination = destination_stop.strip().lower()
    if not origin or not destination:
        raise MobilityError("origin_stop and destination_stop required")
    if origin == destination:
        raise MobilityError("origin and destination must differ")

    routes = PublicTransitRoute.objects.filter(active=True)
    if region:
        routes = routes.filter(region__icontains=region)

    plans: list[dict[str, Any]] = []
    for route in routes:
        stops = route.stops or []
        o_idx = _stop_index(stops, origin)
        d_idx = _stop_index(stops, destination)
        if o_idx is None or d_idx is None or o_idx >= d_idx:
            continue
        fare_minor, currency = _route_fare(route)
        segment_stops = stops[o_idx : d_idx + 1]
        plans.append(
            {
                "kind": "direct",
                "route_id": str(route.id),
                "route_code": route.code,
                "route_name": route.name,
                "mode": (route.metadata or {}).get("mode", route.vehicle_mode),
                "brand": (route.metadata or {}).get("brand", ""),
                "origin_stop": origin,
                "destination_stop": destination,
                "stops_count": len(segment_stops),
                "fare_minor": fare_minor,
                "currency": currency,
                "duration_minutes": max(5, (d_idx - o_idx) * 8),
                "legs": [
                    {
                        "route_id": str(route.id),
                        "route_code": route.code,
                        "route_name": route.name,
                        "origin_stop": origin,
                        "destination_stop": destination,
                        "mode": (route.metadata or {}).get("mode", route.vehicle_mode),
                    }
                ],
            }
        )

    transfer_plans = _multimodal_plans(origin=origin, destination=destination, routes=routes)
    seen_transfer: set[tuple[str, str, str]] = set()
    for plan in transfer_plans:
        legs = plan.get("legs") or []
        if len(legs) < 2:
            continue
        key = (
            str(plan.get("transfer_stop") or ""),
            str(legs[0].get("route_id") or ""),
            str(legs[1].get("route_id") or ""),
        )
        if key in seen_transfer:
            continue
        seen_transfer.add(key)
        plans.append(plan)

    plans.sort(key=lambda p: (p["fare_minor"], p["duration_minutes"]))
    return {
        "origin_stop": origin,
        "destination_stop": destination,
        "region": region,
        "plans": plans[:10],
        "model_version": "mobility.transit.plan.v2",
    }


def scheduled_run_to_dict(run: TransitScheduledRun) -> dict[str, Any]:
    route = run.route
    return {
        "id": str(run.id),
        "route_id": str(route.id),
        "route_code": route.code,
        "route_name": route.name,
        "driver_owner": run.driver_owner,
        "vehicle_label": run.vehicle_label,
        "scheduled_at": run.scheduled_at.isoformat(),
        "origin_stop": run.origin_stop,
        "destination_stop": run.destination_stop,
        "status": run.status,
        "metadata": run.metadata or {},
        "brand": (route.metadata or {}).get("brand", ""),
    }


def list_driver_runs(*, driver_owner: str, limit: int = 20) -> list[dict[str, Any]]:
    now = timezone.now()
    qs = (
        TransitScheduledRun.objects.filter(driver_owner=driver_owner)
        .exclude(status=TransitScheduledRun.Status.CANCELLED)
        .select_related("route")
        .order_by("scheduled_at")
    )
    rows = [row for row in qs if row.scheduled_at >= now - timezone.timedelta(hours=2)][:limit]
    return [scheduled_run_to_dict(row) for row in rows]


@transaction.atomic
def advance_driver_run(*, run_id, driver_owner: str, status: str, actor: str) -> TransitScheduledRun:
    run = TransitScheduledRun.objects.select_for_update().select_related("route").get(pk=run_id)
    if run.driver_owner != driver_owner:
        raise MobilityError("run not assigned to driver")
    allowed: dict[str, set[str]] = {
        TransitScheduledRun.Status.SCHEDULED: {TransitScheduledRun.Status.BOARDING},
        TransitScheduledRun.Status.BOARDING: {TransitScheduledRun.Status.DEPARTED},
        TransitScheduledRun.Status.DEPARTED: {TransitScheduledRun.Status.COMPLETED},
    }
    next_status = status.lower()
    current = run.status
    if next_status not in {s.value for s in TransitScheduledRun.Status}:
        raise MobilityError("invalid status")
    permitted = allowed.get(current, set())
    if next_status not in permitted:
        raise MobilityError(f"cannot transition from {current} to {next_status}")
    run.status = next_status
    run.save(update_fields=["status", "updated_at"])
    _audit(action=f"run.{next_status}", actor=actor, ticket=None, payload={"run_id": str(run.id)})
    return run


def _route_polyline(route: PublicTransitRoute) -> list[dict[str, Any]]:
    return [
        {
            "code": str(stop.get("code", "")),
            "name": str(stop.get("name", "")),
            "lat": float(stop.get("lat", 0)),
            "lng": float(stop.get("lng", 0)),
            "sequence": int(stop.get("sequence", idx + 1)),
        }
        for idx, stop in enumerate(route.stops or [])
    ]


def _progress_e4_for_position(route: PublicTransitRoute, lat: float, lng: float) -> int:
    stops = route.stops or []
    if len(stops) < 2:
        return 0
    best_idx = 0
    best_dist = float("inf")
    for idx, stop in enumerate(stops):
        dist = _haversine_m(lat, lng, float(stop.get("lat", 0)), float(stop.get("lng", 0)))
        if dist < best_dist:
            best_dist = dist
            best_idx = idx
    return int((best_idx / max(len(stops) - 1, 1)) * 10_000)


def _nearest_next_stop(route: PublicTransitRoute, progress_e4: int) -> str:
    stops = route.stops or []
    if not stops:
        return ""
    idx = min(len(stops) - 1, max(0, int((progress_e4 / 10_000) * (len(stops) - 1)) + 1))
    return str(stops[idx].get("code", ""))


def avl_vehicle_to_dict(vehicle: TransitAvlVehicle) -> dict[str, Any]:
    route = vehicle.route
    return {
        "id": str(vehicle.id),
        "vehicle_label": vehicle.vehicle_label,
        "route_id": str(route.id),
        "route_code": route.code,
        "route_name": route.name,
        "latitude": float(vehicle.latitude),
        "longitude": float(vehicle.longitude),
        "heading": vehicle.heading,
        "speed_kmh": vehicle.speed_kmh,
        "progress_e4": vehicle.progress_e4,
        "next_stop_code": vehicle.next_stop_code,
        "eta_next_stop_seconds": vehicle.eta_next_stop_seconds,
        "status": vehicle.status,
        "recorded_at": vehicle.recorded_at.isoformat(),
        "brand": (route.metadata or {}).get("brand", ""),
    }


def live_transit_map(*, region: str = "", route_id: str = "") -> dict[str, Any]:
    routes_qs = PublicTransitRoute.objects.filter(active=True)
    if region:
        routes_qs = routes_qs.filter(region__icontains=region)
    if route_id:
        routes_qs = routes_qs.filter(pk=route_id)

    routes_payload = []
    route_ids: list = []
    for route in routes_qs:
        route_ids.append(route.id)
        routes_payload.append(
            {
                "id": str(route.id),
                "code": route.code,
                "name": route.name,
                "metadata": route.metadata or {},
                "polyline": _route_polyline(route),
            }
        )

    vehicles_qs = TransitAvlVehicle.objects.filter(active=True, route_id__in=route_ids).select_related(
        "route"
    )
    stations_qs = TransitStationProfile.objects.filter(active=True)
    if region:
        stations_qs = stations_qs.filter(region__icontains=region)

    return {
        "region": region or "Dar es Salaam",
        "routes": routes_payload,
        "stations": [
            {
                "stop_code": row.stop_code,
                "name": row.name,
                "latitude": float(row.latitude),
                "longitude": float(row.longitude),
                "platform": row.platform,
            }
            for row in stations_qs[:50]
        ],
        "vehicles": [avl_vehicle_to_dict(row) for row in vehicles_qs],
        "model_version": "mobility.transit.map.v1",
    }


@transaction.atomic
def upsert_avl_ping(
    *,
    actor: str,
    vehicle_label: str,
    route_id,
    latitude: float,
    longitude: float,
    heading: int = 0,
    speed_kmh: int = 0,
    next_stop_code: str = "",
    eta_next_stop_seconds: int = 0,
    status: str = TransitAvlVehicle.Status.IN_SERVICE,
) -> TransitAvlVehicle:
    route = PublicTransitRoute.objects.get(pk=route_id, active=True)
    progress = _progress_e4_for_position(route, latitude, longitude)
    stop_code = next_stop_code or _nearest_next_stop(route, progress)
    run = (
        TransitScheduledRun.objects.filter(
            driver_owner=actor,
            vehicle_label=vehicle_label,
            route=route,
        )
        .exclude(status=TransitScheduledRun.Status.CANCELLED)
        .order_by("-scheduled_at")
        .first()
    )
    vehicle, _ = TransitAvlVehicle.objects.update_or_create(
        vehicle_label=vehicle_label,
        defaults={
            "route": route,
            "scheduled_run": run,
            "latitude": latitude,
            "longitude": longitude,
            "heading": heading,
            "speed_kmh": speed_kmh,
            "progress_e4": progress,
            "next_stop_code": stop_code,
            "eta_next_stop_seconds": eta_next_stop_seconds,
            "status": status,
            "active": True,
        },
    )
    payload = avl_vehicle_to_dict(vehicle)
    broadcast_transit_avl(
        region=route.region,
        route_id=str(route.id),
        event_type="transit.avl.update",
        payload=payload,
    )
    _audit(action="avl.ping", actor=actor, ticket=None, payload={"vehicle": vehicle_label})
    return vehicle


def _emit_transit_notification(
    *,
    owner: str,
    event_type: str,
    title: str,
    body: str,
    deduplication_key: str,
    payload: dict | None = None,
) -> TransitNotification | None:
    notification, created = TransitNotification.objects.get_or_create(
        deduplication_key=deduplication_key[:160],
        defaults={
            "owner": owner,
            "event_type": event_type,
            "title": title,
            "body": body,
            "payload": payload or {},
        },
    )
    if created:
        pushed = _deliver_transit_push(
            owner=owner,
            title=title,
            body=body,
            payload={"event_type": event_type, **(payload or {})},
        )
        if pushed:
            merged = dict(notification.payload or {})
            merged["push_delivered"] = True
            notification.payload = merged
            notification.save(update_fields=["payload"])
    return notification if created else None


def _deliver_transit_push(*, owner: str, title: str, body: str, payload: dict | None = None) -> bool:
    try:
        from integrations.notifications import NotificationNotConfigured, deliver_notification
        from payments.models import Device
    except ImportError:
        return False
    device = (
        Device.objects.filter(owner=owner)
        .exclude(push_token="")
        .order_by("-last_seen_at")
        .first()
    )
    if device is None or not device.push_token:
        return False
    try:
        result = deliver_notification(
            channel="push",
            to=device.push_token,
            subject=title,
            body=body,
            metadata=payload or {},
        )
        return result.accepted
    except NotificationNotConfigured:
        return False


def _sentiment_from_rating(rating: int) -> str:
    if rating >= 4:
        return "positive"
    if rating == 3:
        return "neutral"
    return "negative"


def passenger_profile_bundle(*, owner: str) -> dict[str, Any]:
    profile, _ = TransitPassengerProfile.objects.get_or_create(owner=owner)
    tickets = TransportTicket.objects.filter(owner=owner)
    completed = tickets.filter(status__in=["used", "active"]).count()
    favorites = TransitFavorite.objects.filter(owner=owner).order_by("-created_at")[:20]
    return {
        "profile": {
            "owner": profile.owner,
            "home_stop": profile.home_stop,
            "work_stop": profile.work_stop,
            "preferred_language": profile.preferred_language,
            "accessibility": profile.accessibility or {},
        },
        "stats": {
            "total_tickets": tickets.count(),
            "active_tickets": tickets.filter(status="active").count(),
            "completed_trips": completed,
            "favorite_count": favorites.count(),
        },
        "favorites": [
            {
                "id": str(f.id),
                "subject_type": f.subject_type,
                "subject_code": f.subject_code,
                "label": f.label,
            }
            for f in favorites
        ],
        "model_version": "mobility.transit.profile.v1",
    }


@transaction.atomic
def update_passenger_profile(*, owner: str, data: dict[str, Any]) -> TransitPassengerProfile:
    profile, _ = TransitPassengerProfile.objects.get_or_create(owner=owner)
    for field in ("home_stop", "work_stop", "preferred_language"):
        if field in data:
            setattr(profile, field, str(data[field] or ""))
    if "accessibility" in data and isinstance(data["accessibility"], dict):
        profile.accessibility = data["accessibility"]
    profile.save()
    return profile


def list_transit_favorites(*, owner: str) -> list[dict[str, Any]]:
    return [
        {
            "id": str(row.id),
            "subject_type": row.subject_type,
            "subject_code": row.subject_code,
            "label": row.label,
        }
        for row in TransitFavorite.objects.filter(owner=owner).order_by("-created_at")
    ]


@transaction.atomic
def add_transit_favorite(
    *,
    owner: str,
    subject_type: str,
    subject_code: str,
    label: str = "",
) -> TransitFavorite:
    if subject_type not in {TransitFavorite.SubjectType.STATION, TransitFavorite.SubjectType.ROUTE}:
        raise MobilityError("invalid favorite subject_type")
    fav, _ = TransitFavorite.objects.update_or_create(
        owner=owner,
        subject_type=subject_type,
        subject_code=subject_code.strip().lower(),
        defaults={"label": label},
    )
    return fav


def remove_transit_favorite(*, owner: str, favorite_id) -> None:
    TransitFavorite.objects.filter(pk=favorite_id, owner=owner).delete()


def list_transit_notifications(*, owner: str, limit: int = 30) -> list[dict[str, Any]]:
    rows = TransitNotification.objects.filter(owner=owner).order_by("-created_at")[:limit]
    return [
        {
            "id": str(row.id),
            "event_type": row.event_type,
            "title": row.title,
            "body": row.body,
            "payload": row.payload or {},
            "read": row.read,
            "created_at": row.created_at.isoformat(),
        }
        for row in rows
    ]


def mark_transit_notifications_read(*, owner: str, notification_ids: list | None = None) -> int:
    qs = TransitNotification.objects.filter(owner=owner, read=False)
    if notification_ids:
        qs = qs.filter(pk__in=notification_ids)
    return qs.update(read=True)


@transaction.atomic
def submit_transit_feedback(
    *,
    owner: str,
    rating: int,
    comment: str = "",
    tags: list | None = None,
    route_id=None,
    ticket_id=None,
) -> TransitFeedback:
    if rating < 1 or rating > 5:
        raise MobilityError("rating must be 1-5")
    route = None
    ticket = None
    if route_id:
        route = PublicTransitRoute.objects.filter(pk=route_id).first()
    if ticket_id:
        ticket = TransportTicket.objects.filter(pk=ticket_id, owner=owner).first()
    feedback = TransitFeedback.objects.create(
        owner=owner,
        route=route,
        ticket=ticket,
        rating=rating,
        comment=comment,
        tags=tags or [],
        sentiment=_sentiment_from_rating(rating),
    )
    return feedback


def list_transit_feedback(*, owner: str, limit: int = 20) -> list[dict[str, Any]]:
    rows = TransitFeedback.objects.filter(owner=owner).select_related("route").order_by("-created_at")[:limit]
    return [
        {
            "id": str(row.id),
            "rating": row.rating,
            "comment": row.comment,
            "tags": row.tags,
            "sentiment": row.sentiment,
            "route_code": row.route.code if row.route else "",
            "created_at": row.created_at.isoformat(),
        }
        for row in rows
    ]


@transaction.atomic
def report_transit_sos(
    *,
    owner: str,
    latitude: float | None = None,
    longitude: float | None = None,
    stop_code: str = "",
    route_id=None,
    vehicle_label: str = "",
    notes: str = "",
) -> dict[str, Any]:
    from .models import SafetyIncident

    route = PublicTransitRoute.objects.filter(pk=route_id).first() if route_id else None
    incident = SafetyIncident.objects.create(
        reporter_principal=owner,
        kind="sos",
        severity="critical",
        latitude=latitude,
        longitude=longitude,
        details={
            "context": "transit",
            "stop_code": stop_code,
            "route_id": str(route.id) if route else "",
            "route_code": route.code if route else "",
            "vehicle_label": vehicle_label,
            "notes": notes,
        },
    )
    _emit_transit_notification(
        owner=owner,
        event_type="transit.safety.sos",
        title="SOS sent to DART security",
        body="Your location was shared with transit safety operators.",
        deduplication_key=f"sos-{incident.id}",
        payload={"incident_id": str(incident.id), "stop_code": stop_code},
    )
    return {
        "incident_id": str(incident.id),
        "status": incident.status,
        "kind": incident.kind,
        "created_at": incident.created_at.isoformat(),
    }


def transit_ops_snapshot(*, region: str = "") -> dict[str, Any]:
    """Live BRT KPIs for city/national control centers."""
    today = timezone.localdate()
    routes_qs = PublicTransitRoute.objects.filter(active=True)
    tickets_qs = TransportTicket.objects.filter(created_at__date=today)
    validated_qs = TransitAuditEvent.objects.filter(
        action="ticket.validated",
        created_at__date=today,
    )
    avl_qs = TransitAvlVehicle.objects.filter(active=True, status=TransitAvlVehicle.Status.IN_SERVICE)
    alerts_qs = TransitAlert.objects.filter(active=True)
    if region:
        routes_qs = routes_qs.filter(region__iexact=region)
        tickets_qs = tickets_qs.filter(route__region__iexact=region)
        validated_qs = validated_qs.filter(ticket__route__region__iexact=region)
        avl_qs = avl_qs.filter(route__region__iexact=region)
        alerts_qs = alerts_qs.filter(region__iexact=region)
    nfc_validations = validated_qs.filter(payload__media_type="nfc").count()
    qr_validations = validated_qs.exclude(payload__media_type="nfc").count()
    return {
        "region": region or "national",
        "tickets_issued_today": tickets_qs.count(),
        "validations_today": validated_qs.count(),
        "nfc_validations_today": nfc_validations,
        "qr_validations_today": qr_validations,
        "fare_today_minor": tickets_qs.aggregate(total=Sum("fare_minor"))["total"] or 0,
        "active_routes": routes_qs.count(),
        "avl_vehicles_in_service": avl_qs.count(),
        "active_alerts": alerts_qs.count(),
        "lost_found_open": TransitLostFoundItem.objects.filter(
            status=TransitLostFoundItem.Status.OPEN,
        ).count(),
        "lost_found_claimed": TransitLostFoundItem.objects.filter(
            status=TransitLostFoundItem.Status.CLAIMED,
        ).count(),
        "model_version": "mobility.transit.ops.v1",
    }


def build_transit_daily_metrics(*, region: str, day=None) -> list[TransitDailyMetric]:
    """Materialize corridor metrics for a single day."""
    from datetime import date as date_cls

    metric_day = day or timezone.localdate()
    if isinstance(metric_day, str):
        metric_day = date_cls.fromisoformat(metric_day)

    rows: dict[tuple[str, str], dict[str, int]] = {}
    tickets = (
        TransportTicket.objects.filter(created_at__date=metric_day, route__region__iexact=region)
        .select_related("route")
        .order_by("created_at")
    )
    for ticket in tickets:
        route_code = ticket.route.code if ticket.route else ""
        product_code = ticket.product_code or ""
        key = (route_code, product_code)
        bucket = rows.setdefault(
            key,
            {
                "tickets_issued": 0,
                "tickets_validated": 0,
                "nfc_validations": 0,
                "qr_validations": 0,
                "fare_minor": 0,
            },
        )
        bucket["tickets_issued"] += 1
        bucket["fare_minor"] += int(ticket.fare_minor or 0)
        if ticket.validation_count:
            bucket["tickets_validated"] += ticket.validation_count

    validations = TransitAuditEvent.objects.filter(
        action="ticket.validated",
        created_at__date=metric_day,
        ticket__route__region__iexact=region,
    ).select_related("ticket", "ticket__route")
    for event in validations:
        route_code = event.ticket.route.code if event.ticket and event.ticket.route else ""
        product_code = event.ticket.product_code if event.ticket else ""
        key = (route_code, product_code)
        bucket = rows.setdefault(
            key,
            {
                "tickets_issued": 0,
                "tickets_validated": 0,
                "nfc_validations": 0,
                "qr_validations": 0,
                "fare_minor": 0,
            },
        )
        if (event.payload or {}).get("media_type") == "nfc":
            bucket["nfc_validations"] += 1
        else:
            bucket["qr_validations"] += 1

    saved: list[TransitDailyMetric] = []
    for (route_code, product_code), bucket in rows.items():
        metric, _ = TransitDailyMetric.objects.update_or_create(
            date=metric_day,
            region=region,
            route_code=route_code,
            product_code=product_code,
            defaults={
                "tickets_issued": bucket["tickets_issued"],
                "tickets_validated": bucket["tickets_validated"],
                "nfc_validations": bucket["nfc_validations"],
                "qr_validations": bucket["qr_validations"],
                "fare_minor": bucket["fare_minor"],
            },
        )
        saved.append(metric)
    return saved


def transit_analytics_bundle(*, region: str = "Dar es Salaam", days: int = 7) -> dict[str, Any]:
    from datetime import timedelta

    days = max(1, min(days, 30))
    end = timezone.localdate()
    start = end - timedelta(days=days - 1)
    build_transit_daily_metrics(region=region, day=end)
    metrics = TransitDailyMetric.objects.filter(
        region__iexact=region,
        date__gte=start,
        date__lte=end,
    ).order_by("date", "route_code")
    daily: dict[str, dict[str, int]] = {}
    by_route: dict[str, dict[str, int]] = {}
    for row in metrics:
        day_key = row.date.isoformat()
        day_bucket = daily.setdefault(
            day_key,
            {
                "tickets_issued": 0,
                "tickets_validated": 0,
                "nfc_validations": 0,
                "qr_validations": 0,
                "fare_minor": 0,
            },
        )
        for field in day_bucket:
            day_bucket[field] += getattr(row, field)
        if row.route_code:
            route_bucket = by_route.setdefault(
                row.route_code,
                {
                    "tickets_issued": 0,
                    "tickets_validated": 0,
                    "fare_minor": 0,
                },
            )
            route_bucket["tickets_issued"] += row.tickets_issued
            route_bucket["tickets_validated"] += row.tickets_validated
            route_bucket["fare_minor"] += row.fare_minor

    return {
        "region": region,
        "days": days,
        "daily": [
            {"date": day, **values}
            for day, values in sorted(daily.items())
        ],
        "by_route": [
            {"route_code": code, **values}
            for code, values in sorted(by_route.items())
        ],
        "ops": transit_ops_snapshot(region=region),
        "model_version": "mobility.transit.analytics.v1",
    }


@transaction.atomic
def admin_upsert_route(
    *,
    actor: str,
    route_id=None,
    data: dict[str, Any],
) -> PublicTransitRoute:
    if route_id:
        route = PublicTransitRoute.objects.get(pk=route_id)
        for field in ("name", "region", "district", "active"):
            if field in data:
                setattr(route, field, data[field])
        if "stops" in data and isinstance(data["stops"], list):
            route.stops = data["stops"]
        if "metadata" in data and isinstance(data["metadata"], dict):
            route.metadata = data["metadata"]
        route.save()
    else:
        code = str(data.get("code") or "").strip()
        name = str(data.get("name") or "").strip()
        if not code or not name:
            raise MobilityError("code and name required")
        route = PublicTransitRoute.objects.create(
            code=code,
            name=name,
            region=str(data.get("region") or "Dar es Salaam"),
            district=str(data.get("district") or ""),
            operator_principal=str(data.get("operator_principal") or actor),
            vehicle_mode=str(data.get("vehicle_mode") or "bus"),
            stops=data.get("stops") or [],
            metadata=data.get("metadata") or {},
            active=bool(data.get("active", True)),
        )
    _audit(action="admin.route.upsert", actor=actor, ticket=None, payload={"route_id": str(route.id), "code": route.code})
    return route


@transaction.atomic
def admin_upsert_product(
    *,
    actor: str,
    product_id=None,
    data: dict[str, Any],
) -> TransitTicketProduct:
    if product_id:
        product = TransitTicketProduct.objects.get(pk=product_id)
        for field in (
            "name",
            "description",
            "ticket_type",
            "fare_minor",
            "currency",
            "validity_hours",
            "max_validations",
            "active",
        ):
            if field in data:
                setattr(product, field, data[field])
        if "metadata" in data and isinstance(data["metadata"], dict):
            product.metadata = data["metadata"]
        product.save()
    else:
        code = str(data.get("code") or "").strip()
        name = str(data.get("name") or "").strip()
        if not code or not name:
            raise MobilityError("code and name required")
        product = TransitTicketProduct.objects.create(
            code=code,
            name=name,
            description=str(data.get("description") or ""),
            ticket_type=str(data.get("ticket_type") or "single"),
            fare_minor=int(data.get("fare_minor") or 0),
            currency=str(data.get("currency") or "TZS"),
            validity_hours=int(data.get("validity_hours") or 2),
            max_validations=int(data.get("max_validations") or 1),
            metadata=data.get("metadata") or {},
            active=bool(data.get("active", True)),
        )
    _audit(action="admin.product.upsert", actor=actor, ticket=None, payload={"product_code": product.code})
    return product


_KNOWN_STOP_ALIASES: dict[str, str] = {
    "kimara": "kimara",
    "kimara terminal": "kimara",
    "ubungo": "ubungo",
    "ubungo brt": "ubungo",
    "morocco": "morocco",
    "kariakoo": "kariakoo",
    "posta": "posta",
    "kivukoni": "kivukoni",
    "feri": "kivukoni",
    "ferry": "kivukoni",
}

_COMMUTE_ALIASES = {
    "kazini": "work",
    "work": "work",
    "office": "work",
    "ofisi": "work",
    "nyumbani": "home",
    "home": "home",
}


def _detect_locale(text: str) -> str:
    lower = text.lower()
    sw_markers = (
        "kutoka",
        "hadi",
        "kwenda",
        "bei",
        "basi",
        "stesheni",
        "safari",
        "karibu",
        "nataka",
        "naomba",
        "bei gani",
    )
    if any(marker in lower for marker in sw_markers):
        return "sw"
    return "en"


def _normalize_stop_token(token: str) -> str:
    cleaned = re.sub(r"[^\w\s-]", "", (token or "").strip().lower())
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    if cleaned in _KNOWN_STOP_ALIASES:
        return _KNOWN_STOP_ALIASES[cleaned]
    for alias, code in _KNOWN_STOP_ALIASES.items():
        if alias in cleaned or cleaned in alias:
            return code
    return cleaned.replace(" ", "-")


def _extract_journey_stops(query: str) -> tuple[str, str]:
    q = (query or "").strip()
    if not q:
        return "", ""
    patterns = [
        r"(?:nataka|naomba)\s+kwenda\s+(.+?)(?:\s+kutoka\s+(.+))?$",
        r"(?:from|kutoka)\s+(.+?)\s+(?:to|hadi|kwenda)\s+(.+)",
        r"^(.+?)\s+(?:to|hadi)\s+(.+)$",
    ]
    for pattern in patterns:
        match = re.search(pattern, q, flags=re.I)
        if not match:
            continue
        groups = [g.strip() for g in match.groups() if g]
        if len(groups) == 1 and "(?:nataka" in pattern:
            return "", _normalize_stop_token(groups[0])
        if len(groups) == 2:
            if "(?:nataka" in pattern:
                return _normalize_stop_token(groups[1]), _normalize_stop_token(groups[0])
            return _normalize_stop_token(groups[0]), _normalize_stop_token(groups[1])
    found: list[str] = []
    lower = q.lower()
    for alias, code in sorted(_KNOWN_STOP_ALIASES.items(), key=lambda item: -len(item[0])):
        if alias in lower and code not in found:
            found.append(code)
    if len(found) >= 2:
        return found[0], found[1]
    if len(found) == 1:
        return found[0], ""
    return "", ""


def _search_query_from_text(text: str) -> str:
    lower = text.lower()
    for alias in sorted(_KNOWN_STOP_ALIASES.keys(), key=len, reverse=True):
        if alias in lower:
            return alias
    return text


def _sanitize_stop_token(token: str) -> str:
    if not token:
        return ""
    if token in _COMMUTE_ALIASES:
        return token
    if token in _KNOWN_STOP_ALIASES.values():
        return token
    normalized = _normalize_stop_token(token)
    if normalized in _KNOWN_STOP_ALIASES.values():
        return normalized
    return ""


def _rank_plans_with_ai(
    *,
    plans: list[dict[str, Any]],
    principal: str,
    locale: str,
) -> list[dict[str, Any]]:
    if len(plans) <= 1:
        return plans
    try:
        from ecosystem.ai import invoke_ai

        result = invoke_ai(
            capability_code="route_optimization",
            principal=principal,
            payload={
                "objective": "minimize_time_and_cost",
                "candidates": plans,
                "locale": locale,
            },
            domain_code="mobility_transit",
        )
        ranked = result.get("suggestion") or (result.get("result") or {}).get("suggestion")
        if isinstance(ranked, list) and ranked:
            return ranked
    except Exception:
        pass
    return sorted(plans, key=lambda row: (row.get("duration_minutes", 999), row.get("fare_minor", 0)))


def _assistant_reply(
    *,
    principal: str,
    query: str,
    locale: str,
    context: dict[str, Any],
) -> dict[str, Any]:
    locale_tag = "sw-TZ" if locale == "sw" else "en-TZ"
    try:
        from ecosystem.ai import invoke_ai

        return invoke_ai(
            capability_code="voice_assistant",
            principal=principal,
            payload={
                "task": "transit_travel_assistant",
                "text": query,
                "locale": locale_tag,
                "context": context,
            },
            domain_code="mobility_transit",
        )
    except Exception:
        if locale == "sw":
            return {
                "reply": "Ninaweza kukusaidia kupanga safari ya Mwendokasi, kutafuta stesheni, na kuona bei.",
                "model_version": "mobility.transit.assistant.stub-v1",
                "confidence_e4": 5000,
            }
        return {
            "reply": "I can help you plan Mwendokasi BRT trips, find stations, and check fares.",
            "model_version": "mobility.transit.assistant.stub-v1",
            "confidence_e4": 5000,
        }


def transit_ai_assistant(
    *,
    owner: str,
    query: str,
    locale: str = "",
    region: str = "Dar es Salaam",
    origin_stop: str = "",
    destination_stop: str = "",
) -> dict[str, Any]:
    """Bilingual NL travel assistant — rules + Taifa AI OS advisory layer."""
    text = (query or "").strip()
    if not text:
        raise MobilityError("query required")

    resolved_locale = (locale or _detect_locale(text)).lower()
    if resolved_locale not in {"sw", "en"}:
        resolved_locale = _detect_locale(text)

    parsed_origin, parsed_dest = _extract_journey_stops(text)
    origin = _sanitize_stop_token((origin_stop or parsed_origin).strip().lower())
    destination = _sanitize_stop_token((destination_stop or parsed_dest).strip().lower())

    profile, _ = TransitPassengerProfile.objects.get_or_create(owner=owner)
    if destination in _COMMUTE_ALIASES:
        if _COMMUTE_ALIASES[destination] == "work" and profile.work_stop:
            destination = profile.work_stop.lower()
        elif _COMMUTE_ALIASES[destination] == "home" and profile.home_stop:
            destination = profile.home_stop.lower()
    if origin in _COMMUTE_ALIASES:
        if _COMMUTE_ALIASES[origin] == "work" and profile.work_stop:
            origin = profile.work_stop.lower()
        elif _COMMUTE_ALIASES[origin] == "home" and profile.home_stop:
            origin = profile.home_stop.lower()

    if not origin or not destination:
        if not origin and profile.home_stop:
            origin = profile.home_stop.lower()
        if not destination and profile.work_stop:
            destination = profile.work_stop.lower()

    plans: list[dict[str, Any]] = []
    intent = "general"
    if origin and destination and origin != destination:
        intent = "plan_journey"
        journey = plan_transit_journey(
            origin_stop=origin,
            destination_stop=destination,
            region=region,
        )
        plans = _rank_plans_with_ai(
            plans=journey.get("plans") or [],
            principal=owner,
            locale=resolved_locale,
        )
    elif any(word in text.lower() for word in ("search", "tafuta", "station", "stesheni", "route", "line")):
        intent = "search"
    else:
        maybe_origin, maybe_dest = _extract_journey_stops(text)
        if maybe_origin and maybe_dest:
            intent = "plan_journey"
            journey = plan_transit_journey(
                origin_stop=maybe_origin,
                destination_stop=maybe_dest,
                region=region,
            )
            origin, destination = maybe_origin, maybe_dest
            plans = _rank_plans_with_ai(
                plans=journey.get("plans") or [],
                principal=owner,
                locale=resolved_locale,
            )

    search = (
        search_transit(query=_search_query_from_text(text), region=region)
        if intent == "search" or not plans
        else {"query": text, "routes": [], "stops": []}
    )
    if intent != "search" and not plans and (search.get("stops") or search.get("routes")):
        intent = "search"
    alerts = active_alerts(region=region)
    products = list_transit_products(mode="brt")[:4]

    ai_payload = _assistant_reply(
        principal=owner,
        query=text,
        locale=resolved_locale,
        context={
            "region": region,
            "intent": intent,
            "origin_stop": origin,
            "destination_stop": destination,
            "plan_count": len(plans),
            "alerts": alerts[:3],
            "products": products,
        },
    )
    reply = (
        ai_payload.get("reply")
        or (ai_payload.get("result") or {}).get("reply")
        or ""
    )
    if not reply:
        if intent == "plan_journey" and plans:
            best = plans[0]
            reply = (
                f"Njia bora: {best['route_name']} — dakika {best['duration_minutes']}, bei {best['fare_minor']}."
                if resolved_locale == "sw"
                else f"Best option: {best['route_name']} — {best['duration_minutes']} min, fare {best['fare_minor']}."
            )
        elif resolved_locale == "sw":
            reply = "Uliza kuhusu safari, stesheni, bei, au andika 'kutoka Kimara hadi Kivukoni'."
        else:
            reply = "Ask about trips, stations, fares, or try 'from Kimara to Kivukoni'."

    suggested_actions: list[dict[str, Any]] = []
    if plans:
        top = plans[0]
        suggested_actions.append(
            {
                "action": "open_planner",
                "label": "Angalia mpango" if resolved_locale == "sw" else "View plan",
                "origin_stop": origin,
                "destination_stop": destination,
            }
        )
        suggested_actions.append(
            {
                "action": "buy_ticket",
                "label": "Nunua tiketi" if resolved_locale == "sw" else "Buy ticket",
                "route_id": top.get("route_id"),
                "product_code": "brt_single",
            }
        )
    if search.get("stops"):
        suggested_actions.append(
            {
                "action": "open_station",
                "label": "Fungua stesheni" if resolved_locale == "sw" else "Open station",
                "stop_code": search["stops"][0].get("code") or search["stops"][0].get("stop_code"),
            }
        )

    return {
        "query": text,
        "locale": resolved_locale,
        "intent": intent,
        "reply": reply,
        "origin_stop": origin,
        "destination_stop": destination,
        "plans": plans,
        "search": search,
        "alerts": alerts[:5],
        "suggested_actions": suggested_actions,
        "ai": {
            "capability": "voice_assistant",
            "confidence_e4": ai_payload.get("confidence_e4", 5000),
            "model_version": ai_payload.get("model_version", "mobility.transit.assistant.v1"),
            "reasoning_summary": ai_payload.get("reasoning_summary", ""),
        },
        "model_version": "mobility.transit.assistant.v1",
    }


def _family_member_to_dict(member: TransitFamilyMember, *, guardian_owner: str) -> dict[str, Any]:
    spent = _family_member_spend_minor(
        guardian_owner=guardian_owner,
        member_owner=member.member_owner,
    )
    active_tickets = TransportTicket.objects.filter(
        owner=member.member_owner,
        status="active",
    ).count()
    return {
        "id": str(member.id),
        "member_owner": member.member_owner,
        "display_name": member.display_name,
        "relationship": member.relationship,
        "status": member.status,
        "can_purchase": member.can_purchase,
        "monthly_limit_minor": member.monthly_limit_minor,
        "spent_this_month_minor": spent,
        "active_tickets": active_tickets,
    }


def _family_member_spend_minor(*, guardian_owner: str, member_owner: str) -> int:
    today = timezone.localdate()
    start = today.replace(day=1)
    rows = TransportTicket.objects.filter(
        owner=member_owner,
        metadata__guardian_owner=guardian_owner,
        created_at__date__gte=start,
        created_at__date__lte=today,
    )
    return int(rows.aggregate(total=Sum("fare_minor"))["total"] or 0)


def _require_active_family_member(*, guardian_owner: str, member_owner: str) -> TransitFamilyMember:
    member = TransitFamilyMember.objects.filter(
        guardian_owner=guardian_owner,
        member_owner=member_owner,
        status=TransitFamilyMember.Status.ACTIVE,
    ).first()
    if not member:
        raise MobilityError("family member not linked")
    if not member.can_purchase:
        raise MobilityError("guardian purchases disabled for this member")
    if guardian_owner == member_owner:
        raise MobilityError("cannot add yourself as a family member")
    return member


def transit_family_bundle(*, guardian_owner: str) -> dict[str, Any]:
    members = TransitFamilyMember.objects.filter(
        guardian_owner=guardian_owner,
        status=TransitFamilyMember.Status.ACTIVE,
    ).order_by("display_name")
    member_rows = [_family_member_to_dict(row, guardian_owner=guardian_owner) for row in members]
    member_owners = [row.member_owner for row in members]
    tickets = TransportTicket.objects.filter(owner__in=member_owners).select_related("route").order_by(
        "-created_at"
    )[:30]
    return {
        "guardian_owner": guardian_owner,
        "members": member_rows,
        "tickets": [ticket_to_dict(ticket) for ticket in tickets],
        "model_version": "mobility.transit.family.v1",
    }


@transaction.atomic
def add_transit_family_member(
    *,
    guardian_owner: str,
    member_owner: str,
    display_name: str = "",
    relationship: str = TransitFamilyMember.Relationship.CHILD,
    monthly_limit_minor: int = 0,
) -> TransitFamilyMember:
    member_owner = (member_owner or "").strip()
    if not member_owner:
        raise MobilityError("member_owner required")
    if guardian_owner == member_owner:
        raise MobilityError("cannot add yourself as a family member")
    if relationship not in TransitFamilyMember.Relationship.values:
        raise MobilityError("invalid relationship")
    member, created = TransitFamilyMember.objects.update_or_create(
        guardian_owner=guardian_owner,
        member_owner=member_owner,
        defaults={
            "display_name": display_name or member_owner,
            "relationship": relationship,
            "status": TransitFamilyMember.Status.ACTIVE,
            "can_purchase": True,
            "monthly_limit_minor": max(0, int(monthly_limit_minor or 0)),
        },
    )
    if not created and member.status == TransitFamilyMember.Status.REMOVED:
        member.status = TransitFamilyMember.Status.ACTIVE
        member.display_name = display_name or member.display_name
        member.relationship = relationship
        member.monthly_limit_minor = max(0, int(monthly_limit_minor or 0))
        member.save()
    return member


def remove_transit_family_member(*, guardian_owner: str, member_id) -> None:
    updated = TransitFamilyMember.objects.filter(
        pk=member_id,
        guardian_owner=guardian_owner,
    ).update(status=TransitFamilyMember.Status.REMOVED)
    if not updated:
        raise MobilityError("family member not found")


def list_transit_family_members(*, guardian_owner: str) -> list[dict[str, Any]]:
    rows = TransitFamilyMember.objects.filter(
        guardian_owner=guardian_owner,
        status=TransitFamilyMember.Status.ACTIVE,
    ).order_by("display_name")
    return [_family_member_to_dict(row, guardian_owner=guardian_owner) for row in rows]


def lost_found_item_to_dict(item: TransitLostFoundItem) -> dict[str, Any]:
    return {
        "id": str(item.id),
        "reporter_owner": item.reporter_owner,
        "kind": item.kind,
        "category": item.category,
        "title": item.title,
        "description": item.description,
        "stop_code": item.stop_code,
        "route_code": item.route.code if item.route else "",
        "status": item.status,
        "contact_hint": item.contact_hint,
        "claimant_owner": item.claimant_owner,
        "claim_message": item.claim_message,
        "claimed_at": item.claimed_at.isoformat() if item.claimed_at else "",
        "resolved_at": item.resolved_at.isoformat() if item.resolved_at else "",
        "photo_url": item.photo_url,
        "created_at": item.created_at.isoformat(),
    }


def transit_lost_found_bundle(
    *,
    owner: str,
    kind: str = "",
    stop_code: str = "",
    limit: int = 30,
) -> dict[str, Any]:
    open_qs = TransitLostFoundItem.objects.filter(
        status__in=[
            TransitLostFoundItem.Status.OPEN,
            TransitLostFoundItem.Status.CLAIMED,
        ],
    ).select_related("route")
    if kind in TransitLostFoundItem.Kind.values:
        open_qs = open_qs.filter(kind=kind)
    if stop_code:
        open_qs = open_qs.filter(stop_code=stop_code)
    open_items = list(open_qs.order_by("-created_at")[:limit])
    my_reports = list(
        TransitLostFoundItem.objects.filter(reporter_owner=owner)
        .select_related("route")
        .order_by("-created_at")[:limit]
    )
    my_claims = list(
        TransitLostFoundItem.objects.filter(claimant_owner=owner)
        .select_related("route")
        .order_by("-created_at")[:limit]
    )
    return {
        "open_items": [lost_found_item_to_dict(row) for row in open_items],
        "my_reports": [lost_found_item_to_dict(row) for row in my_reports],
        "my_claims": [lost_found_item_to_dict(row) for row in my_claims],
        "model_version": "mobility.transit.lost_found.v1",
    }


@transaction.atomic
def report_transit_lost_found(
    *,
    owner: str,
    kind: str,
    title: str,
    description: str = "",
    category: str = TransitLostFoundItem.Category.OTHER,
    stop_code: str = "",
    route_id=None,
    contact_hint: str = "",
    photo_url: str = "",
) -> TransitLostFoundItem:
    kind = (kind or "").strip().lower()
    title = (title or "").strip()
    if kind not in TransitLostFoundItem.Kind.values:
        raise MobilityError("kind must be lost or found")
    if not title:
        raise MobilityError("title required")
    if category not in TransitLostFoundItem.Category.values:
        raise MobilityError("invalid category")
    route = None
    if route_id:
        route = PublicTransitRoute.objects.filter(pk=route_id).first()
    item = TransitLostFoundItem.objects.create(
        reporter_owner=owner,
        kind=kind,
        category=category,
        title=title,
        description=description,
        stop_code=stop_code,
        route=route,
        contact_hint=contact_hint,
        photo_url=photo_url,
        status=TransitLostFoundItem.Status.OPEN,
    )
    _emit_transit_notification(
        owner=owner,
        event_type="transit.lost_found.reported",
        title="Lost & found report submitted",
        body=f"Your {kind} report for {title} is now visible to Mwendokasi passengers.",
        deduplication_key=f"transit-lf-report-{item.id}",
        payload={"item_id": str(item.id), "kind": kind},
    )
    return item


@transaction.atomic
def claim_transit_lost_found(
    *,
    item_id,
    claimant_owner: str,
    message: str = "",
) -> TransitLostFoundItem:
    item = TransitLostFoundItem.objects.select_for_update().filter(pk=item_id).first()
    if not item:
        raise MobilityError("item not found")
    if item.kind != TransitLostFoundItem.Kind.FOUND:
        raise MobilityError("only found items can be claimed")
    if item.status != TransitLostFoundItem.Status.OPEN:
        raise MobilityError("item is not open for claims")
    if item.reporter_owner == claimant_owner:
        raise MobilityError("cannot claim your own report")
    item.claimant_owner = claimant_owner
    item.claim_message = message
    item.status = TransitLostFoundItem.Status.CLAIMED
    item.claimed_at = timezone.now()
    item.save(
        update_fields=[
            "claimant_owner",
            "claim_message",
            "status",
            "claimed_at",
            "updated_at",
        ]
    )
    _emit_transit_notification(
        owner=item.reporter_owner,
        event_type="transit.lost_found.claimed",
        title="Someone claimed your found item",
        body=f"A passenger believes {item.title} may be theirs.",
        deduplication_key=f"transit-lf-claim-{item.id}-{claimant_owner}",
        payload={"item_id": str(item.id), "claimant_owner": claimant_owner},
    )
    _emit_transit_notification(
        owner=claimant_owner,
        event_type="transit.lost_found.claim_submitted",
        title="Claim submitted",
        body=f"We notified the finder about {item.title}.",
        deduplication_key=f"transit-lf-claim-ack-{item.id}-{claimant_owner}",
        payload={"item_id": str(item.id)},
    )
    return item


@transaction.atomic
def resolve_transit_lost_found(
    *,
    item_id,
    actor_owner: str,
    status: str = TransitLostFoundItem.Status.CLOSED,
) -> TransitLostFoundItem:
    if status not in {
        TransitLostFoundItem.Status.MATCHED,
        TransitLostFoundItem.Status.CLOSED,
    }:
        raise MobilityError("invalid resolve status")
    item = TransitLostFoundItem.objects.select_for_update().filter(pk=item_id).first()
    if not item:
        raise MobilityError("item not found")
    allowed = {item.reporter_owner, item.claimant_owner}
    if actor_owner not in allowed:
        raise MobilityError("not authorized to resolve this item")
    if item.status in {
        TransitLostFoundItem.Status.CLOSED,
        TransitLostFoundItem.Status.MATCHED,
    }:
        raise MobilityError("item already resolved")
    item.status = status
    item.resolved_at = timezone.now()
    item.save(update_fields=["status", "resolved_at", "updated_at"])
    notify_targets = {item.reporter_owner, item.claimant_owner} - {actor_owner}
    for target in notify_targets:
        if not target:
            continue
        _emit_transit_notification(
            owner=target,
            event_type="transit.lost_found.resolved",
            title="Lost & found item resolved",
            body=f"{item.title} was marked {status}.",
            deduplication_key=f"transit-lf-resolve-{item.id}-{target}",
            payload={"item_id": str(item.id), "status": status},
        )
    return item


def upload_transit_lost_found_photo(
    *,
    owner: str,
    content: bytes,
    content_type: str = "image/jpeg",
) -> str:
    if not content:
        raise MobilityError("photo content required")
    if len(content) > 5 * 1024 * 1024:
        raise MobilityError("photo exceeds 5MB limit")
    ext = "jpg"
    if "png" in content_type:
        ext = "png"
    elif "webp" in content_type:
        ext = "webp"
    key = f"transit/lost-found/{owner}/{secrets.token_hex(8)}.{ext}"
    try:
        from integrations.storage import ObjectStorageNotConfigured, S3CompatibleStorage

        storage = S3CompatibleStorage()
        obj = storage.put(key=key, payload=content, content_type=content_type)
        return obj.url
    except ObjectStorageNotConfigured:
        from django.conf import settings

        if settings.DEBUG or getattr(settings, "RUNNING_TESTS", False):
            return f"https://storage.local/{key}"
        raise MobilityError("photo storage not configured")


def ops_list_transit_lost_found(*, status: str = "", limit: int = 50) -> list[dict[str, Any]]:
    qs = TransitLostFoundItem.objects.select_related("route").order_by("-created_at")
    if status:
        qs = qs.filter(status=status)
    return [lost_found_item_to_dict(row) for row in qs[:limit]]


@transaction.atomic
def ops_resolve_transit_lost_found(
    *,
    item_id,
    status: str = TransitLostFoundItem.Status.CLOSED,
) -> TransitLostFoundItem:
    if status not in {
        TransitLostFoundItem.Status.MATCHED,
        TransitLostFoundItem.Status.CLOSED,
    }:
        raise MobilityError("invalid resolve status")
    item = TransitLostFoundItem.objects.select_for_update().filter(pk=item_id).first()
    if not item:
        raise MobilityError("item not found")
    item.status = status
    item.resolved_at = timezone.now()
    item.save(update_fields=["status", "resolved_at", "updated_at"])
    for target in {item.reporter_owner, item.claimant_owner}:
        if not target:
            continue
        _emit_transit_notification(
            owner=target,
            event_type="transit.lost_found.ops_resolved",
            title="Lost & found closed by operator",
            body=f"{item.title} was marked {status} by Mwendokasi ops.",
            deduplication_key=f"transit-lf-ops-{item.id}-{target}",
            payload={"item_id": str(item.id), "status": status},
        )
    return item
