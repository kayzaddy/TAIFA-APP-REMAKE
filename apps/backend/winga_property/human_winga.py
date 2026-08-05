"""Winga Property Phase 4 — human Winga assignment, CRM, chat, appointments."""
from __future__ import annotations

import uuid
from typing import Any

from django.db import transaction
from django.utils import timezone

from commerce.models import ChatMessage, ChatThread
from winga.models import BrokerageDomain, Lead, VerificationStatus, WingaProfile

from .models import (
    PropertyAppointmentStatus,
    PropertyAssignmentStatus,
    PropertyListing,
    PropertySharedDocument,
    PropertyTimelineEvent,
    PropertyTimelineEventType,
    PropertyViewingAppointment,
    PropertyWingaAssignment,
)


class HumanWingaError(Exception):
    pass


def list_property_wingas(*, limit: int = 20) -> list[WingaProfile]:
    domain = BrokerageDomain.objects.filter(code="property", active=True).first()
    qs = WingaProfile.objects.filter(
        active=True,
        verification_status=VerificationStatus.VERIFIED,
    )
    if domain:
        qs = qs.filter(domains=domain)
    return list(qs.order_by("-reputation_score_e4")[:limit])


def winga_leaderboard(*, limit: int = 10) -> list[dict[str, Any]]:
    return [
        {
            "id": str(w.id),
            "principal": w.principal,
            "display_name": w.display_name,
            "certification": w.certification,
            "reputation_score_e4": w.reputation_score_e4,
            "trust_stars": max(1, min(5, round(w.reputation_score_e4 / 2000))),
        }
        for w in list_property_wingas(limit=limit)
    ]


def _best_winga() -> WingaProfile:
    wingas = list_property_wingas(limit=1)
    if not wingas:
        raise HumanWingaError("no verified property Wingas available")
    return wingas[0]


@transaction.atomic
def assign_winga(
    *,
    listing: PropertyListing,
    customer_principal: str,
    winga: WingaProfile | None = None,
    notes: str = "",
) -> PropertyWingaAssignment:
    existing = PropertyWingaAssignment.objects.filter(
        listing=listing,
        customer_principal=customer_principal,
        status__in=[PropertyAssignmentStatus.ASSIGNED, PropertyAssignmentStatus.ACTIVE],
    ).first()
    if existing:
        return existing

    winga = winga or _best_winga()
    thread = ChatThread.objects.create(
        owner=customer_principal,
        title=f"Winga · {listing.title}",
        subtitle=f"Your advisor: {winga.display_name}",
    )
    lead = _create_lead(winga=winga, listing=listing, customer_principal=customer_principal)

    assignment = PropertyWingaAssignment.objects.create(
        listing=listing,
        customer_principal=customer_principal,
        winga_principal=winga.principal,
        winga_profile_id=winga.id,
        status=PropertyAssignmentStatus.ACTIVE,
        chat_thread_id=thread.id,
        winga_lead_id=lead.id if lead else None,
        notes=notes,
    )
    _timeline(
        assignment=assignment,
        event_type=PropertyTimelineEventType.ASSIGNED,
        title=f"Winga {winga.display_name} assigned",
        notes=notes,
        actor=customer_principal,
        metadata={"winga_id": str(winga.id)},
    )
    ChatMessage.objects.create(
        owner=customer_principal,
        thread=thread,
        sender="them",
        text=f"Hi! I'm {winga.display_name}, your Taifa property Winga. How can I help with {listing.title}?",
    )
    return assignment


def _create_lead(
    *,
    winga: WingaProfile,
    listing: PropertyListing,
    customer_principal: str,
) -> Lead | None:
    domain = BrokerageDomain.objects.filter(code="property").first()
    if not domain:
        return None
    return Lead.objects.create(
        winga=winga,
        customer_principal=customer_principal,
        domain=domain,
        title=f"Property inquiry: {listing.title}",
        notes=f"Auto-created from Winga Property assignment for listing {listing.id}",
        pipeline_stage="inquiry",
        metadata={"listing_id": str(listing.id)},
    )


def _timeline(
    *,
    assignment: PropertyWingaAssignment,
    event_type: str,
    title: str,
    notes: str = "",
    actor: str,
    metadata: dict | None = None,
) -> PropertyTimelineEvent:
    return PropertyTimelineEvent.objects.create(
        assignment=assignment,
        event_type=event_type,
        title=title,
        notes=notes,
        actor=actor,
        metadata=metadata or {},
    )


def get_customer_assignments(*, customer_principal: str, limit: int = 20) -> list[PropertyWingaAssignment]:
    return list(
        PropertyWingaAssignment.objects.filter(customer_principal=customer_principal)
        .select_related("listing")
        .order_by("-created_at")[:limit]
    )


def commission_preview(*, amount_minor: int) -> dict[str, Any]:
    domain = BrokerageDomain.objects.filter(code="property", active=True).first()
    bps = domain.default_commission_bps if domain else 500
    commission_minor = int(amount_minor * bps / 10_000)
    return {
        "amount_minor": amount_minor,
        "commission_bps": bps,
        "commission_minor": commission_minor,
        "currency": "TZS",
        "note": "Preview only — settlement via Taifa Payments when deal closes",
    }


@transaction.atomic
def share_document(
    *,
    assignment: PropertyWingaAssignment,
    title: str,
    url: str,
    shared_by: str,
) -> PropertySharedDocument:
    doc = PropertySharedDocument.objects.create(
        assignment=assignment,
        title=title,
        url=url,
        shared_by=shared_by,
    )
    _timeline(
        assignment=assignment,
        event_type=PropertyTimelineEventType.DOCUMENT,
        title=f"Document shared: {title}",
        actor=shared_by,
        metadata={"url": url, "document_id": str(doc.id)},
    )
    return doc


@transaction.atomic
def schedule_appointment(
    *,
    assignment: PropertyWingaAssignment,
    scheduled_at,
    location_notes: str = "",
    actor: str,
) -> PropertyViewingAppointment:
    appt = PropertyViewingAppointment.objects.create(
        assignment=assignment,
        scheduled_at=scheduled_at,
        status=PropertyAppointmentStatus.REQUESTED,
        location_notes=location_notes,
    )
    _timeline(
        assignment=assignment,
        event_type=PropertyTimelineEventType.APPOINTMENT,
        title="Viewing appointment requested",
        notes=location_notes,
        actor=actor,
        metadata={"appointment_id": str(appt.id), "scheduled_at": scheduled_at.isoformat()},
    )
    return appt


def list_chat_messages(*, assignment: PropertyWingaAssignment, principal: str) -> list[dict[str, Any]]:
    if principal not in {assignment.customer_principal, assignment.winga_principal}:
        raise HumanWingaError("not authorized")
    if not assignment.chat_thread_id:
        return []
    messages = ChatMessage.objects.filter(
        thread_id=assignment.chat_thread_id,
        owner=assignment.customer_principal,
    ).order_by("created_at")[:100]
    return [
        {
            "id": str(m.id),
            "sender": m.sender,
            "text": m.text,
            "created_at": m.created_at.isoformat(),
            "is_me": m.sender == "me",
        }
        for m in messages
    ]


@transaction.atomic
def post_chat_message(
    *,
    assignment: PropertyWingaAssignment,
    principal: str,
    text: str,
) -> dict[str, Any]:
    if principal not in {assignment.customer_principal, assignment.winga_principal}:
        raise HumanWingaError("not authorized")
    if not assignment.chat_thread_id:
        raise HumanWingaError("chat not initialized")
    sender = "me" if principal == assignment.customer_principal else "them"
    msg = ChatMessage.objects.create(
        owner=assignment.customer_principal,
        thread_id=assignment.chat_thread_id,
        sender=sender,
        text=text.strip(),
    )
    ChatThread.objects.filter(pk=assignment.chat_thread_id).update(updated_at=timezone.now())
    _timeline(
        assignment=assignment,
        event_type=PropertyTimelineEventType.MESSAGE,
        title="Chat message",
        notes=text[:200],
        actor=principal,
    )
    return {
        "id": str(msg.id),
        "sender": sender,
        "text": msg.text,
        "created_at": msg.created_at.isoformat(),
        "is_me": sender == "me",
    }


def winga_profile_payload(winga_id: uuid.UUID | None) -> dict[str, Any]:
    if not winga_id:
        return {}
    try:
        w = WingaProfile.objects.get(pk=winga_id)
    except WingaProfile.DoesNotExist:
        return {}
    return {
        "id": str(w.id),
        "display_name": w.display_name,
        "bio": w.bio,
        "certification": w.certification,
        "reputation_score_e4": w.reputation_score_e4,
        "trust_stars": max(1, min(5, round(w.reputation_score_e4 / 2000))),
    }
