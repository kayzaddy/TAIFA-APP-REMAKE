"""Winga Property Phase 4 — AI copilot (discovery only, no payments)."""
from __future__ import annotations

from typing import Any

from winga.ai import assist as winga_assist

from . import intelligence
from .models import PropertyListing, PropertyVerificationStatus


class CopilotError(Exception):
    pass


def property_copilot(
    *,
    query: str,
    principal: str,
    listing_id: str | None = None,
) -> dict[str, Any]:
    context: dict[str, Any] = {"query": query, "domain": "winga_property"}
    if listing_id:
        listing = PropertyListing.objects.filter(pk=listing_id, active=True).first()
        if listing:
            context["listing"] = {
                "title": listing.title,
                "price_minor": listing.price_minor,
                "beds": listing.beds,
                "location": f"{listing.ward}, {listing.district}",
            }
            context["intelligence"] = intelligence.neighborhood_intelligence(listing=listing)
            context["visit_score"] = intelligence.visit_decision_score(listing=listing)

    result = winga_assist(
        capability="natural_language",
        principal=principal,
        payload={"task": "property_copilot", **context},
    )
    answer = (
        result.get("result", {}).get("text")
        or result.get("result", {}).get("summary")
        or result.get("result", {}).get("suggestions")
        or f"I can help you evaluate properties. You asked: {query}"
    )
    if isinstance(answer, list):
        answer = "; ".join(str(a) for a in answer)
    return {
        "query": query,
        "answer": str(answer),
        "listing_id": listing_id or "",
        "payment_authorized": False,
        "model_version": "winga_property.copilot.v1",
    }


def rank_listings(*, listing_ids: list[str], principal: str) -> list[dict[str, Any]]:
    rows = PropertyListing.objects.filter(
        id__in=listing_ids[:20],
        active=True,
        verification_status=PropertyVerificationStatus.VERIFIED,
    )
    ranked = []
    for listing in rows:
        visit = intelligence.visit_decision_score(listing=listing)
        intel = intelligence.neighborhood_intelligence(listing=listing)
        ranked.append(
            {
                "listing_id": str(listing.id),
                "title": listing.title,
                "rank_score_e4": visit["score_e4"],
                "visit_stars": visit["stars"],
                "safety_e4": intel["safety_score_e4"],
                "price_minor": listing.price_minor,
            }
        )
    ranked.sort(key=lambda r: r["rank_score_e4"], reverse=True)
    for i, row in enumerate(ranked, start=1):
        row["rank"] = i
    return ranked


def negotiation_assist(
    *,
    listing: PropertyListing,
    offer_minor: int,
    principal: str,
) -> dict[str, Any]:
    gap = listing.price_minor - offer_minor
    result = winga_assist(
        capability="recommendation",
        principal=principal,
        payload={
            "task": "property_negotiation",
            "listing_title": listing.title,
            "list_price_minor": listing.price_minor,
            "offer_minor": offer_minor,
            "gap_minor": gap,
        },
    )
    hints = result.get("result", {}).get("suggestions") or result.get("result", {}).get("hints") or []
    if not hints:
        if gap <= 0:
            hints = ["Offer meets or exceeds list price — strong position for fast acceptance."]
        elif gap < listing.price_minor * 0.05:
            hints = ["Offer is within 5% — reasonable opening for negotiation."]
        else:
            hints = ["Gap is significant — ask Winga about comparable rentals in the area."]
    return {
        "listing_id": str(listing.id),
        "list_price_minor": listing.price_minor,
        "offer_minor": offer_minor,
        "gap_minor": gap,
        "hints": hints if isinstance(hints, list) else [str(hints)],
        "payment_authorized": False,
        "model_version": "winga_property.negotiation.v1",
    }


def relocation_assist(
    *,
    listing: PropertyListing,
    destination: str,
    principal: str,
) -> dict[str, Any]:
    intel = intelligence.neighborhood_intelligence(listing=listing)
    result = winga_assist(
        capability="natural_language",
        principal=principal,
        payload={
            "task": "property_relocation",
            "listing_title": listing.title,
            "destination": destination,
            "lifestyle": intel["lifestyle"],
        },
    )
    advice = (
        result.get("result", {}).get("text")
        or result.get("result", {}).get("summary")
        or f"Moving to {listing.ward} from {destination}: consider schools, commute, and utilities in {intel['lifestyle']} area."
    )
    return {
        "listing_id": str(listing.id),
        "destination": destination,
        "advice": str(advice),
        "lifestyle": intel["lifestyle"],
        "payment_authorized": False,
        "model_version": "winga_property.relocation.v1",
    }
