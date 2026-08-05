"""Tourism trip orchestration — seed itinerary generation for MVP."""
from __future__ import annotations

from datetime import timedelta
from typing import Any

from django.db import transaction
from django.utils import timezone

from .models import TourismItineraryVersion, TourismTrip, TourismTripStatus


class TourismError(Exception):
    pass


def _day(day_num: int, title: str, items: list[dict[str, Any]]) -> dict[str, Any]:
    return {"day": day_num, "title": title, "items": items}


def _item(time: str, title: str, kind: str = "activity", note: str = "") -> dict[str, str]:
    return {"time": time, "title": title, "kind": kind, "note": note}


def generate_itinerary_options(*, trip: TourismTrip) -> list[TourismItineraryVersion]:
    """Create 2–3 demo itineraries from trip profile (AI replacement in phase 2)."""
    party = trip.party_size or 2
    luxury = trip.budget_tier == "luxury"
    base = 3_500_000_00 if luxury else 1_800_000_00
    per_person = base * party

    safari_days = [
        _day(
            1,
            "Arrival Dar es Salaam",
            [
                _item("14:00", "Airport pickup", "transfer"),
                _item("16:00", "Hotel check-in", "stay"),
                _item("19:30", "Waterfront dinner", "dining"),
            ],
        ),
        _day(
            2,
            "Fly to Serengeti",
            [
                _item("07:00", "Domestic flight to Seronera", "flight"),
                _item("12:00", "Lodge check-in", "stay"),
                _item("16:00", "Sunset game drive", "safari"),
            ],
        ),
        _day(3, "Serengeti full day", [_item("06:00", "Game drive", "safari")]),
        _day(
            4,
            "Ngorongoro crater",
            [
                _item("05:30", "Crater descent", "safari"),
                _item("14:00", "Transfer to Arusha", "transfer"),
            ],
        ),
        _day(
            5,
            "Fly to Zanzibar",
            [
                _item("09:00", "Flight to Zanzibar", "flight"),
                _item("15:00", "Beach resort check-in", "stay"),
            ],
        ),
        _day(6, "Stone Town", [_item("09:00", "Heritage walk", "culture")]),
        _day(7, "Mnemba reef", [_item("08:00", "Snorkel excursion", "activity")]),
        _day(8, "Departure", [_item("11:00", "Airport transfer", "transfer")]),
    ]

    beach_days = [
        _day(1, "Arrival Zanzibar", [_item("13:00", "Resort check-in", "stay")]),
        _day(2, "Stone Town & spices", [_item("10:00", "Guided tour", "culture")]),
        _day(3, "Beach day", [_item("All day", "Relaxation", "activity")]),
        _day(4, "Dhow sunset", [_item("17:00", "Sunset cruise", "activity")]),
        _day(5, "Departure", [_item("10:00", "Transfer to airport", "transfer")]),
    ]

    options = [
        ("Safari + Zanzibar classic", "Northern circuit then Indian Ocean", safari_days, int(per_person * 2.4)),
        ("Zanzibar escape", "Short beach & culture break", beach_days, int(per_person * 0.85)),
    ]
    if "safari" in [str(i).lower() for i in (trip.interests or [])] or luxury:
        options.append(
            (
                "Serengeti focus",
                "Maximum wildlife time",
                safari_days[:5],
                int(per_person * 1.9),
            )
        )

    created: list[TourismItineraryVersion] = []
    trip.itineraries.all().delete()
    for idx, (label, summary, days, estimate) in enumerate(options, start=1):
        created.append(
            TourismItineraryVersion.objects.create(
                trip=trip,
                version=idx,
                label=label,
                summary=summary,
                days=days,
                estimate_minor=estimate,
                currency="TZS",
            )
        )
    return created


@transaction.atomic
def create_trip(
    *,
    owner: str,
    title: str = "My Tanzania trip",
    party_size: int = 2,
    budget_tier: str = "mid",
    travel_style: str = "leisure",
    interests: list | None = None,
    start_date=None,
    end_date=None,
) -> TourismTrip:
    return TourismTrip.objects.create(
        owner=owner,
        title=title,
        party_size=max(1, min(party_size, 20)),
        budget_tier=budget_tier or "mid",
        travel_style=travel_style or "leisure",
        interests=interests or [],
        start_date=start_date,
        end_date=end_date,
        status=TourismTripStatus.PLANNING,
    )


@transaction.atomic
def plan_trip(
    *,
    trip: TourismTrip,
    party_size: int | None = None,
    budget_tier: str | None = None,
    travel_style: str | None = None,
    interests: list | None = None,
    start_date=None,
    end_date=None,
) -> tuple[TourismTrip, list[TourismItineraryVersion]]:
    if party_size is not None:
        trip.party_size = max(1, min(party_size, 20))
    if budget_tier:
        trip.budget_tier = budget_tier
    if travel_style:
        trip.travel_style = travel_style
    if interests is not None:
        trip.interests = interests
    if start_date:
        trip.start_date = start_date
    if end_date:
        trip.end_date = end_date
    elif start_date and not end_date:
        trip.end_date = start_date + timedelta(days=7)
    trip.save()
    itineraries = generate_itinerary_options(trip=trip)
    return trip, itineraries


@transaction.atomic
def select_itinerary(*, trip: TourismTrip, itinerary_id) -> TourismTrip:
    try:
        itin = TourismItineraryVersion.objects.get(pk=itinerary_id, trip=trip)
    except TourismItineraryVersion.DoesNotExist as exc:
        raise TourismError("itinerary not found") from exc
    trip.selected_itinerary = itin
    if trip.start_date and itin.days:
        last_day = max(d.get("day", 1) for d in itin.days)
        trip.end_date = trip.start_date + timedelta(days=max(0, last_day - 1))
    trip.status = TourismTripStatus.READY
    trip.save(update_fields=["selected_itinerary", "end_date", "status", "updated_at"])
    return trip


@transaction.atomic
def attach_booking(
    *,
    trip: TourismTrip,
    booking_type: str,
    booking_id: str,
) -> TourismTrip:
    bid = str(booking_id)
    if booking_type == "tour":
        ids = list(trip.tour_booking_ids or [])
        if bid not in ids:
            ids.append(bid)
        trip.tour_booking_ids = ids
    elif booking_type == "stay":
        ids = list(trip.stay_booking_ids or [])
        if bid not in ids:
            ids.append(bid)
        trip.stay_booking_ids = ids
    else:
        raise TourismError("booking_type must be tour or stay")
    if trip.status == TourismTripStatus.PLANNING and trip.selected_itinerary_id:
        trip.status = TourismTripStatus.READY
    trip.save(update_fields=["tour_booking_ids", "stay_booking_ids", "status", "updated_at"])
    return trip


def trip_to_dict(trip: TourismTrip) -> dict:
    sel = trip.selected_itinerary
    return {
        "id": str(trip.id),
        "title": trip.title,
        "status": trip.status,
        "start_date": trip.start_date.isoformat() if trip.start_date else None,
        "end_date": trip.end_date.isoformat() if trip.end_date else None,
        "party_size": trip.party_size,
        "budget_tier": trip.budget_tier,
        "travel_style": trip.travel_style,
        "interests": trip.interests or [],
        "tour_booking_ids": trip.tour_booking_ids or [],
        "stay_booking_ids": trip.stay_booking_ids or [],
        "selected_itinerary_id": str(sel.id) if sel else None,
        "created_at": trip.created_at.isoformat(),
        "updated_at": trip.updated_at.isoformat(),
        "model_version": "tourism.trip.v1",
    }


def itinerary_to_dict(itin: TourismItineraryVersion) -> dict:
    return {
        "id": str(itin.id),
        "trip_id": str(itin.trip_id),
        "version": itin.version,
        "label": itin.label,
        "summary": itin.summary,
        "days": itin.days or [],
        "estimate_minor": itin.estimate_minor,
        "currency": itin.currency,
        "created_at": itin.created_at.isoformat(),
    }


# --- Cart & unified checkout (TAIFA-TOUR-003/004/006) ---

TRAVEL_INSURANCE_PLANS: dict[str, dict[str, Any]] = {
    "ins-travel": {
        "plan_name": "Safari Travel Cover",
        "provider": "Strategies Insurance",
        "category": "Travel",
        "premium_minor_per_guest": 2_500_000,
        "coverage_minor": 200_000_000,
    },
}

ESIM_PLANS: dict[str, dict[str, Any]] = {
    "esim-7d-5gb": {
        "plan_name": "Tanzania 7 days · 5 GB",
        "data_gb": 5,
        "days": 7,
        "price_minor": 1_500_000,
        "mno": "Taifa MNO Partner",
    },
    "esim-14d-10gb": {
        "plan_name": "Tanzania 14 days · 10 GB",
        "data_gb": 10,
        "days": 14,
        "price_minor": 2_800_000,
        "mno": "Taifa MNO Partner",
    },
}


def list_esim_plans() -> list[dict]:
    rows = []
    for plan_id, meta in ESIM_PLANS.items():
        rows.append(
            {
                "plan_id": plan_id,
                "plan_name": meta["plan_name"],
                "data_gb": meta["data_gb"],
                "days": meta["days"],
                "price_minor": int(meta["price_minor"]),
                "currency": "TZS",
                "mno": meta.get("mno", ""),
            }
        )
    return rows


def esim_quote(*, plan_id: str = "esim-7d-5gb") -> dict | None:
    meta = ESIM_PLANS.get(plan_id)
    if not meta:
        return None
    return {
        "plan_id": plan_id,
        "plan_name": meta["plan_name"],
        "data_gb": meta["data_gb"],
        "days": meta["days"],
        "price_minor": int(meta["price_minor"]),
        "currency": "TZS",
        "mno": meta.get("mno", ""),
    }


def provision_esim_order(
    *,
    owner: str,
    trip: TourismTrip | None,
    plan_id: str,
    payment_ref: str,
) -> Any:
    from .models import TourismEsimOrder, TourismEsimOrderStatus

    quote = esim_quote(plan_id=plan_id)
    if not quote:
        raise TourismError("unknown esim plan")
    code = f"TAIFA-{payment_ref[:8].upper()}"
    smdp = "smdp.taifa-connect.example"
    qr_payload = f"LPA:1${smdp}${code}"
    return TourismEsimOrder.objects.create(
        owner=owner,
        trip=trip,
        plan_id=plan_id,
        plan_name=quote["plan_name"],
        data_gb=quote["data_gb"],
        days=quote["days"],
        price_minor=quote["price_minor"],
        currency="TZS",
        status=TourismEsimOrderStatus.PROVISIONED,
        activation_code=code,
        qr_payload=qr_payload,
        payment_ref=payment_ref,
    )


def esim_order_to_dict(order) -> dict:
    return {
        "id": str(order.id),
        "trip_id": str(order.trip_id) if order.trip_id else None,
        "plan_id": order.plan_id,
        "plan_name": order.plan_name,
        "data_gb": order.data_gb,
        "days": order.days,
        "price_minor": int(order.price_minor),
        "currency": order.currency,
        "status": order.status,
        "activation_code": order.activation_code,
        "qr_payload": order.qr_payload,
        "payment_ref": order.payment_ref or None,
        "created_at": order.created_at.isoformat(),
        "model_version": "tourism.esim.order.v1",
    }


def travel_insurance_quote(*, trip: TourismTrip, plan_id: str = "ins-travel") -> dict | None:
    plan = TRAVEL_INSURANCE_PLANS.get(plan_id)
    if not plan:
        return None
    guests = max(1, trip.party_size or 1)
    premium = int(plan["premium_minor_per_guest"]) * guests
    return {
        "plan_id": plan_id,
        "plan_name": plan["plan_name"],
        "provider": plan["provider"],
        "category": plan["category"],
        "premium_minor": premium,
        "coverage_minor": int(plan["coverage_minor"]),
        "currency": "TZS",
    }


def _booking_paid(status: str, payment_ref: str) -> bool:
    st = (status or "").lower()
    if st == "paid":
        return True
    return bool((payment_ref or "").strip()) and st in {"paid", "ticketed", "deposit_paid"}


def build_trip_cart(
    *,
    trip: TourismTrip,
    include_insurance_quote: bool = True,
    include_esim_quote: bool = True,
    esim_plan_id: str = "esim-7d-5gb",
) -> dict:
    from commerce.models import StayBooking, TourBooking

    lines: list[dict[str, Any]] = []
    travel_subtotal = 0

    for bid in trip.tour_booking_ids or []:
        try:
            b = TourBooking.objects.get(pk=bid, owner=trip.owner)
        except TourBooking.DoesNotExist:
            continue
        paid = _booking_paid(b.status, b.payment_ref)
        lines.append(
            {
                "section": "travel",
                "kind": "tour",
                "ref_id": str(b.id),
                "title": b.tour_title,
                "amount_minor": int(b.total_minor),
                "currency": b.currency,
                "status": b.status,
                "paid": paid,
            }
        )
        if not paid:
            travel_subtotal += int(b.total_minor)

    for bid in trip.stay_booking_ids or []:
        try:
            b = StayBooking.objects.get(pk=bid, owner=trip.owner)
        except StayBooking.DoesNotExist:
            continue
        paid = _booking_paid(b.status, b.payment_ref)
        lines.append(
            {
                "section": "travel",
                "kind": "stay",
                "ref_id": str(b.id),
                "title": f"{b.hotel_name} · {b.room_name}",
                "amount_minor": int(b.total_minor),
                "currency": b.currency,
                "status": b.status,
                "paid": paid,
            }
        )
        if not paid:
            travel_subtotal += int(b.total_minor)

    protection_subtotal = 0
    insurance_quote = None
    if include_insurance_quote:
        insurance_quote = travel_insurance_quote(trip=trip)
        if insurance_quote:
            protection_subtotal = int(insurance_quote["premium_minor"])
            lines.append(
                {
                    "section": "protection",
                    "kind": "insurance_quote",
                    "ref_id": insurance_quote["plan_id"],
                    "title": insurance_quote["plan_name"],
                    "amount_minor": protection_subtotal,
                    "currency": insurance_quote["currency"],
                    "optional": True,
                    "provider": insurance_quote["provider"],
                    "coverage_minor": insurance_quote["coverage_minor"],
                }
            )

    connectivity_subtotal = 0
    esim_quote_data = None
    if include_esim_quote:
        esim_quote_data = esim_quote(plan_id=esim_plan_id)
        if esim_quote_data:
            connectivity_subtotal = int(esim_quote_data["price_minor"])
            lines.append(
                {
                    "section": "connectivity",
                    "kind": "esim_quote",
                    "ref_id": esim_quote_data["plan_id"],
                    "title": esim_quote_data["plan_name"],
                    "amount_minor": connectivity_subtotal,
                    "currency": esim_quote_data["currency"],
                    "optional": True,
                    "data_gb": esim_quote_data["data_gb"],
                    "days": esim_quote_data["days"],
                    "mno": esim_quote_data.get("mno", ""),
                }
            )

    return {
        "trip_id": str(trip.id),
        "lines": lines,
        "travel_subtotal_minor": travel_subtotal,
        "protection_subtotal_minor": protection_subtotal,
        "connectivity_subtotal_minor": connectivity_subtotal,
        "insurance_quote": insurance_quote,
        "esim_quote": esim_quote_data,
        "total_minor": travel_subtotal + protection_subtotal + connectivity_subtotal,
        "currency": "TZS",
        "model_version": "tourism.cart.v2",
    }


@transaction.atomic
def create_trip_checkout(
    *,
    trip: TourismTrip,
    include_insurance: bool = False,
    insurance_plan_id: str = "ins-travel",
    include_esim: bool = False,
    esim_plan_id: str = "esim-7d-5gb",
) -> tuple[Any, dict]:
    from .models import TourismCheckout, TourismCheckoutStatus

    cart = build_trip_cart(
        trip=trip,
        include_insurance_quote=True,
        include_esim_quote=True,
        esim_plan_id=esim_plan_id,
    )
    travel_subtotal = int(cart["travel_subtotal_minor"])
    protection_subtotal = 0
    connectivity_subtotal = 0
    quote = cart.get("insurance_quote")
    esim_q = cart.get("esim_quote")
    inc_insurance = bool(include_insurance and quote)
    inc_esim = bool(include_esim and esim_q)
    if inc_insurance and quote:
        protection_subtotal = int(quote["premium_minor"])
    if inc_esim and esim_q:
        connectivity_subtotal = int(esim_q["price_minor"])

    total = travel_subtotal + protection_subtotal + connectivity_subtotal
    if total <= 0 and not inc_insurance and not inc_esim:
        raise TourismError("nothing to checkout — add bookings or add-ons")

    lines = list(cart["lines"])
    if not inc_insurance:
        lines = [ln for ln in lines if ln.get("section") != "protection"]
    if not inc_esim:
        lines = [ln for ln in lines if ln.get("section") != "connectivity"]

    checkout, _ = TourismCheckout.objects.update_or_create(
        trip=trip,
        defaults={
            "owner": trip.owner,
            "status": TourismCheckoutStatus.READY,
            "include_insurance": inc_insurance,
            "insurance_plan_id": quote["plan_id"] if inc_insurance and quote else "",
            "insurance_plan_name": quote["plan_name"] if inc_insurance and quote else "",
            "insurance_provider": quote["provider"] if inc_insurance and quote else "",
            "insurance_premium_minor": protection_subtotal if inc_insurance else 0,
            "insurance_coverage_minor": int(quote["coverage_minor"]) if inc_insurance and quote else 0,
            "include_esim": inc_esim,
            "esim_plan_id": esim_q["plan_id"] if inc_esim and esim_q else "",
            "esim_plan_name": esim_q["plan_name"] if inc_esim and esim_q else "",
            "esim_price_minor": connectivity_subtotal if inc_esim else 0,
            "travel_subtotal_minor": travel_subtotal,
            "protection_subtotal_minor": protection_subtotal,
            "connectivity_subtotal_minor": connectivity_subtotal,
            "total_minor": total,
            "currency": "TZS",
            "lines": lines,
            "payment_ref": "",
        },
    )
    if checkout.status == TourismCheckoutStatus.PAID:
        raise TourismError("checkout already paid")

    return checkout, checkout_to_dict(checkout)


@transaction.atomic
def pay_trip_checkout(
    *,
    trip: TourismTrip,
    owner: str,
    actor: str,
    idempotency_key: str,
) -> Any:
    from commerce.models import InsurancePolicy, StayBooking, TourBooking
    from commerce.services import ensure_platform_commerce_merchant
    from enterprise.orchestrator import PlatformContext, PlatformError, default_platform
    from payments.money import Currency, Money

    from .models import TourismCheckout, TourismCheckoutStatus

    try:
        checkout = TourismCheckout.objects.select_for_update().get(trip=trip, owner=owner)
    except TourismCheckout.DoesNotExist as exc:
        raise TourismError("checkout not found — POST checkout first") from exc

    if checkout.status == TourismCheckoutStatus.PAID and checkout.payment_ref:
        return checkout

    total = int(checkout.total_minor)
    if total <= 0:
        raise TourismError("checkout total must be positive")

    currency = Currency.from_code(checkout.currency or "TZS")
    merchant = ensure_platform_commerce_merchant(sector="tourism")
    try:
        txn = default_platform().capture_merchant_payment(
            ctx=PlatformContext(actor=actor),
            merchant=merchant,
            payer_owner=owner,
            amount=Money(total, currency),
            idempotency_key=idempotency_key,
            note=f"Tourism unified checkout trip {trip.id}",
        )
    except PlatformError as exc:
        raise TourismError(str(exc)) from exc

    payment_ref = str(txn.id)

    for bid in trip.tour_booking_ids or []:
        try:
            b = TourBooking.objects.select_for_update().get(pk=bid, owner=owner)
        except TourBooking.DoesNotExist:
            continue
        if _booking_paid(b.status, b.payment_ref):
            continue
        b.payment_ref = payment_ref
        b.status = "paid"
        b.save(update_fields=["payment_ref", "status", "updated_at"])

    for bid in trip.stay_booking_ids or []:
        try:
            b = StayBooking.objects.select_for_update().get(pk=bid, owner=owner)
        except StayBooking.DoesNotExist:
            continue
        if _booking_paid(b.status, b.payment_ref):
            continue
        b.payment_ref = payment_ref
        b.status = "paid"
        b.save(update_fields=["payment_ref", "status", "updated_at"])

    policy_id = None
    if checkout.include_insurance and checkout.insurance_premium_minor > 0:
        policy = InsurancePolicy.objects.create(
            owner=owner,
            plan_id=checkout.insurance_plan_id or "ins-travel",
            plan_name=checkout.insurance_plan_name or "Safari Travel Cover",
            provider=checkout.insurance_provider or "",
            category="Travel",
            premium_minor=int(checkout.insurance_premium_minor),
            coverage_minor=int(checkout.insurance_coverage_minor),
            currency=checkout.currency,
            policy_ref=f"TRV-{payment_ref[:12]}",
        )
        policy_id = policy.id
        checkout.insurance_policy_id = policy_id

    if checkout.include_esim and checkout.esim_price_minor > 0:
        order = provision_esim_order(
            owner=owner,
            trip=trip,
            plan_id=checkout.esim_plan_id or "esim-7d-5gb",
            payment_ref=payment_ref,
        )
        checkout.esim_order_id = order.id

    checkout.payment_ref = payment_ref
    checkout.status = TourismCheckoutStatus.PAID
    checkout.save(
        update_fields=[
            "payment_ref",
            "status",
            "insurance_policy_id",
            "esim_order_id",
            "updated_at",
        ]
    )

    trip.status = TourismTripStatus.ACTIVE
    trip.save(update_fields=["status", "updated_at"])
    return checkout


def checkout_to_dict(checkout) -> dict:
    return {
        "id": str(checkout.id),
        "trip_id": str(checkout.trip_id),
        "status": checkout.status,
        "include_insurance": checkout.include_insurance,
        "insurance_plan_id": checkout.insurance_plan_id or None,
        "insurance_policy_id": str(checkout.insurance_policy_id)
        if checkout.insurance_policy_id
        else None,
        "include_esim": checkout.include_esim,
        "esim_plan_id": checkout.esim_plan_id or None,
        "esim_order_id": str(checkout.esim_order_id) if checkout.esim_order_id else None,
        "travel_subtotal_minor": int(checkout.travel_subtotal_minor),
        "protection_subtotal_minor": int(checkout.protection_subtotal_minor),
        "connectivity_subtotal_minor": int(checkout.connectivity_subtotal_minor),
        "total_minor": int(checkout.total_minor),
        "currency": checkout.currency,
        "lines": checkout.lines or [],
        "payment_ref": checkout.payment_ref or None,
        "created_at": checkout.created_at.isoformat(),
        "updated_at": checkout.updated_at.isoformat(),
        "model_version": "tourism.checkout.v2",
    }
