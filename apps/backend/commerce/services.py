"""Commerce payment collection — money truth only via Taifa Payments/Enterprise.

Clients must never set status=paid or payment_ref. Dedicated /pay endpoints
call capture_merchant_payment and write ledger-backed references server-side.
"""
from __future__ import annotations

from django.db import transaction

from enterprise.models import Merchant, MerchantStatus
from enterprise.orchestrator import PlatformContext, PlatformError, default_platform
from payments.money import Currency, Money

from .models import (
    EduPayment,
    FlightBooking,
    FoodOrder,
    GovRequest,
    HealthAppointment,
    HousingInquiry,
    StayBooking,
    TourBooking,
    WingaOrder,
)


class CommerceError(Exception):
    pass


_PAID_STATUSES = frozenset({"paid", "payment_confirmed", "deposit_paid"})


def ensure_platform_commerce_merchant(*, sector: str = "commerce") -> Merchant:
    """Idempotent ACTIVE merchant used for Super-App commerce captures."""
    merchant, _ = Merchant.objects.get_or_create(
        code="taifa-commerce-platform",
        defaults={
            "legal_name": "Taifa Commerce Platform",
            "trading_name": "TAIFA Commerce",
            "status": MerchantStatus.ACTIVE,
            "fee_bps": 150,
            "tax_bps": 0,
            "commission_bps": 0,
            "sector": sector,
            "owner_principal": "system:commerce",
        },
    )
    if merchant.status != MerchantStatus.ACTIVE:
        merchant.status = MerchantStatus.ACTIVE
        merchant.save(update_fields=["status", "updated_at"])
    return merchant


def reject_client_money_fields(validated: dict) -> None:
    """Raise if a PATCH body tries to forge paid state or payment_ref."""
    if "payment_ref" in validated and validated.get("payment_ref"):
        raise CommerceError(
            "payment_ref is server-authored; use POST …/pay with Idempotency-Key"
        )
    status = (validated.get("status") or "").strip().lower()
    if status in _PAID_STATUSES:
        raise CommerceError(
            f"status '{status}' cannot be set by clients; use POST …/pay"
        )


@transaction.atomic
def collect_commerce_payment(
    *,
    model,
    pk,
    owner: str,
    actor: str,
    idempotency_key: str,
    amount_field: str = "total_minor",
    paid_status: str = "paid",
    note_prefix: str = "Commerce",
):
    """Capture wallet payment for a commerce order/booking and mark paid."""
    obj = model.objects.select_for_update().get(pk=pk, owner=owner)
    existing_ref = (getattr(obj, "payment_ref", None) or "").strip()
    if existing_ref and getattr(obj, "status", "") == paid_status:
        return obj

    amount_minor = int(getattr(obj, amount_field) or 0)
    if amount_minor <= 0:
        raise CommerceError("order amount must be positive")
    currency = Currency.from_code(getattr(obj, "currency", None) or "TZS")
    merchant = ensure_platform_commerce_merchant()
    try:
        txn = default_platform().capture_merchant_payment(
            ctx=PlatformContext(actor=actor),
            merchant=merchant,
            payer_owner=owner,
            amount=Money(amount_minor, currency),
            idempotency_key=idempotency_key,
            note=f"{note_prefix} {obj.__class__.__name__} {obj.pk}",
        )
    except PlatformError as exc:
        raise CommerceError(str(exc)) from exc

    obj.payment_ref = str(txn.id)
    obj.status = paid_status
    obj.save(update_fields=["payment_ref", "status", "updated_at"])
    return obj


# Typed helpers keep call sites clear for OpenAPI/views.
def collect_food_order_payment(order_id, *, owner: str, actor: str, idempotency_key: str):
    return collect_commerce_payment(
        model=FoodOrder,
        pk=order_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        note_prefix="Food",
    )


def collect_stay_booking_payment(booking_id, *, owner: str, actor: str, idempotency_key: str):
    return collect_commerce_payment(
        model=StayBooking,
        pk=booking_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        note_prefix="Stay",
    )


def collect_flight_booking_payment(booking_id, *, owner: str, actor: str, idempotency_key: str):
    return collect_commerce_payment(
        model=FlightBooking,
        pk=booking_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        note_prefix="Flight",
    )


def collect_tour_booking_payment(booking_id, *, owner: str, actor: str, idempotency_key: str):
    return collect_commerce_payment(
        model=TourBooking,
        pk=booking_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        note_prefix="Tour",
    )


def collect_gov_request_payment(request_id, *, owner: str, actor: str, idempotency_key: str):
    return collect_commerce_payment(
        model=GovRequest,
        pk=request_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        amount_field="fee_minor",
        note_prefix="Gov",
    )


def collect_health_appointment_payment(
    appointment_id, *, owner: str, actor: str, idempotency_key: str
):
    return collect_commerce_payment(
        model=HealthAppointment,
        pk=appointment_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        amount_field="fee_minor",
        note_prefix="Health",
    )


def collect_edu_payment(payment_id, *, owner: str, actor: str, idempotency_key: str):
    return collect_commerce_payment(
        model=EduPayment,
        pk=payment_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        amount_field="amount_minor",
        note_prefix="Edu",
    )


def collect_winga_order_payment(order_id, *, owner: str, actor: str, idempotency_key: str):
    return collect_commerce_payment(
        model=WingaOrder,
        pk=order_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        note_prefix="Winga",
    )


def collect_housing_deposit_payment(
    inquiry_id, *, owner: str, actor: str, idempotency_key: str
):
    return collect_commerce_payment(
        model=HousingInquiry,
        pk=inquiry_id,
        owner=owner,
        actor=actor,
        idempotency_key=idempotency_key,
        amount_field="deposit_minor",
        paid_status="deposit_paid",
        note_prefix="HousingDeposit",
    )
