"""Winga Property Phase 3 — virtual experience, viewing pass, live sessions."""
from __future__ import annotations

import secrets
import uuid
from datetime import timedelta
from typing import Any

from django.db import transaction
from django.utils import timezone

from commerce.services import CommerceError, ensure_platform_commerce_merchant
from enterprise.orchestrator import PlatformContext, default_platform
from payments.money import Currency, Money

from .models import (
    MediaTourKind,
    PropertyListing,
    PropertyLiveMessage,
    PropertyLiveSession,
    PropertyLiveSessionStatus,
    PropertyMedia,
    PropertyViewingPass,
    PropertyViewingPassStatus,
    TourRoomCode,
    ViewingPassPlanCode,
)


class ExperienceError(Exception):
    pass


VIEWING_PASS_PLANS: dict[str, dict[str, Any]] = {
    ViewingPassPlanCode.SINGLE: {
        "name": "Single Viewing Pass",
        "description": "Unlock one property — address, navigation, contact, scheduling",
        "amount_minor": 25_000,
        "listing_quota": 1,
        "duration_days": 7,
    },
    ViewingPassPlanCode.BUNDLE: {
        "name": "5-Property Bundle",
        "description": "Unlock up to 5 properties within 14 days",
        "amount_minor": 99_000,
        "listing_quota": 5,
        "duration_days": 14,
    },
    ViewingPassPlanCode.UNLIMITED: {
        "name": "Unlimited Pass",
        "description": "Unlimited property unlocks for 30 days",
        "amount_minor": 199_000,
        "listing_quota": 0,
        "duration_days": 30,
    },
}


def viewing_pass_plans() -> list[dict[str, Any]]:
    return [
        {"code": code, "currency": "TZS", **meta}
        for code, meta in VIEWING_PASS_PLANS.items()
    ]


def _qr_token() -> str:
    return secrets.token_urlsafe(24)


def _join_code() -> str:
    return secrets.token_hex(4).upper()


def listing_experience(*, listing: PropertyListing) -> dict[str, Any]:
    media = list(listing.media.all())
    gallery = [
        _media_payload(m)
        for m in media
        if m.tour_kind in {"", MediaTourKind.GALLERY} or m.kind == "photo"
    ]
    walkthrough: dict[str, list[dict]] = {code: [] for code, _ in TourRoomCode.choices}
    floor_plans: list[dict] = []
    video_tours: list[dict] = []
    panoramas: list[dict] = []

    for item in media:
        payload = _media_payload(item)
        if item.tour_kind == MediaTourKind.WALKTHROUGH and item.room_code:
            walkthrough.setdefault(item.room_code, []).append(payload)
        elif item.tour_kind == MediaTourKind.FLOOR_PLAN:
            floor_plans.append({**payload, "floor_plan_data": item.floor_plan_data})
        elif item.tour_kind in {MediaTourKind.VIDEO_TOUR, MediaTourKind.GUIDED_TOUR}:
            video_tours.append(payload)
        elif item.tour_kind == MediaTourKind.PANORAMA_360:
            panoramas.append({**payload, "panorama_url": item.panorama_url or item.url})

    rooms = [
        {"room_code": code, "label": label, "media": walkthrough.get(code, [])}
        for code, label in TourRoomCode.choices
        if walkthrough.get(code)
    ]

    return {
        "listing_id": str(listing.id),
        "gallery": gallery,
        "walkthrough": rooms,
        "video_tours": video_tours,
        "floor_plans": floor_plans,
        "panoramas_360": panoramas,
        "vr_ready": any(panoramas),
        "model_version": "winga_property.experience.v1",
    }


def _media_payload(media: PropertyMedia) -> dict[str, Any]:
    return {
        "id": str(media.id),
        "kind": media.kind,
        "tour_kind": media.tour_kind or MediaTourKind.GALLERY,
        "room_code": media.room_code,
        "url": media.url,
        "caption": media.caption,
        "is_hd": media.is_hd,
        "duration_seconds": media.duration_seconds,
    }


def has_listing_unlock(*, principal: str, listing_id: uuid.UUID) -> bool:
    now = timezone.now()
    listing_key = str(listing_id)
    for pass_row in PropertyViewingPass.objects.filter(
        principal=principal,
        status=PropertyViewingPassStatus.ACTIVE,
    ):
        if pass_row.expires_at and pass_row.expires_at < now:
            continue
        if pass_row.plan_code == ViewingPassPlanCode.UNLIMITED:
            return True
        if pass_row.listing_id == listing_id:
            return True
        if listing_key in (pass_row.listings_unlocked or []):
            return True
    return False


@transaction.atomic
def create_viewing_pass(
    *,
    principal: str,
    plan_code: str,
    listing_id: uuid.UUID | None = None,
) -> PropertyViewingPass:
    if plan_code not in VIEWING_PASS_PLANS:
        raise ExperienceError(f"unknown plan {plan_code}")
    listing = None
    if plan_code == ViewingPassPlanCode.SINGLE:
        if listing_id is None:
            raise ExperienceError("listing_id required for single pass")
        listing = PropertyListing.objects.get(pk=listing_id, active=True)
    return PropertyViewingPass.objects.create(
        principal=principal,
        listing=listing,
        plan_code=plan_code,
        amount_minor=VIEWING_PASS_PLANS[plan_code]["amount_minor"],
        currency="TZS",
        qr_token=_qr_token(),
        status=PropertyViewingPassStatus.PENDING_PAYMENT,
    )


@transaction.atomic
def collect_viewing_pass_payment(
    *,
    pass_id: uuid.UUID,
    principal: str,
    actor: str,
    idempotency_key: str,
) -> PropertyViewingPass:
    row = PropertyViewingPass.objects.select_for_update().get(pk=pass_id, principal=principal)
    if row.status == PropertyViewingPassStatus.ACTIVE and row.payment_ref:
        return row
    if row.status != PropertyViewingPassStatus.PENDING_PAYMENT:
        raise ExperienceError(f"cannot pay pass in status {row.status}")

    plan = VIEWING_PASS_PLANS[row.plan_code]
    merchant = ensure_platform_commerce_merchant(sector="winga_property")
    try:
        txn = default_platform().capture_merchant_payment(
            ctx=PlatformContext(actor=actor),
            merchant=merchant,
            payer_owner=principal,
            amount=Money(row.amount_minor, Currency.from_code(row.currency)),
            idempotency_key=idempotency_key,
            note=f"WingaProperty ViewingPass {row.pk}",
        )
    except Exception as exc:
        raise CommerceError(str(exc)) from exc

    row.payment_ref = str(txn.id)
    row.status = PropertyViewingPassStatus.ACTIVE
    row.unlock_address = True
    row.unlock_navigation = True
    row.unlock_contact = True
    row.unlock_scheduling = True
    row.expires_at = timezone.now() + timedelta(days=plan["duration_days"])
    if row.listing_id:
        row.listings_unlocked = [str(row.listing_id)]
    row.save()
    _notify_pass_activated(row)
    return row


def activate_listing_on_pass(*, pass_row: PropertyViewingPass, listing_id: uuid.UUID) -> PropertyViewingPass:
    if pass_row.status != PropertyViewingPassStatus.ACTIVE:
        raise ExperienceError("pass is not active")
    listing_key = str(listing_id)
    unlocked = list(pass_row.listings_unlocked or [])
    if listing_key in unlocked:
        return pass_row
    plan = VIEWING_PASS_PLANS[pass_row.plan_code]
    quota = plan["listing_quota"]
    if quota and len(unlocked) >= quota:
        raise ExperienceError("listing quota exceeded for this pass")
    unlocked.append(listing_key)
    pass_row.listings_unlocked = unlocked
    pass_row.save(update_fields=["listings_unlocked", "updated_at"])
    return pass_row


def verify_viewing_pass_qr(*, qr_token: str) -> dict[str, Any]:
    try:
        row = PropertyViewingPass.objects.select_related("listing").get(qr_token=qr_token)
    except PropertyViewingPass.DoesNotExist:
        raise ExperienceError("invalid qr token") from None
    valid = row.status == PropertyViewingPassStatus.ACTIVE
    if row.expires_at and row.expires_at < timezone.now():
        valid = False
    return {
        "valid": valid,
        "pass_id": str(row.id),
        "principal": row.principal,
        "plan_code": row.plan_code,
        "listing_id": str(row.listing_id) if row.listing_id else "",
        "expires_at": row.expires_at.isoformat() if row.expires_at else None,
    }


def _notify_pass_activated(pass_row: PropertyViewingPass) -> None:
    try:
        from integrations.notifications import NotificationNotConfigured, deliver_notification

        deliver_notification(
            channel="push",
            recipient=pass_row.principal,
            template="winga_property_viewing_pass_active",
            payload={
                "pass_id": str(pass_row.id),
                "plan_code": pass_row.plan_code,
            },
        )
    except Exception:
        pass


def _notify_live_request(session: PropertyLiveSession) -> None:
    try:
        from integrations.notifications import deliver_notification

        deliver_notification(
            channel="push",
            recipient=session.owner_principal,
            template="winga_property_live_requested",
            payload={
                "session_id": str(session.id),
                "listing_id": str(session.listing_id),
                "join_code": session.join_code,
            },
        )
    except Exception:
        pass


@transaction.atomic
def request_live_session(
    *,
    listing: PropertyListing,
    customer_principal: str,
    scheduled_at=None,
    notes: str = "",
) -> PropertyLiveSession:
    session = PropertyLiveSession.objects.create(
        listing=listing,
        customer_principal=customer_principal,
        owner_principal=listing.owner.principal,
        status=PropertyLiveSessionStatus.REQUESTED,
        scheduled_at=scheduled_at,
        appointment_notes=notes,
        join_code=_join_code(),
    )
    _notify_live_request(session)
    return session


@transaction.atomic
def schedule_live_session(
    *,
    session: PropertyLiveSession,
    scheduled_at,
    actor: str,
) -> PropertyLiveSession:
    if session.owner_principal != actor:
        raise ExperienceError("only owner can schedule")
    session.status = PropertyLiveSessionStatus.SCHEDULED
    session.scheduled_at = scheduled_at
    session.save(update_fields=["status", "scheduled_at", "updated_at"])
    return session


@transaction.atomic
def start_live_session(*, session: PropertyLiveSession, actor: str) -> PropertyLiveSession:
    if session.owner_principal != actor:
        raise ExperienceError("only owner can start live session")
    session.status = PropertyLiveSessionStatus.LIVE
    session.started_at = timezone.now()
    session.stream_url = session.stream_url or f"https://live.taifa.local/s/{session.join_code}"
    session.save(update_fields=["status", "started_at", "stream_url", "updated_at"])
    return session


@transaction.atomic
def join_live_session(*, session: PropertyLiveSession, actor: str) -> PropertyLiveSession:
    if actor not in {session.customer_principal, session.owner_principal}:
        raise ExperienceError("not authorized to join session")
    if session.status not in {
        PropertyLiveSessionStatus.REQUESTED,
        PropertyLiveSessionStatus.SCHEDULED,
        PropertyLiveSessionStatus.LIVE,
    }:
        raise ExperienceError(f"cannot join session in status {session.status}")
    if session.status in {
        PropertyLiveSessionStatus.REQUESTED,
        PropertyLiveSessionStatus.SCHEDULED,
    }:
        session.status = PropertyLiveSessionStatus.LIVE
        session.started_at = timezone.now()
        session.stream_url = session.stream_url or f"https://live.taifa.local/s/{session.join_code}"
        session.save(update_fields=["status", "started_at", "stream_url", "updated_at"])
    return session


@transaction.atomic
def end_live_session(*, session: PropertyLiveSession, actor: str) -> PropertyLiveSession:
    if actor not in {session.customer_principal, session.owner_principal}:
        raise ExperienceError("not authorized to end session")
    session.status = PropertyLiveSessionStatus.ENDED
    session.ended_at = timezone.now()
    session.recording_url = session.recording_url or f"https://recordings.taifa.local/{session.id}.mp4"
    session.ai_transcript = _build_ai_transcript(session)
    session.save(
        update_fields=["status", "ended_at", "recording_url", "ai_transcript", "updated_at"]
    )
    return session


def post_live_message(*, session: PropertyLiveSession, sender: str, body: str) -> PropertyLiveMessage:
    if session.status != PropertyLiveSessionStatus.LIVE:
        raise ExperienceError("session is not live")
    return PropertyLiveMessage.objects.create(
        session=session,
        sender_principal=sender,
        body=body.strip(),
    )


def _build_ai_transcript(session: PropertyLiveSession) -> dict[str, Any]:
    messages = list(session.messages.order_by("created_at").values("sender_principal", "body", "created_at"))
    summary = ""
    try:
        from ecosystem.ai import invoke_ai

        result = invoke_ai(
            capability_code="natural_language",
            principal=session.customer_principal,
            payload={
                "task": "summarize_live_property_tour",
                "messages": [{"from": m["sender_principal"], "text": m["body"]} for m in messages],
            },
            domain_code="winga_property",
        )
        summary = result.get("summary") or result.get("text") or ""
    except Exception:
        summary = f"Live tour with {len(messages)} messages."

    return {
        "message_count": len(messages),
        "messages": [
            {
                "sender": m["sender_principal"],
                "body": m["body"],
                "at": m["created_at"].isoformat(),
            }
            for m in messages
        ],
        "summary": summary,
        "model_version": "winga_property.live_transcript.v1",
    }
