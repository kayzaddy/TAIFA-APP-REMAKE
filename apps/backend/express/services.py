"""Taifa Express orchestration — reuse commerce pay + trips delivery + POD."""
from __future__ import annotations

import math
import secrets
from decimal import Decimal
from typing import Any

from django.contrib.auth.hashers import make_password
from django.db import transaction
from django.db.models import F
from django.utils import timezone

from commerce.models import FoodOrder, FoodOrderStatus
from commerce.services import collect_food_order_payment, ensure_platform_commerce_merchant

from . import metrics
from .models import (
    ExpressOrder,
    ExpressOrderStatus,
    ExpressProduct,
    ExpressStore,
    PaymentTiming,
    SettlementStatus,
)


class ExpressError(Exception):
    pass


TIMELINE_STAGES = [
    "basket_submitted",
    "merchant_found",
    "merchant_accepted",
    "paid",
    "preparing",
    "ready",
    "rider_assigned",
    "rider_arriving",
    "picked_up",
    "on_the_way",
    "arriving",
    "delivered",
    "completed",
]


def _haversine_m(lat1, lng1, lat2, lng2) -> float:
    r = 6371000.0
    p1, p2 = math.radians(float(lat1)), math.radians(float(lat2))
    dphi = math.radians(float(lat2) - float(lat1))
    dl = math.radians(float(lng2) - float(lng1))
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def _append_timeline(order: ExpressOrder, event: str, **extra) -> list:
    timeline = list(order.timeline or [])
    entry = {"at": timezone.now().isoformat(), "event": event, **extra}
    timeline.append(entry)
    order.timeline = timeline
    return timeline


def delivery_fee_minor(*, distance_m: float, urgency: str = "standard") -> int:
    base = 1500
    per_km = 800
    fee = base + int((distance_m / 1000.0) * per_km)
    if urgency == "express":
        fee = int(fee * 1.35)
    return max(1000, fee)


def platform_fee_minor(*, subtotal_minor: int) -> int:
    return max(200, int(subtotal_minor * 0.02))


def rank_stores(
    *,
    customer_lat: float,
    customer_lng: float,
    product_names: list[str] | None = None,
    category: str = "",
    limit: int = 10,
) -> list[dict[str, Any]]:
    qs = ExpressStore.objects.filter(active=True)
    if category:
        qs = qs.filter(category=category)
    ranked: list[dict[str, Any]] = []
    names = [n.lower() for n in (product_names or [])]
    for store in qs:
        dist = _haversine_m(customer_lat, customer_lng, store.lat, store.lng)
        if dist > store.delivery_radius_m:
            continue
        products = list(store.products.filter(active=True))
        coverage = 1.0
        if names:
            hit = 0
            for n in names:
                if any(n in p.name.lower() or n in " ".join(p.tags).lower() for p in products):
                    hit += 1
            coverage = hit / max(1, len(names))
            if coverage == 0:
                continue
        score = (
            (dist / 1000.0) * 2.0
            + float(store.prep_minutes) * 0.15
            + (1.0 - float(store.rating) / 5.0) * 3.0
            + (1.0 - float(store.reliability)) * 2.0
            + store.workload * 0.2
            + (1.0 - coverage) * 5.0
        )
        ranked.append(
            {
                "store_id": str(store.id),
                "code": store.code,
                "name": store.name,
                "category": store.category,
                "distance_m": int(dist),
                "prep_minutes": store.prep_minutes,
                "rating": float(store.rating),
                "eta_minutes": int(store.prep_minutes + dist / 250.0),
                "coverage": round(coverage, 2),
                "score": round(score, 3),
            }
        )
    ranked.sort(key=lambda x: x["score"])
    return ranked[:limit]


def search_products(*, query: str = "", category: str = "", limit: int = 40) -> list[ExpressProduct]:
    qs = ExpressProduct.objects.filter(active=True, store__active=True).select_related("store")
    if category:
        qs = qs.filter(store__category=category)
    if query:
        qs = qs.filter(name__icontains=query.strip())
    return list(qs[:limit])


def ai_build_basket(*, prompt: str) -> dict[str, Any]:
    """Rule-based shopping assistant — never authorizes payments."""
    metrics.ai_assists.inc()
    p = (prompt or "").lower()
    suggestions: list[dict[str, str | int]] = []
    catalog = {
        "breakfast": [("Milk", 2), ("Bread", 1), ("Eggs", 1), ("Butter", 1)],
        "chapati": [("Flour", 1), ("Oil", 1), ("Salt", 1), ("Onions", 1)],
        "pilau": [("Rice", 1), ("Chicken", 1), ("Onions", 1), ("Oil", 1), ("Salt", 1)],
        "dinner": [("Rice", 1), ("Chicken", 1), ("Tomatoes", 1), ("Onions", 1), ("Cooking oil", 1)],
        "weekly": [
            ("Milk", 3),
            ("Bread", 2),
            ("Rice", 1),
            ("Soap", 1),
            ("Eggs", 2),
            ("Sugar", 1),
            ("Tea", 1),
        ],
        "cleaning": [("Soap", 2), ("Detergent", 1), ("Sponge", 1)],
        "baby": [("Diapers", 1), ("Baby wipes", 1), ("Formula", 1)],
    }
    matched = None
    for key, items in catalog.items():
        if key in p or (key == "weekly" and "grocery" in p):
            matched = key
            suggestions = [{"name": n, "qty": q} for n, q in items]
            break
    if not suggestions:
        for word in p.replace(",", " ").split():
            if len(word) < 3:
                continue
            for prod in ExpressProduct.objects.filter(name__icontains=word, active=True)[:3]:
                suggestions.append({"name": prod.name, "qty": 1, "sku": prod.sku})
        if not suggestions:
            suggestions = [{"name": "Milk", "qty": 1}, {"name": "Bread", "qty": 1}]
            matched = "defaults"
    return {
        "prompt": prompt,
        "theme": matched or "custom",
        "items": suggestions,
        "disclaimer": "AI suggests a basket only. You must review and pay — AI never authorizes payments.",
    }


def _resolve_lines(store: ExpressStore, items: list[dict]) -> list[dict]:
    lines: list[dict] = []
    for item in items:
        name = (item.get("name") or "").strip()
        qty = int(item.get("qty") or item.get("quantity") or 1)
        product = None
        if item.get("product_id"):
            product = ExpressProduct.objects.filter(
                id=item["product_id"], store=store, active=True
            ).first()
        if product is None and name:
            product = ExpressProduct.objects.filter(
                store=store, active=True, name__icontains=name
            ).first()
        if product is None:
            raise ExpressError(f"product not available at store: {name or item}")
        if product.stock_qty < qty:
            raise ExpressError(f"insufficient stock: {product.name}")
        lines.append(
            {
                "product_id": str(product.id),
                "sku": product.sku,
                "name": product.name,
                "qty": qty,
                "unit_price_minor": product.price_minor,
                "line_total_minor": product.price_minor * qty,
            }
        )
    return lines


def _merge_lines(lines: list[dict]) -> list[dict]:
    merged: dict[str, dict] = {}
    for line in lines:
        key = line["product_id"]
        if key in merged:
            merged[key]["qty"] += line["qty"]
            merged[key]["line_total_minor"] = (
                merged[key]["qty"] * merged[key]["unit_price_minor"]
            )
        else:
            merged[key] = dict(line)
    return list(merged.values())


def _packing_checklist(lines: list[dict]) -> list[dict]:
    return [
        {
            "sku": line["sku"],
            "name": line["name"],
            "qty": line["qty"],
            "packed": False,
        }
        for line in lines
    ]


def build_settlement_plan(order: ExpressOrder) -> dict[str, Any]:
    """Allocate customer payment across merchant / rider / platform — ledger capture stays single.

    Actual money movement remains capture_merchant_payment via commerce.
    This plan is the Express settlement control record for ops + future payout execution
    via enterprise.create_settlement / trip earnings — never a second ledger.
    """
    merchant_minor = int(order.subtotal_minor)
    rider_minor = int(order.delivery_fee_minor)
    platform_minor = int(order.platform_fee_minor)
    return {
        "currency": order.currency,
        "customer_paid_minor": int(order.total_minor),
        "payment_ref": order.payment_ref,
        "allocations": [
            {
                "party": "merchant",
                "store_code": order.store.code if order.store else "",
                "amount_minor": merchant_minor,
                "note": "goods",
            },
            {
                "party": "rider",
                "amount_minor": rider_minor,
                "note": "delivery fee → mobility earnings",
            },
            {
                "party": "platform",
                "amount_minor": platform_minor,
                "note": "Taifa Express commission",
            },
        ],
        "status": SettlementStatus.ALLOCATED,
        "allocated_at": timezone.now().isoformat(),
    }


def quote_fulfillment(
    *,
    items: list[dict],
    customer_lat: float,
    customer_lng: float,
    urgency: str = "standard",
    category: str = "",
) -> dict[str, Any]:
    """Preview merchant ranking + fees without creating an order."""
    names = [str(i.get("name") or "") for i in items if i.get("name")]
    ranking = rank_stores(
        customer_lat=customer_lat,
        customer_lng=customer_lng,
        product_names=names,
        category=category,
    )
    if not ranking:
        raise ExpressError("no nearby merchants with inventory")
    store = ExpressStore.objects.get(id=ranking[0]["store_id"])
    lines = _merge_lines(_resolve_lines(store, items))
    subtotal = sum(l["line_total_minor"] for l in lines)
    dist = _haversine_m(customer_lat, customer_lng, store.lat, store.lng)
    delivery = delivery_fee_minor(distance_m=dist, urgency=urgency)
    platform = platform_fee_minor(subtotal_minor=subtotal)
    return {
        "store": ranking[0],
        "ranking": ranking[:5],
        "lines": lines,
        "subtotal_minor": subtotal,
        "delivery_fee_minor": delivery,
        "platform_fee_minor": platform,
        "total_minor": subtotal + delivery + platform,
        "eta_minutes": int(store.prep_minutes + dist / 250.0),
        "currency": "TZS",
    }


@transaction.atomic
def create_order(
    *,
    owner: str,
    items: list[dict],
    customer_lat: float,
    customer_lng: float,
    customer_address: str = "",
    customer_phone: str = "",
    customer_notes: str = "",
    store_id: str | None = None,
    urgency: str = "standard",
    ai_prompt: str = "",
    payment_timing: str = PaymentTiming.PREPAID,
    payment_method: str = "wallet",
    promo_code: str = "",
) -> ExpressOrder:
    names = [str(i.get("name") or "") for i in items if i.get("name")]
    ranking = rank_stores(
        customer_lat=customer_lat,
        customer_lng=customer_lng,
        product_names=names,
    )
    if not ranking and not store_id:
        raise ExpressError("no nearby merchants with inventory")

    if store_id:
        store = ExpressStore.objects.filter(id=store_id, active=True).first()
        if store is None:
            raise ExpressError("store not found")
    else:
        store = ExpressStore.objects.get(id=ranking[0]["store_id"])

    lines = _merge_lines(_resolve_lines(store, items))
    subtotal = sum(l["line_total_minor"] for l in lines)
    dist = _haversine_m(customer_lat, customer_lng, store.lat, store.lng)
    fee = delivery_fee_minor(distance_m=dist, urgency=urgency)
    pfee = platform_fee_minor(subtotal_minor=subtotal)
    eta = int(store.prep_minutes + dist / 250.0)
    pin = f"{secrets.randbelow(10**6):06d}"

    order = ExpressOrder.objects.create(
        owner=owner,
        status=ExpressOrderStatus.MERCHANT_FOUND,
        store=store,
        lines=lines,
        packing_checklist=_packing_checklist(lines),
        subtotal_minor=subtotal,
        delivery_fee_minor=fee,
        platform_fee_minor=pfee,
        total_minor=subtotal + fee + pfee,
        urgency=urgency,
        payment_timing=payment_timing,
        payment_method=payment_method,
        customer_lat=Decimal(str(customer_lat)),
        customer_lng=Decimal(str(customer_lng)),
        customer_address=customer_address,
        customer_phone=customer_phone,
        customer_notes=customer_notes,
        promo_code=promo_code,
        ranking=ranking[:5],
        eta_minutes=eta,
        ai_prompt=ai_prompt,
        delivery_pin=pin,
        timeline=[
            {
                "at": timezone.now().isoformat(),
                "event": "basket_submitted",
            },
            {
                "at": timezone.now().isoformat(),
                "event": "merchant_found",
                "store": store.code,
                "store_name": store.name,
            },
        ],
    )
    metrics.orders_created.inc()
    return order


@transaction.atomic
def merchant_accept(*, order: ExpressOrder, actor: str = "") -> ExpressOrder:
    if order.status not in (
        ExpressOrderStatus.PLACED,
        ExpressOrderStatus.RANKED,
        ExpressOrderStatus.MERCHANT_FOUND,
    ):
        raise ExpressError("order not acceptable")
    order.status = ExpressOrderStatus.MERCHANT_ACCEPTED
    _append_timeline(order, "merchant_accepted", actor=actor)
    order.save(update_fields=["status", "timeline", "updated_at"])
    return order


@transaction.atomic
def pay_order(
    *,
    order: ExpressOrder,
    owner: str,
    idempotency_key: str,
    actor: str = "",
) -> ExpressOrder:
    if order.payment_ref:
        return order
    if order.status == ExpressOrderStatus.CANCELLED:
        raise ExpressError("order cancelled")
    if order.payment_timing == PaymentTiming.ON_DELIVERY:
        raise ExpressError("pay on delivery — capture at delivery via Tap/MAP")

    ensure_platform_commerce_merchant(sector="express")
    store = order.store
    if store is None:
        raise ExpressError("order missing store")

    food = FoodOrder.objects.create(
        owner=owner,
        status=FoodOrderStatus.CONFIRMED,
        restaurant_id=store.code,
        restaurant_name=store.name,
        subtotal_minor=order.subtotal_minor,
        delivery_fee_minor=order.delivery_fee_minor + order.platform_fee_minor,
        total_minor=order.total_minor,
        currency=order.currency,
    )
    try:
        food = collect_food_order_payment(
            food.id,
            owner=owner,
            actor=actor or owner,
            idempotency_key=idempotency_key,
        )
    except Exception as exc:
        FoodOrder.objects.filter(pk=food.id).update(status=FoodOrderStatus.CANCELLED)
        raise ExpressError(str(exc)) from exc

    order.food_order_id = food.id
    order.payment_ref = food.payment_ref
    order.settlement_plan = build_settlement_plan(order)
    order.settlement_status = SettlementStatus.ALLOCATED
    order.status = ExpressOrderStatus.PREPARING
    _append_timeline(order, "paid", payment_ref=order.payment_ref)
    _append_timeline(order, "preparing")
    _append_timeline(
        order,
        "settlement_allocated",
        plan=order.settlement_plan.get("allocations"),
    )
    order.save(
        update_fields=[
            "food_order_id",
            "payment_ref",
            "settlement_plan",
            "settlement_status",
            "status",
            "timeline",
            "updated_at",
        ]
    )
    for line in order.lines:
        ExpressProduct.objects.filter(id=line["product_id"]).update(
            stock_qty=F("stock_qty") - int(line["qty"])
        )
    metrics.orders_paid.inc()
    return order


def _attach_delivery_pod(*, order: ExpressOrder, trip) -> None:
    from trips.models import Delivery

    if order.delivery_id:
        return
    pin = order.delivery_pin or f"{secrets.randbelow(10**6):06d}"
    if not order.delivery_pin:
        order.delivery_pin = pin
    notes = f"Express {order.public_code} · package {order.package_code}"
    if order.customer_notes:
        notes = f"{notes} · {order.customer_notes}"[:500]
    delivery = Delivery.objects.create(
        trip=trip,
        category="package",
        recipient_name=order.customer_address or order.owner[:64] or "Customer",
        recipient_phone_masked=(order.customer_phone or "****")[:32],
        verification_hash=make_password(pin),
        package_notes=notes,
    )
    order.delivery_id = delivery.id


def request_delivery(*, order: ExpressOrder, actor: str = "") -> ExpressOrder:
    """Create mobility delivery trip after merchant READY — best-effort if no drivers."""
    prepaid_ok = bool(order.payment_ref)
    cod_ok = order.payment_timing == PaymentTiming.ON_DELIVERY
    if not prepaid_ok and not cod_ok:
        raise ExpressError("order must be paid before delivery")
    if order.trip_id:
        return order
    if order.status not in (
        ExpressOrderStatus.READY,
        ExpressOrderStatus.PREPARING,
        ExpressOrderStatus.PAID,
        ExpressOrderStatus.MERCHANT_ACCEPTED,
    ):
        # Allow retry from ready/preparing
        pass
    store = order.store
    if store is None:
        raise ExpressError("missing store")

    from trips.models import TripKind
    from trips.services import MobilityError, create_trip, dispatch_trip

    try:
        trip = create_trip(
            owner=order.owner,
            pickup_name=store.name,
            pickup_lat=store.lat,
            pickup_lng=store.lng,
            dropoff_name=order.customer_address or "Customer",
            dropoff_lat=order.customer_lat,
            dropoff_lng=order.customer_lng,
            vehicle_mode="delivery_bike",
            kind=TripKind.DELIVERY,
            estimated_distance_meters=max(
                500,
                int(
                    _haversine_m(
                        store.lat, store.lng, order.customer_lat, order.customer_lng
                    )
                ),
            ),
            estimated_duration_seconds=max(300, order.eta_minutes * 60),
            actor=actor or order.owner,
        )
        try:
            dispatch_trip(trip.id, actor=actor or "express")
        except MobilityError:
            pass
        order.trip_id = trip.id
        _attach_delivery_pod(order=order, trip=trip)
        order.status = ExpressOrderStatus.RIDER_ASSIGNED
        _append_timeline(
            order,
            "rider_assigned",
            trip_id=str(trip.id),
            delivery_id=str(order.delivery_id) if order.delivery_id else "",
            package_code=order.package_code,
        )
        order.save(
            update_fields=[
                "trip_id",
                "delivery_id",
                "delivery_pin",
                "status",
                "timeline",
                "updated_at",
            ]
        )
        metrics.deliveries_requested.inc()
    except MobilityError as exc:
        _append_timeline(order, "delivery_pending", detail=str(exc))
        order.status = ExpressOrderStatus.READY
        order.save(update_fields=["timeline", "status", "updated_at"])
    return order


@transaction.atomic
def merchant_ready(*, order: ExpressOrder, actor: str = "") -> ExpressOrder:
    """Merchant marks package READY → auto-dispatch best rider."""
    if order.status not in (
        ExpressOrderStatus.MERCHANT_ACCEPTED,
        ExpressOrderStatus.PREPARING,
        ExpressOrderStatus.PAID,
        ExpressOrderStatus.READY,
    ):
        raise ExpressError("order not ready for dispatch")
    if order.payment_timing == PaymentTiming.PREPAID and not order.payment_ref:
        raise ExpressError("prepaid order must be paid before ready")

    checklist = list(order.packing_checklist or [])
    for row in checklist:
        row["packed"] = True
    order.packing_checklist = checklist
    order.status = ExpressOrderStatus.READY
    _append_timeline(
        order,
        "ready",
        actor=actor,
        package_code=order.package_code,
        package_qr=order.package_qr,
    )
    order.save(update_fields=["status", "packing_checklist", "timeline", "updated_at"])
    return request_delivery(order=order, actor=actor or "express-dispatch")


@transaction.atomic
def advance_fulfillment(*, order: ExpressOrder, stage: str, actor: str = "") -> ExpressOrder:
    """Advance live delivery stages (orchestration mirror of mobility)."""
    mapping = {
        "rider_arriving": ExpressOrderStatus.RIDER_ARRIVING,
        "picked_up": ExpressOrderStatus.PICKED_UP,
        "on_the_way": ExpressOrderStatus.DELIVERING,
        "delivering": ExpressOrderStatus.DELIVERING,
        "arriving": ExpressOrderStatus.ARRIVING,
        "delivered": ExpressOrderStatus.DELIVERED,
        "completed": ExpressOrderStatus.COMPLETED,
    }
    if stage not in mapping:
        raise ExpressError(f"unknown stage: {stage}")
    order.status = mapping[stage]
    event = "on_the_way" if stage in ("on_the_way", "delivering") else stage
    _append_timeline(order, event, actor=actor)
    if stage == "completed":
        order.settlement_status = SettlementStatus.SETTLED
        _append_timeline(order, "settlement_settled")
        order.save(
            update_fields=["status", "timeline", "settlement_status", "updated_at"]
        )
    else:
        order.save(update_fields=["status", "timeline", "updated_at"])
    return order


def checkout(
    *,
    owner: str,
    items: list[dict],
    customer_lat: float,
    customer_lng: float,
    customer_address: str = "",
    customer_phone: str = "",
    customer_notes: str = "",
    idempotency_key: str,
    urgency: str = "standard",
    ai_prompt: str = "",
    payment_timing: str = PaymentTiming.PREPAID,
    payment_method: str = "wallet",
    promo_code: str = "",
    auto_accept: bool = True,
    auto_ready: bool = True,
) -> ExpressOrder:
    """One-tap: find merchant → accept → pay → (optional) READY → dispatch."""
    order = create_order(
        owner=owner,
        items=items,
        customer_lat=customer_lat,
        customer_lng=customer_lng,
        customer_address=customer_address,
        customer_phone=customer_phone,
        customer_notes=customer_notes,
        urgency=urgency,
        ai_prompt=ai_prompt,
        payment_timing=payment_timing,
        payment_method=payment_method,
        promo_code=promo_code,
    )
    if auto_accept:
        merchant_accept(order=order, actor="express-auto")
    if payment_timing == PaymentTiming.PREPAID:
        order = pay_order(
            order=order, owner=owner, idempotency_key=idempotency_key, actor=owner
        )
    elif auto_accept:
        order.status = ExpressOrderStatus.PREPARING
        _append_timeline(order, "preparing", note="pay_on_delivery")
        order.save(update_fields=["status", "timeline", "updated_at"])
    if auto_ready:
        order = merchant_ready(order=order, actor="express-auto")
    return order
