"""Winga Property Phase 2 — discovery intelligence, commute, visit score, AI search."""
from __future__ import annotations

import re
from typing import Any

from trips.services import haversine_meters, nearest_station

from .models import (
    PropertyListing,
    PropertyVerificationStatus,
    PropertyViewEvent,
)
from .services import search_listings


def _float(val) -> float:
    try:
        return float(val)
    except (TypeError, ValueError):
        return 0.0


def _ward_profile(ward: str, district: str) -> dict[str, Any]:
    """Deterministic neighborhood baseline by Dar es Salaam area (foundation)."""
    key = (ward or district or "").lower()
    profiles = {
        "masaki": {
            "walkability_e4": 7200,
            "safety_e4": 7800,
            "water_reliability_e4": 8200,
            "power_reliability_e4": 8500,
            "lifestyle": "upmarket_coastal",
        },
        "mikocheni": {
            "walkability_e4": 6800,
            "safety_e4": 7400,
            "water_reliability_e4": 8000,
            "power_reliability_e4": 8200,
            "lifestyle": "family_suburban",
        },
        "oysterbay": {
            "walkability_e4": 7000,
            "safety_e4": 8000,
            "water_reliability_e4": 8300,
            "power_reliability_e4": 8600,
            "lifestyle": "diplomatic_quiet",
        },
        "tegeta": {
            "walkability_e4": 5500,
            "safety_e4": 6500,
            "water_reliability_e4": 7000,
            "power_reliability_e4": 7200,
            "lifestyle": "emerging_suburban",
        },
        "kariakoo": {
            "walkability_e4": 8500,
            "safety_e4": 6200,
            "water_reliability_e4": 7500,
            "power_reliability_e4": 7000,
            "lifestyle": "urban_bustling",
        },
    }
    for token, profile in profiles.items():
        if token in key:
            return profile
    return {
        "walkability_e4": 6000,
        "safety_e4": 6800,
        "water_reliability_e4": 7400,
        "power_reliability_e4": 7600,
        "lifestyle": "general_urban",
    }


def _nearby_express_count(lat: float, lng: float) -> int:
    try:
        from express.services import rank_stores

        return len(rank_stores(customer_lat=lat, customer_lng=lng, limit=5))
    except Exception:
        return 0


def neighborhood_intelligence(*, listing: PropertyListing) -> dict[str, Any]:
    lat = _float(listing.latitude)
    lng = _float(listing.longitude)
    profile = _ward_profile(listing.ward, listing.district)
    station = nearest_station(latitude=lat, longitude=lng, region=listing.region) if lat and lng else None
    station_dist_m = (
        haversine_meters(lat, lng, float(station.latitude), float(station.longitude))
        if station
        else None
    )
    express_nearby = _nearby_express_count(lat, lng) if lat and lng else 0

    # Foundation POI counts — seeded heuristics by ward density
    density = profile["walkability_e4"] / 10_000
    schools = max(1, int(2 + density * 6))
    hospitals = max(1, int(1 + density * 3))
    markets = max(1, int(2 + density * 5))
    restaurants = max(2, int(3 + density * 8))
    parks = max(0, int(density * 4))

    return {
        "listing_id": str(listing.id),
        "ward": listing.ward,
        "district": listing.district,
        "region": listing.region,
        "lifestyle": profile["lifestyle"],
        "walkability_e4": profile["walkability_e4"],
        "safety_score_e4": profile["safety_e4"],
        "water_reliability_e4": profile["water_reliability_e4"],
        "power_reliability_e4": profile["power_reliability_e4"],
        "internet_providers": ["TTCL", "Airtel", "Vodacom", "YAS"],
        "nearby": {
            "schools": schools,
            "hospitals": hospitals,
            "markets": markets,
            "express_merchants": express_nearby,
            "mobility_stations": 1 if station else 0,
            "restaurants": restaurants,
            "parks": parks,
        },
        "mobility": {
            "nearest_station": station.name if station else "",
            "station_distance_meters": station_dist_m,
        },
        "model_version": "winga_property.neighborhood.v1",
    }


def commute_estimate(
    *,
    listing: PropertyListing,
    dest_lat: float,
    dest_lng: float,
    mode: str = "driving",
) -> dict[str, Any]:
    lat = _float(listing.latitude)
    lng = _float(listing.longitude)
    distance_m = haversine_meters(lat, lng, dest_lat, dest_lng)
    speed_mps = 6.0 if mode == "driving" else 1.4
    traffic_factor = 1.35 if mode == "driving" else 1.0
    duration_s = int((distance_m / speed_mps) * traffic_factor)
    return {
        "listing_id": str(listing.id),
        "mode": mode,
        "distance_meters": distance_m,
        "duration_seconds": duration_s,
        "duration_label": f"{max(1, duration_s // 60)} min",
        "traffic_factor": traffic_factor,
        "model_version": "winga_property.commute.v1",
    }


def visit_decision_score(
    *,
    listing: PropertyListing,
    dest_lat: float | None = None,
    dest_lng: float | None = None,
) -> dict[str, Any]:
    """AI visit decision score 1–5 stars (deterministic foundation)."""
    intel = neighborhood_intelligence(listing=listing)
    score_e4 = 5000

    if listing.verification_status == PropertyVerificationStatus.VERIFIED:
        score_e4 += 1200
    score_e4 += int(intel["walkability_e4"] * 0.15)
    score_e4 += int(intel["safety_score_e4"] * 0.10)
    score_e4 += min(800, intel["nearby"]["express_merchants"] * 100)
    if listing.beds >= 2 and listing.area_sqm >= 80:
        score_e4 += 300

    commute_penalty = 0
    if dest_lat is not None and dest_lng is not None:
        commute = commute_estimate(listing=listing, dest_lat=dest_lat, dest_lng=dest_lng)
        mins = commute["duration_seconds"] // 60
        if mins > 60:
            commute_penalty = 1500
        elif mins > 45:
            commute_penalty = 900
        elif mins > 30:
            commute_penalty = 400
        score_e4 -= commute_penalty

    score_e4 = max(0, min(10_000, score_e4))
    stars = max(1, min(5, round(score_e4 / 2000)))

    labels = {
        5: "Visit — excellent match",
        4: "Good match",
        3: "Average — worth a virtual tour",
        2: "Consider alternatives",
        1: "Skip unless priorities change",
    }

    return {
        "listing_id": str(listing.id),
        "score_e4": score_e4,
        "stars": stars,
        "label": labels.get(stars, "Average"),
        "factors": {
            "verified": listing.verification_status == PropertyVerificationStatus.VERIFIED,
            "neighborhood": intel["lifestyle"],
            "commute_penalty_e4": commute_penalty,
        },
        "model_version": "winga_property.visit_score.v1",
    }


def ai_property_search(
    *,
    query: str,
    principal: str,
    lifestyle: str = "",
    neighborhood: str = "",
    limit: int = 20,
) -> dict[str, Any]:
    """Natural-language + lifestyle search — AI assist with rule-based fallback."""
    q = (query or "").strip()
    filters: dict[str, Any] = {"verified_only": True, "limit": limit}

    # Parse simple NL patterns
    bed_match = re.search(r"(\d+)\s*bed", q, re.I)
    if bed_match:
        filters["beds"] = int(bed_match.group(1))
    if re.search(r"\bboda\b|\bmasaki\b|\bmikocheni\b|\boysterbay\b|\btegeta\b|\bkariakoo\b", q, re.I):
        for area in ("masaki", "mikocheni", "oysterbay", "tegeta", "kariakoo"):
            if area in q.lower():
                filters["district"] = area.title() if area != "masaki" else "Kinondoni"
                filters["q"] = area
                break
    if re.search(r"\brent\b|\bapartment\b|\bflat\b", q, re.I):
        filters["transaction_type"] = "rent"
    if re.search(r"\bsale\b|\bbuy\b", q, re.I):
        filters["transaction_type"] = "sale"
    if neighborhood:
        filters["q"] = neighborhood
    if lifestyle:
        filters["q"] = f"{filters.get('q', '')} {lifestyle}".strip()

    if not filters.get("q") and q:
        filters["q"] = q

    listings = list(search_listings(**filters))

    ai_hints: list[str] = []
    try:
        from ecosystem.ai import invoke_ai

        ai_result = invoke_ai(
            capability_code="semantic_search",
            principal=principal,
            payload={"query": q, "domain": "winga_property", "lifestyle": lifestyle},
            domain_code="winga_property",
        )
        ai_hints = ai_result.get("hints") or ai_result.get("suggestions") or []
    except Exception:
        from django.conf import settings

        if getattr(settings, "TAIFA_ALLOW_STUB_ADAPTERS", True):
            ai_hints = [f"Matched {len(listings)} properties for '{q or lifestyle or neighborhood}'"]

    return {
        "query": q,
        "lifestyle": lifestyle,
        "neighborhood": neighborhood,
        "count": len(listings),
        "listing_ids": [str(l.id) for l in listings],
        "ai_hints": ai_hints,
        "model_version": "winga_property.ai_search.v1",
    }


def recommend_listings(*, principal: str, limit: int = 6) -> list[PropertyListing]:
    """AI recommendations from favorites + recent views."""
    from .models import PropertyFavorite

    fav_cats = list(
        PropertyFavorite.objects.filter(principal=principal)
        .select_related("listing__category")
        .values_list("listing__category__code", flat=True)[:5]
    )
    recent = list(
        PropertyViewEvent.objects.filter(principal=principal)
        .select_related("listing")
        .order_by("-viewed_at")[:5]
    )
    recent_ids = [e.listing_id for e in recent]
    qs = PropertyListing.objects.filter(
        active=True,
        verification_status=PropertyVerificationStatus.VERIFIED,
    ).exclude(id__in=recent_ids)
    if fav_cats:
        qs = qs.filter(category__code__in=fav_cats)
    return list(qs.select_related("category", "property_type", "owner")[:limit])


def compare_listings(*, listing_ids: list[str]) -> dict[str, Any]:
    rows = list(
        PropertyListing.objects.filter(id__in=listing_ids[:4], active=True).select_related(
            "category", "property_type", "owner"
        )
    )
    comparisons = []
    for listing in rows:
        intel = neighborhood_intelligence(listing=listing)
        visit = visit_decision_score(listing=listing)
        comparisons.append(
            {
                "id": str(listing.id),
                "title": listing.title,
                "price_minor": listing.price_minor,
                "currency": listing.currency,
                "beds": listing.beds,
                "baths": listing.baths,
                "area_sqm": listing.area_sqm,
                "location": f"{listing.ward}, {listing.district}",
                "verification_status": listing.verification_status,
                "visit_stars": visit["stars"],
                "visit_label": visit["label"],
                "safety_e4": intel["safety_score_e4"],
                "walkability_e4": intel["walkability_e4"],
            }
        )
    return {"listings": comparisons, "count": len(comparisons)}


def record_view(*, principal: str, listing: PropertyListing) -> None:
    PropertyViewEvent.objects.create(principal=principal, listing=listing)


def recently_viewed(*, principal: str, limit: int = 8) -> list[PropertyListing]:
    ids = (
        PropertyViewEvent.objects.filter(principal=principal)
        .order_by("-viewed_at")
        .values_list("listing_id", flat=True)[:limit]
    )
    seen: list = []
    unique_ids: list = []
    for lid in ids:
        if lid not in seen:
            seen.append(lid)
            unique_ids.append(lid)
    return list(
        PropertyListing.objects.filter(id__in=unique_ids, active=True).select_related(
            "category", "property_type", "owner"
        )
    )


def map_clusters(*, region: str = "", grid_size: float = 0.02) -> list[dict[str, Any]]:
    """Grid-based map clustering for discovery map."""
    from .services import map_pins

    pins = map_pins(region=region, limit=500)
    buckets: dict[tuple[int, int], list[dict]] = {}
    for pin in pins:
        gx = int(pin["lat"] / grid_size)
        gy = int(pin["lng"] / grid_size)
        buckets.setdefault((gx, gy), []).append(pin)

    clusters = []
    for (gx, gy), group in buckets.items():
        lat = sum(p["lat"] for p in group) / len(group)
        lng = sum(p["lng"] for p in group) / len(group)
        clusters.append(
            {
                "cluster_id": f"{gx}:{gy}",
                "lat": lat,
                "lng": lng,
                "count": len(group),
                "pins": group,
            }
        )
    return clusters


def advanced_search(
    *,
    q: str = "",
    lifestyle: str = "",
    min_walkability_e4: int | None = None,
    min_safety_e4: int | None = None,
    **filters,
) -> list[PropertyListing]:
    listings = list(search_listings(q=q or lifestyle, **filters))
    if not min_walkability_e4 and not min_safety_e4:
        return listings
    out = []
    for listing in listings:
        intel = neighborhood_intelligence(listing=listing)
        if min_walkability_e4 and intel["walkability_e4"] < min_walkability_e4:
            continue
        if min_safety_e4 and intel["safety_score_e4"] < min_safety_e4:
            continue
        out.append(listing)
    return out
