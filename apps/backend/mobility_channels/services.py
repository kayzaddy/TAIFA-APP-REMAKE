"""Taifa Mobility Hybrid Dispatch — multi-channel orchestration."""
from __future__ import annotations

import hashlib
import re
import secrets
from dataclasses import dataclass
from typing import Any

from django.contrib.auth.hashers import check_password, make_password
from django.db import transaction
from django.utils import timezone

from trips.models import (
    DispatchOffer,
    DispatchOfferStatus,
    Driver,
    DriverAvailability,
    DriverStatus,
    Station,
    Trip,
    TripStatus,
)
from trips.services import MobilityError, accept_offer, notify_mobility, reject_offer

from .models import (
    ChannelDispatchAttempt,
    ChannelKind,
    ChannelStatus,
    DeviceCapability,
    DriverChannelBinding,
    InboundMessage,
    TripBoardingPin,
    UssdSession,
)


class ChannelsError(Exception):
    pass


def _hash_msisdn(msisdn: str) -> str:
    normalized = normalize_msisdn(msisdn)
    return hashlib.sha256(normalized.encode()).hexdigest()


def normalize_msisdn(raw: str) -> str:
    digits = re.sub(r"\D", "", raw or "")
    if digits.startswith("255"):
        return f"+{digits}"
    if digits.startswith("0") and len(digits) >= 10:
        return f"+255{digits[1:]}"
    if len(digits) == 9:
        return f"+255{digits}"
    return f"+{digits}" if digits else ""


def mask_msisdn(msisdn: str) -> str:
    n = normalize_msisdn(msisdn)
    if len(n) < 6:
        return "****"
    return f"{n[:4]}***{n[-2:]}"


@dataclass(frozen=True)
class ChannelPlan:
    channel: str
    reason: str


def select_channel(binding: DriverChannelBinding) -> ChannelPlan:
    """Priority: push → SMS → USSD → IVR → stage."""
    if binding.device_capability == DeviceCapability.SMARTPHONE and binding.has_internet:
        if binding.push_token:
            return ChannelPlan(ChannelKind.PUSH, "smartphone_with_push")
        return ChannelPlan(ChannelKind.PUSH, "smartphone_app_poll")
    if binding.msisdn:
        return ChannelPlan(ChannelKind.SMS, "feature_phone_or_no_data")
    if binding.device_capability == DeviceCapability.FEATURE_PHONE:
        return ChannelPlan(ChannelKind.USSD, "feature_phone_no_sms")
    return ChannelPlan(ChannelKind.STAGE, "no_direct_channel")


def ensure_binding(
    *,
    driver: Driver,
    msisdn: str = "",
    device_capability: str = DeviceCapability.SMARTPHONE,
    has_internet: bool = True,
    has_gps: bool = True,
    push_token: str = "",
) -> DriverChannelBinding:
    msisdn_norm = normalize_msisdn(msisdn) if msisdn else ""
    binding, _ = DriverChannelBinding.objects.get_or_create(
        driver=driver,
        defaults={
            "msisdn": msisdn_norm,
            "msisdn_hash": _hash_msisdn(msisdn_norm) if msisdn_norm else "",
            "device_capability": device_capability,
            "has_internet": has_internet,
            "has_gps": has_gps,
            "push_token": push_token,
        },
    )
    updates: list[str] = []
    if msisdn_norm and binding.msisdn != msisdn_norm:
        binding.msisdn = msisdn_norm
        binding.msisdn_hash = _hash_msisdn(msisdn_norm)
        updates.extend(["msisdn", "msisdn_hash"])
    if push_token and binding.push_token != push_token:
        binding.push_token = push_token
        updates.append("push_token")
    if updates:
        binding.save(update_fields=updates + ["updated_at"])
    return binding


def _format_fare(trip: Trip) -> str:
    return f"{trip.fare_minor:,} {trip.currency}"


def sms_offer_body(*, trip: Trip, offer: DispatchOffer, driver: Driver) -> str:
    ride_id = str(trip.id)[:8].upper()
    return (
        "TAIFA MOBILITY\n\n"
        "New Ride Request\n\n"
        f"Passenger:\n{trip.owner}\n\n"
        f"Pickup:\n{trip.pickup_name}\n\n"
        f"Destination:\n{trip.dropoff_name}\n\n"
        f"Estimated Fare:\n{_format_fare(trip)}\n\n"
        "Reply YES or 1 within 30 seconds to accept.\n\n"
        f"Ride ID:\n{ride_id}"
    )


def sms_passenger_accepted(*, trip: Trip, driver: Driver, vehicle_label: str, eta_min: int) -> str:
    binding = DriverChannelBinding.objects.filter(driver=driver).first()
    phone = binding.msisdn if binding and binding.msisdn else driver.phone_masked
    return (
        "Your ride has been accepted.\n\n"
        f"Driver:\n{driver.full_name}\n\n"
        f"Phone:\n{phone}\n\n"
        f"Vehicle:\n{vehicle_label}\n\n"
        f"Estimated Arrival:\n{eta_min} min\n\n"
        "Please contact your rider if necessary."
    )


def _deliver(channel: str, to: str, subject: str, body: str, metadata: dict) -> bool:
    try:
        from integrations.notifications import NotificationNotConfigured, deliver_notification

        result = deliver_notification(
            channel=channel,
            to=to,
            subject=subject,
            body=body,
            metadata=metadata,
        )
        return result.accepted
    except NotificationNotConfigured:
        return False
    except Exception:
        return False


def _record_attempt(
    *,
    offer: DispatchOffer,
    channel: str,
    status: str,
    detail: dict | None = None,
) -> ChannelDispatchAttempt:
    return ChannelDispatchAttempt.objects.create(
        offer=offer,
        trip=offer.trip,
        driver=offer.driver,
        channel=channel,
        status=status,
        detail=detail or {},
    )


def notify_driver_offer(*, offer: DispatchOffer) -> ChannelDispatchAttempt:
    """Send dispatch offer via best channel; schedule IVR fallback if SMS."""
    trip = offer.trip
    driver = offer.driver
    binding = DriverChannelBinding.objects.filter(driver=driver).first()
    if binding is None:
        binding = ensure_binding(
            driver=driver,
            msisdn="",
            device_capability=DeviceCapability.SMARTPHONE,
        )
    plan = select_channel(binding)
    body = sms_offer_body(trip=trip, offer=offer, driver=driver)
    metadata = {
        "offer_id": str(offer.id),
        "trip_id": str(trip.id),
        "channel": plan.channel,
    }

    if plan.channel == ChannelKind.PUSH:
        notify_mobility(
            recipient_principal=driver.owner_principal,
            event_type="mobility.dispatch.offer",
            deduplication_key=f"offer-push:{offer.id}",
            trip=trip,
            station=trip.station,
            payload={
                "offer_id": str(offer.id),
                "eta_seconds": offer.eta_seconds,
                "channel": "push",
                "body": body,
            },
        )
        attempt = _record_attempt(offer=offer, channel=ChannelKind.PUSH, status=ChannelStatus.SENT)
        _schedule_ivr_fallback(offer.id)
        return attempt

    if plan.channel == ChannelKind.SMS and binding.msisdn:
        accepted = _deliver(
            "sms",
            binding.msisdn,
            "Taifa Mobility Ride",
            body,
            metadata,
        )
        notify_mobility(
            recipient_principal=driver.owner_principal,
            event_type="mobility.dispatch.offer",
            deduplication_key=f"offer-sms:{offer.id}",
            trip=trip,
            station=trip.station,
            payload={
                "offer_id": str(offer.id),
                "channel": "sms",
                "msisdn": binding.msisdn,
                "body": body,
            },
        )
        status = ChannelStatus.SENT if accepted else ChannelStatus.FAILED
        attempt = _record_attempt(
            offer=offer,
            channel=ChannelKind.SMS,
            status=status,
            detail={"body": body, "to": binding.msisdn, "driver_name": driver.full_name},
        )
        _schedule_ivr_fallback(offer.id)
        return attempt

    if plan.channel == ChannelKind.USSD:
        attempt = _record_attempt(
            offer=offer,
            channel=ChannelKind.USSD,
            status=ChannelStatus.SENT,
            detail={"hint": "Dial *150*99# to accept"},
        )
        _schedule_ivr_fallback(offer.id)
        return attempt

    # Stage dispatcher fallback
    notify_stage_dispatcher(trip=trip, reason="no_driver_channel")
    return _record_attempt(offer=offer, channel=ChannelKind.STAGE, status=ChannelStatus.SENT)


def fanout_dispatch_offers(*, trip: Trip, offers: list[DispatchOffer]) -> None:
    """Called after trips.dispatch_trip creates offers."""
    for offer in offers:
        try:
            notify_driver_offer(offer=offer)
        except Exception:
            continue


def _schedule_ivr_fallback(offer_id) -> None:
    try:
        from .tasks import schedule_ivr_fallback

        schedule_ivr_fallback(offer_id)
    except Exception:
        pass


def notify_stage_dispatcher(*, trip: Trip, reason: str = "") -> None:
    station = trip.station
    if station is None:
        return
    manager = station.manager_principal
    if not manager:
        return
    notify_mobility(
        recipient_principal=manager,
        event_type="mobility.stage.dispatch_needed",
        deduplication_key=f"stage-dispatch:{trip.id}",
        trip=trip,
        station=station,
        payload={
            "reason": reason,
            "channel": "stage",
            "body": (
                f"Stage alert: trip {str(trip.id)[:8]} needs manual assignment. "
                f"Pickup {trip.pickup_name} → {trip.dropoff_name}"
            ),
        },
    )


def initiate_ivr_offer(*, offer: DispatchOffer) -> ChannelDispatchAttempt:
    binding = DriverChannelBinding.objects.filter(driver=offer.driver).first()
    if not binding or not binding.msisdn:
        notify_stage_dispatcher(trip=offer.trip, reason="ivr_no_msisdn")
        return _record_attempt(offer=offer, channel=ChannelKind.IVR, status=ChannelStatus.FAILED)
    script = (
        "Hello. You have received a new Taifa Mobility ride request. "
        "Press 1 to accept. Press 2 to decline. Press 3 if you are unavailable."
    )
    accepted = _deliver(
        "sms",  # voice providers often share SMS gateway config in foundation
        binding.msisdn,
        "Taifa Mobility IVR",
        script,
        {"offer_id": str(offer.id), "mode": "ivr"},
    )
    status = ChannelStatus.SENT if accepted else ChannelStatus.FAILED
    return _record_attempt(offer=offer, channel=ChannelKind.IVR, status=status)


def parse_sms_response(body: str) -> str:
    text = (body or "").strip().upper()
    if text in {"YES", "Y", "1", "NDIO", "KUBALI"}:
        return "accept"
    if text in {"NO", "N", "2", "HAPANA", "KATAA"}:
        return "reject"
    if text.startswith("REGISTER"):
        return "register"
    return "unknown"


@transaction.atomic
def handle_inbound_sms(*, msisdn: str, body: str) -> dict[str, Any]:
    InboundMessage.objects.create(
        channel=ChannelKind.SMS,
        msisdn_hash=_hash_msisdn(msisdn),
        body=body,
    )
    action = parse_sms_response(body)
    if action == "register":
        return register_driver_sms(body=body, msisdn=msisdn)

    binding = DriverChannelBinding.objects.filter(msisdn_hash=_hash_msisdn(msisdn)).first()
    if binding is None:
        return {"status": "unknown_driver", "detail": "Driver not registered"}

    if action == "accept":
        offer = (
            DispatchOffer.objects.select_related("trip", "driver")
            .filter(
                driver=binding.driver,
                status=DispatchOfferStatus.PENDING,
                expires_at__gt=timezone.now(),
            )
            .order_by("-created_at")
            .first()
        )
        if offer is None:
            return {"status": "no_offer"}
        trip = accept_offer(offer.id, driver=binding.driver)
        return {"status": "accepted", "trip_id": str(trip.id)}

    if action == "reject":
        offer = DispatchOffer.objects.filter(
            driver=binding.driver,
            status=DispatchOfferStatus.PENDING,
            expires_at__gt=timezone.now(),
        ).first()
        if offer:
            reject_offer(offer.id, driver=binding.driver, reason="sms_reject")
        return {"status": "rejected"}

    return {"status": "ignored"}


def register_driver_sms(*, body: str, msisdn: str) -> dict[str, Any]:
    """REGISTER JOHN MWENGE BOXER → create driver + binding."""
    parts = body.strip().split()
    if len(parts) < 4 or parts[0].upper() != "REGISTER":
        return {"status": "invalid_format", "hint": "REGISTER {Name} {Stage} {Vehicle}"}
    name = parts[1]
    stage_code = parts[2].upper()
    vehicle = " ".join(parts[3:])
    station = Station.objects.filter(name__icontains=stage_code, active=True).first()
    principal = f"driver-sms-{_hash_msisdn(msisdn)[:16]}"
    driver, created = Driver.objects.get_or_create(
        owner_principal=principal,
        defaults={
            "full_name": name,
            "phone_masked": mask_msisdn(msisdn),
            "status": DriverStatus.ACTIVE,
            "availability": DriverAvailability.AVAILABLE,
            "station": station,
        },
    )
    ensure_binding(
        driver=driver,
        msisdn=msisdn,
        device_capability=DeviceCapability.FEATURE_PHONE,
        has_internet=False,
        has_gps=False,
    )
    return {"status": "registered", "driver_id": str(driver.id), "created": created}


USSD_MENU_ROOT = (
    "CON Taifa Mobility\n"
    "1. New Ride\n"
    "2. Accept Ride\n"
    "3. Wallet Balance\n"
    "4. Today's Earnings\n"
    "5. Withdraw Money\n"
    "6. Completed Trips\n"
    "7. Help"
)


def handle_ussd(*, msisdn: str, text: str) -> str:
    """Africa's Talking style USSD callback (text = cumulative input)."""
    msisdn_hash = _hash_msisdn(msisdn)
    session, _ = UssdSession.objects.get_or_create(
        msisdn_hash=msisdn_hash,
        active=True,
        defaults={"state": "root", "data": {}},
    )
    parts = [p for p in (text or "").split("*") if p]
    choice = parts[-1] if parts else ""

    if not choice:
        session.state = "root"
        session.save(update_fields=["state", "updated_at"])
        return USSD_MENU_ROOT

    if choice == "2":
        binding = DriverChannelBinding.objects.filter(msisdn_hash=msisdn_hash).first()
        if binding is None:
            return "END Register via SMS: REGISTER Name Stage Vehicle"
        offer = DispatchOffer.objects.filter(
            driver=binding.driver,
            status=DispatchOfferStatus.PENDING,
            expires_at__gt=timezone.now(),
        ).first()
        if offer is None:
            return "END No pending ride offers"
        try:
            trip = accept_offer(offer.id, driver=binding.driver)
            return f"END Ride accepted. Passenger trip {str(trip.id)[:8]}"
        except MobilityError as exc:
            return f"END {exc}"

    if choice == "7":
        return "END Taifa Mobility help: SMS REGISTER or reply YES to accept rides."

    return "END Feature coming soon. Use SMS YES to accept rides."


def handle_ivr_dtmf(*, offer_id: str, digit: str) -> dict[str, Any]:
    offer = DispatchOffer.objects.select_related("trip", "driver").filter(pk=offer_id).first()
    if offer is None:
        return {"status": "offer_not_found"}
    if digit == "1":
        trip = accept_offer(offer.id, driver=offer.driver)
        return {"status": "accepted", "trip_id": str(trip.id)}
    if digit == "2":
        reject_offer(offer.id, driver=offer.driver, reason="ivr_decline")
        return {"status": "rejected"}
    if digit == "3":
        reject_offer(offer.id, driver=offer.driver, reason="ivr_unavailable")
        return {"status": "unavailable"}
    return {"status": "ignored"}


@transaction.atomic
def generate_boarding_pin(*, trip: Trip) -> str:
    pin = f"{secrets.randbelow(10**6):06d}"
    TripBoardingPin.objects.update_or_create(
        trip=trip,
        defaults={"pin_hash": make_password(pin)},
    )
    meta = dict(trip.metadata or {})
    meta["boarding_pin_issued"] = True
    trip.metadata = meta
    trip.save(update_fields=["metadata", "updated_at"])
    return pin


def verify_boarding_pin(*, trip: Trip, pin: str, actor: str = "") -> bool:
    record = TripBoardingPin.objects.filter(trip=trip).first()
    if record is None:
        raise ChannelsError("boarding pin not issued")
    if not check_password(pin, record.pin_hash):
        return False
    record.verified_at = timezone.now()
    record.verified_by = actor
    record.save(update_fields=["verified_at", "verified_by"])
    return True


def on_trip_accepted(*, trip: Trip, driver: Driver) -> None:
    """Passenger SMS + boarding PIN after accept (any channel)."""
    pin = generate_boarding_pin(trip=trip)
    eta_min = max(1, int((trip.duration_seconds or 600) / 60))
    vehicle = trip.vehicle_label or trip.vehicle.registration_number if trip.vehicle_id else ""
    body = sms_passenger_accepted(
        trip=trip,
        driver=driver,
        vehicle_label=vehicle,
        eta_min=eta_min,
    )
    passenger_msisdn = (trip.metadata or {}).get("passenger_msisdn", "")
    if passenger_msisdn:
        _deliver(
            "sms",
            normalize_msisdn(passenger_msisdn),
            "Ride accepted",
            f"{body}\n\nTrip PIN: {pin}",
            {"trip_id": str(trip.id)},
        )
    notify_mobility(
        recipient_principal=trip.owner,
        event_type="mobility.trip.driver_assigned",
        deduplication_key=f"hybrid-assigned:{trip.id}",
        trip=trip,
        payload={
            "driver_name": driver.full_name,
            "vehicle": vehicle,
            "boarding_pin_hint": "share with driver",
            "channel": "hybrid",
        },
    )
    driver_binding = DriverChannelBinding.objects.filter(driver=driver).first()
    if driver_binding and driver_binding.msisdn and driver_binding.device_capability == DeviceCapability.FEATURE_PHONE:
        passenger_phone = passenger_msisdn or trip.owner
        _deliver(
            "sms",
            driver_binding.msisdn,
            "Passenger contact",
            f"Ride accepted. Call passenger: {passenger_phone}\nPickup: {trip.pickup_name}",
            {"trip_id": str(trip.id)},
        )


def trip_dispatch_detail(*, trip: Trip) -> dict[str, Any]:
    """Dev/demo: expose channel attempts and last SMS offer for UI simulation."""
    attempts = list(
        ChannelDispatchAttempt.objects.filter(trip=trip)
        .select_related("driver")
        .order_by("-created_at")[:20]
    )
    sms_preview = ""
    sms_to = ""
    sms_driver_name = ""
    sms_offer_id = ""
    for attempt in attempts:
        if attempt.channel == ChannelKind.SMS and attempt.detail.get("body"):
            sms_preview = str(attempt.detail.get("body", ""))
            sms_to = str(attempt.detail.get("to", ""))
            sms_driver_name = str(attempt.detail.get("driver_name", attempt.driver.full_name))
            sms_offer_id = str(attempt.offer_id)
            break

    channel_rows = [
        {
            "channel": a.channel,
            "status": a.status,
            "driver_name": a.driver.full_name,
            "created_at": a.created_at.isoformat(),
        }
        for a in attempts
    ]
    pending = DispatchOffer.objects.filter(
        trip=trip,
        status=DispatchOfferStatus.PENDING,
        expires_at__gt=timezone.now(),
    ).count()
    return {
        "trip_id": str(trip.id),
        "trip_status": trip.status,
        "hybrid_sms_demo": bool((trip.metadata or {}).get("hybrid_sms_demo")),
        "sms_sent": bool(sms_preview),
        "sms_preview": sms_preview,
        "sms_to": sms_to,
        "sms_driver_name": sms_driver_name,
        "sms_offer_id": sms_offer_id,
        "pending_offers": pending,
        "channels": channel_rows,
    }


def simulate_feature_phone_sms_accept(*, trip: Trip) -> dict[str, Any]:
    """Demo helper: accept pending offer via SMS YES for a feature-phone driver."""
    offers = (
        DispatchOffer.objects.select_related("driver")
        .filter(
            trip=trip,
            status=DispatchOfferStatus.PENDING,
            expires_at__gt=timezone.now(),
        )
        .order_by("rank")
    )
    for offer in offers:
        binding = DriverChannelBinding.objects.filter(
            driver=offer.driver,
            device_capability=DeviceCapability.FEATURE_PHONE,
        ).first()
        if binding and binding.msisdn:
            return handle_inbound_sms(msisdn=binding.msisdn, body="YES")
        if binding is None:
            binding = DriverChannelBinding.objects.filter(driver=offer.driver).first()
        if binding and binding.msisdn:
            return handle_inbound_sms(msisdn=binding.msisdn, body="YES")
    return {"status": "no_offer"}


def passenger_status_message(trip: Trip) -> str:
    """Friendly status for passenger UI — channel-agnostic."""
    status = trip.status
    if (trip.metadata or {}).get("hybrid_sms_demo") and status == TripStatus.SEARCHING:
        return "Contacting nearby riders via SMS…"
    mapping = {
        TripStatus.REQUESTED: "Ride request received",
        TripStatus.REQUESTING: "Looking for nearby driver",
        TripStatus.SEARCHING: "Finding your nearest driver…",
        TripStatus.DRIVER_ASSIGNED: "Best driver selected",
        TripStatus.DRIVER_EN_ROUTE: "Rider is on the way",
        TripStatus.ARRIVED: "Almost there",
        TripStatus.DRIVER_ARRIVED: "Driver has arrived",
        TripStatus.PASSENGER_BOARDED: "Trip starting",
        TripStatus.IN_PROGRESS: "Trip in progress",
        TripStatus.TRIP_STARTED: "Trip in progress",
        TripStatus.COMPLETED: "Trip completed successfully",
    }
    return mapping.get(status, "Processing your ride")
