"""Winga Property — listing CRUD, search, verification."""
from __future__ import annotations

from decimal import Decimal
from typing import Any

from django.db import transaction
from django.db.models import Q, QuerySet
from django.utils import timezone

from .models import (
    MediaKind,
    PropertyCategory,
    PropertyFavorite,
    PropertyListing,
    PropertyMedia,
    PropertyOwner,
    PropertyOwnerRole,
    PropertyType,
    PropertyVerificationEvent,
    PropertyVerificationStatus,
    SavedSearch,
)


class PropertyError(Exception):
    pass


def get_or_create_owner(*, principal: str, display_name: str = "", **kwargs) -> PropertyOwner:
    owner, created = PropertyOwner.objects.get_or_create(
        principal=principal,
        defaults={
            "display_name": display_name or principal,
            **kwargs,
        },
    )
    if not created and display_name and owner.display_name != display_name:
        owner.display_name = display_name
        owner.save(update_fields=["display_name", "updated_at"])
    return owner


def search_listings(
    *,
    q: str = "",
    category: str = "",
    property_type: str = "",
    transaction_type: str = "",
    region: str = "",
    district: str = "",
    min_price: int | None = None,
    max_price: int | None = None,
    beds: int | None = None,
    baths: int | None = None,
    verified_only: bool = False,
    owner_principal: str = "",
    limit: int = 50,
) -> QuerySet[PropertyListing]:
    qs = PropertyListing.objects.filter(active=True).select_related(
        "category", "property_type", "owner"
    )
    if verified_only:
        qs = qs.filter(verification_status=PropertyVerificationStatus.VERIFIED)
    if owner_principal:
        qs = qs.filter(owner__principal=owner_principal)
    if category:
        qs = qs.filter(category__code=category)
    if property_type:
        qs = qs.filter(property_type__code=property_type)
    if transaction_type:
        qs = qs.filter(transaction_type=transaction_type)
    if region:
        qs = qs.filter(region__icontains=region)
    if district:
        qs = qs.filter(district__icontains=district)
    if min_price is not None:
        qs = qs.filter(price_minor__gte=min_price)
    if max_price is not None:
        qs = qs.filter(price_minor__lte=max_price)
    if beds is not None:
        qs = qs.filter(beds__gte=beds)
    if baths is not None:
        qs = qs.filter(baths__gte=baths)
    if q:
        qs = qs.filter(
            Q(title__icontains=q)
            | Q(description__icontains=q)
            | Q(address_line__icontains=q)
            | Q(ward__icontains=q)
            | Q(district__icontains=q)
            | Q(region__icontains=q)
        )
    return qs[:limit]


def map_pins(*, region: str = "", limit: int = 200) -> list[dict[str, Any]]:
    qs = PropertyListing.objects.filter(
        active=True,
        verification_status=PropertyVerificationStatus.VERIFIED,
    ).exclude(latitude=0, longitude=0)
    if region:
        qs = qs.filter(region__icontains=region)
    return [
        {
            "id": str(row.id),
            "title": row.title,
            "lat": float(row.latitude),
            "lng": float(row.longitude),
            "price_minor": row.price_minor,
            "currency": row.currency,
            "transaction_type": row.transaction_type,
            "beds": row.beds,
        }
        for row in qs[:limit]
    ]


@transaction.atomic
def create_listing(*, owner: PropertyOwner, **fields) -> PropertyListing:
    listing = PropertyListing.objects.create(owner=owner, **fields)
    return listing


@transaction.atomic
def update_listing(*, listing: PropertyListing, **fields) -> PropertyListing:
    for key, value in fields.items():
        setattr(listing, key, value)
    listing.save()
    return listing


@transaction.atomic
def add_media(
    *,
    listing: PropertyListing,
    kind: str,
    url: str,
    caption: str = "",
    sort_order: int = 0,
    is_primary: bool = False,
    duration_seconds: int | None = None,
    room_code: str = "",
    tour_kind: str = "gallery",
    is_hd: bool = False,
    panorama_url: str = "",
    floor_plan_data: dict | None = None,
) -> PropertyMedia:
    if is_primary:
        PropertyMedia.objects.filter(listing=listing, is_primary=True).update(is_primary=False)
    return PropertyMedia.objects.create(
        listing=listing,
        kind=kind,
        url=url,
        caption=caption,
        sort_order=sort_order,
        is_primary=is_primary,
        duration_seconds=duration_seconds,
        room_code=room_code,
        tour_kind=tour_kind or "gallery",
        is_hd=is_hd,
        panorama_url=panorama_url,
        floor_plan_data=floor_plan_data or {},
    )


@transaction.atomic
def submit_for_verification(*, listing: PropertyListing, actor: str) -> PropertyListing:
    if listing.verification_status not in {
        PropertyVerificationStatus.DRAFT,
        PropertyVerificationStatus.REJECTED,
    }:
        raise PropertyError(f"cannot submit from {listing.verification_status}")
    if not listing.media.filter(kind=MediaKind.PHOTO).exists():
        raise PropertyError("at least one photo is required before verification")
    old = listing.verification_status
    listing.verification_status = PropertyVerificationStatus.PENDING
    listing.save(update_fields=["verification_status", "updated_at"])
    PropertyVerificationEvent.objects.create(
        listing=listing,
        from_status=old,
        to_status=PropertyVerificationStatus.PENDING,
        actor=actor,
        notes="submitted for verification",
    )
    return listing


@transaction.atomic
def verify_listing(
    *,
    listing: PropertyListing,
    actor: str,
    approve: bool = True,
    notes: str = "",
) -> PropertyListing:
    old = listing.verification_status
    if approve:
        listing.verification_status = PropertyVerificationStatus.VERIFIED
        listing.verified_at = timezone.now()
        listing.published_at = listing.published_at or timezone.now()
    else:
        listing.verification_status = PropertyVerificationStatus.REJECTED
    listing.save(update_fields=["verification_status", "verified_at", "published_at", "updated_at"])
    PropertyVerificationEvent.objects.create(
        listing=listing,
        from_status=old,
        to_status=listing.verification_status,
        actor=actor,
        notes=notes or ("approved" if approve else "rejected"),
    )
    return listing


def toggle_favorite(*, principal: str, listing: PropertyListing) -> bool:
    fav, created = PropertyFavorite.objects.get_or_create(
        principal=principal, listing=listing
    )
    if not created:
        fav.delete()
        return False
    return True


def create_saved_search(*, principal: str, name: str, filters: dict) -> SavedSearch:
    return SavedSearch.objects.create(principal=principal, name=name, filters=filters)
