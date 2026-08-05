"""Intercity, public transit, enterprise, emergency, and logistics commands.

Creates operational Trip rows via existing create_trip/dispatch where needed.
Never posts payments — only stores payment_ref placeholders for Taifa Payments.
"""
from __future__ import annotations

import hashlib
import secrets
from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from .models import TripKind, TransportMode
from .national_models import (
    EmergencyDispatchRequest,
    EnterpriseEmployee,
    EnterpriseOrganization,
    IntercityBooking,
    IntercityCorridor,
    IntercityDeparture,
    LogisticsShipment,
    PublicTransitRoute,
    PublicTransitTimetable,
    TransportTicket,
)
from .services import MobilityError, create_trip, dispatch_trip


def _ticket_code(prefix: str) -> str:
    return f"{prefix}-{secrets.token_hex(8).upper()}"


@transaction.atomic
def book_intercity_departure(
    *,
    departure_id,
    owner: str,
    seats: int = 1,
) -> IntercityBooking:
    departure = IntercityDeparture.objects.select_for_update().get(pk=departure_id)
    if departure.status != "scheduled":
        raise MobilityError("departure is not open for booking")
    if seats < 1 or seats > departure.seats_available:
        raise MobilityError("insufficient seats")
    fare = departure.fare_minor * seats
    departure.seats_available -= seats
    if departure.seats_available == 0:
        departure.status = "full"
    departure.save(update_fields=["seats_available", "status"])
    booking = IntercityBooking.objects.create(
        departure=departure,
        owner=owner,
        seats=seats,
        fare_minor=fare,
        currency=departure.currency,
        status="reserved",
        ticket_code=_ticket_code("IC"),
    )
    TransportTicket.objects.create(
        owner=owner,
        ticket_type=TransportTicket.TicketType.QR,
        media_code=booking.ticket_code,
        intercity_booking=booking,
        fare_minor=fare,
        currency=departure.currency,
        valid_from=timezone.now(),
        valid_to=departure.arrives_at,
        status="active",
        metadata={"kind": "intercity"},
    )
    return booking


@transaction.atomic
def issue_transit_ticket(
    *,
    owner: str,
    route_id,
    ticket_type: str = TransportTicket.TicketType.SINGLE,
    fare_minor: int | None = None,
    days_valid: int = 1,
) -> TransportTicket:
    route = PublicTransitRoute.objects.get(pk=route_id, active=True)
    timetable = (
        PublicTransitTimetable.objects.filter(route=route, active=True)
        .order_by("fare_minor")
        .first()
    )
    amount = fare_minor if fare_minor is not None else (timetable.fare_minor if timetable else 0)
    now = timezone.now()
    return TransportTicket.objects.create(
        owner=owner,
        ticket_type=ticket_type,
        media_code=_ticket_code("PT"),
        route=route,
        fare_minor=amount,
        valid_from=now,
        valid_to=now + timezone.timedelta(days=days_valid),
        status="active",
        metadata={"route_code": route.code},
    )


def validate_ticket(*, media_code: str) -> TransportTicket:
    ticket = TransportTicket.objects.get(media_code=media_code)
    now = timezone.now()
    if ticket.status != "active":
        raise MobilityError("ticket is not active")
    if not (ticket.valid_from <= now <= ticket.valid_to):
        ticket.status = "expired"
        ticket.save(update_fields=["status"])
        raise MobilityError("ticket expired")
    return ticket


@transaction.atomic
def create_emergency_dispatch(
    *,
    requester: str,
    kind: str,
    region: str,
    pickup_name: str,
    pickup_lat: Decimal,
    pickup_lng: Decimal,
    dropoff_name: str = "",
    dropoff_lat: Decimal | None = None,
    dropoff_lng: Decimal | None = None,
    district: str = "",
    severity: str = "critical",
) -> EmergencyDispatchRequest:
    drop_name = dropoff_name or "Nearest emergency facility"
    drop_lat = dropoff_lat if dropoff_lat is not None else pickup_lat
    drop_lng = dropoff_lng if dropoff_lng is not None else pickup_lng
    mode = TransportMode.AMBULANCE if kind == "ambulance" else TransportMode.VAN
    trip = create_trip(
        owner=requester,
        actor=requester,
        pickup_name=pickup_name,
        pickup_lat=pickup_lat,
        pickup_lng=pickup_lng,
        dropoff_name=drop_name,
        dropoff_lat=drop_lat,
        dropoff_lng=drop_lng,
        vehicle_mode=mode,
        kind=TripKind.EMERGENCY,
        dispatch_strategy="emergency",
        region=region,
        estimated_distance_meters=5000,
        estimated_duration_seconds=900,
        payment_method="cash",
    )
    try:
        dispatch_trip(trip.id, actor="emergency-dispatch", offer_seconds=45)
        trip.refresh_from_db()
    except MobilityError:
        pass
    return EmergencyDispatchRequest.objects.create(
        requester_principal=requester,
        kind=kind,
        severity=severity,
        region=region,
        district=district,
        pickup_name=pickup_name,
        pickup_lat=pickup_lat,
        pickup_lng=pickup_lng,
        dropoff_name=drop_name,
        dropoff_lat=drop_lat,
        dropoff_lng=drop_lng,
        status="dispatched" if trip.driver_id else "searching",
        trip=trip,
        metadata={"vehicle_mode": mode},
    )


@transaction.atomic
def create_logistics_shipment(
    *,
    owner: str,
    category: str,
    origin_name: str,
    origin_lat: Decimal,
    origin_lng: Decimal,
    destination_name: str,
    destination_lat: Decimal,
    destination_lng: Decimal,
    region: str = "",
    vehicle_mode: str = TransportMode.TRUCK,
    weight_kg_e2: int = 0,
    warehouse_code: str = "",
    recipient_name: str = "",
    recipient_phone_masked: str = "",
    verification_code: str = "0000",
) -> LogisticsShipment:
    from django.contrib.auth.hashers import make_password

    from .models import Delivery

    mode = vehicle_mode
    if category in {"courier", "medical", "last_mile"} and mode == TransportMode.TRUCK:
        mode = TransportMode.DELIVERY_BIKE
    trip = create_trip(
        owner=owner,
        actor=owner,
        pickup_name=origin_name,
        pickup_lat=origin_lat,
        pickup_lng=origin_lng,
        dropoff_name=destination_name,
        dropoff_lat=destination_lat,
        dropoff_lng=destination_lng,
        vehicle_mode=mode,
        kind=TripKind.DELIVERY,
        dispatch_strategy="station_first",
        region=region,
        estimated_distance_meters=8000,
        estimated_duration_seconds=1200,
    )
    delivery = Delivery.objects.create(
        trip=trip,
        category=category if category in {
            "food", "medicine", "documents", "package", "business", "parcel", "corporate_logistics"
        } else "package",
        recipient_name=recipient_name or "Recipient",
        recipient_phone_masked=recipient_phone_masked or "****",
        verification_hash=make_password(verification_code),
        package_notes=f"logistics:{category}",
    )
    try:
        dispatch_trip(trip.id)
        trip.refresh_from_db()
    except MobilityError:
        pass
    return LogisticsShipment.objects.create(
        owner=owner,
        category=category,
        origin_name=origin_name,
        origin_lat=origin_lat,
        origin_lng=origin_lng,
        destination_name=destination_name,
        destination_lat=destination_lat,
        destination_lng=destination_lng,
        region=region,
        vehicle_mode=mode,
        weight_kg_e2=weight_kg_e2,
        status="in_transit" if trip.driver_id else "created",
        trip=trip,
        delivery=delivery,
        warehouse_code=warehouse_code,
    )


def authorize_enterprise_trip(
    *,
    organization_code: str,
    employee_principal: str,
    department: str = "",
) -> EnterpriseOrganization:
    org = EnterpriseOrganization.objects.get(code=organization_code, active=True)
    employee = EnterpriseEmployee.objects.filter(
        organization=org, principal=employee_principal, active=True
    ).first()
    if employee is None:
        raise MobilityError("employee is not enrolled in enterprise organization")
    allowed_departments = (org.policy or {}).get("allowed_departments") or []
    if allowed_departments and department and department not in allowed_departments:
        raise MobilityError("department is not authorized for enterprise transport")
    return org


def create_partner_credential(
    *,
    partner_code: str,
    legal_name: str,
    owner_principal: str,
    scopes: list[str] | None = None,
) -> tuple:
    raw_key = secrets.token_urlsafe(32)
    prefix = raw_key[:12]
    digest = hashlib.sha256(raw_key.encode("utf-8")).hexdigest()
    from .national_models import PartnerApiCredential

    cred = PartnerApiCredential.objects.create(
        partner_code=partner_code,
        legal_name=legal_name,
        owner_principal=owner_principal,
        api_key_prefix=prefix,
        api_key_hash=digest,
        scopes=scopes
        or [
            "mobility.read",
            "mobility.trips.write",
            "mobility.national.read",
        ],
    )
    return cred, raw_key
