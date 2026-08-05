"""Winga Property Phase 6 — enterprise ops, analytics, fraud, moderation, disputes."""
from __future__ import annotations

import uuid
from typing import Any

from django.db import transaction
from django.db.models import Count, Sum
from django.utils import timezone

from .models import (
    PropertyApplication,
    PropertyApplicationStatus,
    PropertyDispute,
    PropertyDisputeStatus,
    PropertyDisputeSubject,
    PropertyLease,
    PropertyLeasePayment,
    PropertyLeasePaymentStatus,
    PropertyLeaseStatus,
    PropertyListing,
    PropertyModerationReport,
    PropertyModerationStatus,
    PropertyOpsAuditEvent,
    PropertyVerificationCheckStatus,
    PropertyVerificationStatus,
    PropertyViewEvent,
    PropertyViewingPass,
    PropertyViewingPassStatus,
    PropertyWingaAssignment,
)


class OpsError(Exception):
    pass


def _audit(*, actor: str, action: str, entity_type: str, entity_id: uuid.UUID, metadata: dict | None = None) -> None:
    PropertyOpsAuditEvent.objects.create(
        actor=actor,
        action=action,
        entity_type=entity_type,
        entity_id=entity_id,
        metadata=metadata or {},
    )


def executive_dashboard(*, region: str = "") -> dict[str, Any]:
    listings = PropertyListing.objects.filter(active=True)
    if region:
        listings = listings.filter(region=region)
    applications = PropertyApplication.objects.all()
    leases = PropertyLease.objects.all()
    payments = PropertyLeasePayment.objects.filter(status=PropertyLeasePaymentStatus.PAID)
    disputes_open = PropertyDispute.objects.filter(
        status__in=[PropertyDisputeStatus.OPEN, PropertyDisputeStatus.INVESTIGATING]
    ).count()
    moderation_pending = PropertyModerationReport.objects.filter(
        status__in=[PropertyModerationStatus.PENDING, PropertyModerationStatus.UNDER_REVIEW]
    ).count()
    return {
        "generated_at": timezone.now().isoformat(),
        "region_filter": region,
        "listings_total": listings.count(),
        "listings_verified": listings.filter(verification_status=PropertyVerificationStatus.VERIFIED).count(),
        "listings_pending_verification": listings.filter(
            verification_status=PropertyVerificationStatus.PENDING
        ).count(),
        "applications_total": applications.count(),
        "applications_approved": applications.filter(status=PropertyApplicationStatus.APPROVED).count(),
        "leases_active": leases.filter(status=PropertyLeaseStatus.ACTIVE).count(),
        "gmv_minor": payments.aggregate(s=Sum("amount_minor"))["s"] or 0,
        "viewing_passes_active": PropertyViewingPass.objects.filter(
            status=PropertyViewingPassStatus.ACTIVE
        ).count(),
        "winga_assignments_active": PropertyWingaAssignment.objects.filter(status="active").count(),
        "disputes_open": disputes_open,
        "moderation_pending": moderation_pending,
        "model_version": "winga_property.ops.dashboard.v1",
    }


def analytics_summary(*, region: str = "", days: int = 30) -> dict[str, Any]:
    since = timezone.now() - timezone.timedelta(days=days)
    listings = PropertyListing.objects.filter(active=True)
    if region:
        listings = listings.filter(region=region)
    by_region = list(
        listings.values("region")
        .annotate(count=Count("id"), avg_price=Sum("price_minor"))
        .order_by("-count")[:10]
    )
    by_transaction = list(
        listings.values("transaction_type").annotate(count=Count("id")).order_by("-count")
    )
    views = PropertyViewEvent.objects.filter(viewed_at__gte=since).count()
    apps_recent = PropertyApplication.objects.filter(created_at__gte=since).count()
    payments_recent = PropertyLeasePayment.objects.filter(
        status=PropertyLeasePaymentStatus.PAID,
        paid_at__gte=since,
    )
    return {
        "period_days": days,
        "region_filter": region,
        "listings_by_region": by_region,
        "listings_by_transaction_type": by_transaction,
        "views_recent": views,
        "applications_recent": apps_recent,
        "payments_recent_count": payments_recent.count(),
        "payments_recent_gmv_minor": payments_recent.aggregate(s=Sum("amount_minor"))["s"] or 0,
        "conversion_funnel": {
            "views": views,
            "applications": apps_recent,
            "approved": PropertyApplication.objects.filter(
                status=PropertyApplicationStatus.APPROVED,
                created_at__gte=since,
            ).count(),
            "leases_active": PropertyLease.objects.filter(
                status=PropertyLeaseStatus.ACTIVE,
                created_at__gte=since,
            ).count(),
        },
        "model_version": "winga_property.ops.analytics.v1",
    }


def listing_fraud_signals(*, listing: PropertyListing, principal: str = "system") -> dict[str, Any]:
    signals: list[str] = []
    if listing.price_minor <= 0:
        signals.append("zero_or_negative_price")
    if listing.verification_status != PropertyVerificationStatus.VERIFIED:
        signals.append("unverified_listing")
    if not listing.media.exists():
        signals.append("no_media")
    dupes = PropertyListing.objects.filter(
        owner=listing.owner,
        price_minor=listing.price_minor,
        beds=listing.beds,
        district=listing.district,
        active=True,
    ).exclude(pk=listing.pk).count()
    if dupes:
        signals.append("duplicate_listing_pattern")
    reports = listing.moderation_reports.filter(
        status__in=[PropertyModerationStatus.PENDING, PropertyModerationStatus.UNDER_REVIEW]
    ).count()
    if reports:
        signals.append("open_moderation_reports")
    if listing.latitude == 0 and listing.longitude == 0:
        signals.append("missing_coordinates")
    rules_score = min(10000, len(signals) * 2000)
    features = {
        "entity_type": "listing",
        "listing_id": str(listing.id),
        "price_minor": listing.price_minor,
        "verification_status": listing.verification_status,
        "media_count": listing.media.count(),
        "duplicate_count": dupes,
        "open_reports": reports,
        "rule_signals": signals,
        "region": listing.region,
    }
    ml = _ml_fraud_assessment(principal=principal, features=features)
    ml_signals = list(ml.get("signals") or [])
    combined = list(dict.fromkeys(signals + ml_signals))
    return {
        "listing_id": str(listing.id),
        "signals": combined,
        "rule_signals": signals,
        "risk_score_e4": max(rules_score, int(ml.get("score_e4") or 0)),
        "rules_score_e4": rules_score,
        "ml": ml,
        "advisory_only": True,
        "payment_authorized": False,
        "model_version": "winga_property.fraud.v2",
    }


def application_fraud_signals(*, application: PropertyApplication, principal: str = "system") -> dict[str, Any]:
    signals: list[str] = []
    listing = application.listing
    if application.monthly_income_minor <= 0:
        signals.append("zero_declared_income")
    rent = listing.price_minor or 1
    if application.monthly_income_minor < rent:
        signals.append("income_below_rent")
    identity = application.verifications.filter(check_kind="identity").first()
    if identity and identity.status == PropertyVerificationCheckStatus.FAILED:
        signals.append("identity_verification_failed")
    income = application.verifications.filter(check_kind="income").first()
    if income and income.status == PropertyVerificationCheckStatus.FAILED:
        signals.append("income_verification_failed")
    listing_assessment = listing_fraud_signals(listing=listing, principal=principal)
    if listing_assessment["risk_score_e4"] >= 6000:
        signals.append("high_risk_listing")
    rules_score = min(10000, len(signals) * 1800)
    features = {
        "entity_type": "application",
        "application_id": str(application.id),
        "listing_id": str(listing.id),
        "monthly_income_minor": application.monthly_income_minor,
        "rent_minor": rent,
        "income_ratio": round(application.monthly_income_minor / rent, 2) if rent else 0,
        "identity_status": identity.status if identity else "pending",
        "income_status": income.status if income else "pending",
        "rule_signals": signals,
        "listing_risk_e4": listing_assessment["risk_score_e4"],
    }
    ml = _ml_fraud_assessment(principal=principal, features=features)
    ml_signals = list(ml.get("signals") or [])
    combined = list(dict.fromkeys(signals + ml_signals))
    return {
        "application_id": str(application.id),
        "signals": combined,
        "rule_signals": signals,
        "risk_score_e4": max(rules_score, int(ml.get("score_e4") or 0)),
        "rules_score_e4": rules_score,
        "ml": ml,
        "advisory_only": True,
        "payment_authorized": False,
        "model_version": "winga_property.fraud.v2",
    }


def _ml_fraud_assessment(*, principal: str, features: dict[str, Any]) -> dict[str, Any]:
    """Taifa AI OS fraud_detection — advisory only; never authorizes payments."""
    try:
        from ecosystem.ai import invoke_ai

        result = invoke_ai(
            capability_code="fraud_detection",
            principal=principal,
            payload={"features": features, "domain": "winga_property"},
            domain_code="winga_property",
        )
        body = result.get("result") if isinstance(result.get("result"), dict) else result
        if not isinstance(body, dict):
            body = {}
        return {
            "risk_band": body.get("risk_band", "unknown"),
            "score_e4": int(body.get("score_e4") or result.get("confidence_e4") or 0),
            "signals": body.get("signals") or [],
            "reasoning": result.get("reasoning_summary", body.get("note", "")),
            "model_version": str(result.get("model_version") or "fraud_detection"),
            "payment_authorized": False,
        }
    except Exception as exc:
        return {
            "risk_band": "unknown",
            "score_e4": 0,
            "signals": [],
            "reasoning": f"ml_unavailable: {exc}",
            "model_version": "winga_property.fraud.fallback",
            "payment_authorized": False,
        }


def ops_console_bundle(*, region: str = "", limit: int = 30) -> dict[str, Any]:
    """Single payload for the dedicated ops console UI."""
    audit = list(
        PropertyOpsAuditEvent.objects.order_by("-created_at")[:limit].values(
            "action", "entity_type", "actor", "created_at"
        )
    )
    for row in audit:
        row["created_at"] = row["created_at"].isoformat()
    return {
        "dashboard": executive_dashboard(region=region),
        "analytics": analytics_summary(region=region, days=30),
        "moderation": moderation_queue(limit=limit),
        "disputes": [dispute_payload(d) for d in list_disputes(limit=limit)],
        "recent_audit": audit,
        "model_version": "winga_property.ops.console.v1",
    }


def moderation_queue(*, limit: int = 50) -> dict[str, Any]:
    reports = list(
        PropertyModerationReport.objects.filter(
            status__in=[PropertyModerationStatus.PENDING, PropertyModerationStatus.UNDER_REVIEW]
        )
        .select_related("listing")
        .order_by("-created_at")[:limit]
    )
    pending_listings = list(
        PropertyListing.objects.filter(
            verification_status=PropertyVerificationStatus.PENDING,
            active=True,
        ).select_related("owner")[:limit]
    )
    return {
        "reports": [_report_payload(r) for r in reports],
        "pending_verifications": [
            {
                "listing_id": str(l.id),
                "title": l.title,
                "owner": l.owner.display_name,
                "region": l.region,
                "submitted": l.updated_at.isoformat(),
            }
            for l in pending_listings
        ],
        "counts": {
            "reports": len(reports),
            "pending_verifications": len(pending_listings),
        },
    }


def _report_payload(report: PropertyModerationReport) -> dict[str, Any]:
    return {
        "id": str(report.id),
        "listing_id": str(report.listing_id),
        "listing_title": report.listing.title,
        "reason": report.reason,
        "notes": report.notes,
        "status": report.status,
        "reporter_principal": report.reporter_principal,
        "created_at": report.created_at.isoformat(),
    }


@transaction.atomic
def report_listing(
    *,
    listing: PropertyListing,
    reporter_principal: str,
    reason: str,
    notes: str = "",
) -> PropertyModerationReport:
    report = PropertyModerationReport.objects.create(
        listing=listing,
        reporter_principal=reporter_principal,
        reason=reason,
        notes=notes,
    )
    _audit(
        actor=reporter_principal,
        action="report_listing",
        entity_type="moderation_report",
        entity_id=report.id,
        metadata={"listing_id": str(listing.id), "reason": reason},
    )
    return report


@transaction.atomic
def resolve_moderation_report(
    *,
    report: PropertyModerationReport,
    actor: str,
    action: str,
    notes: str = "",
) -> PropertyModerationReport:
    if action == "dismiss":
        report.status = PropertyModerationStatus.DISMISSED
    elif action == "suspend_listing":
        report.status = PropertyModerationStatus.ACTION_TAKEN
        report.listing.verification_status = PropertyVerificationStatus.SUSPENDED
        report.listing.active = False
        report.listing.save(update_fields=["verification_status", "active", "updated_at"])
    else:
        report.status = PropertyModerationStatus.UNDER_REVIEW
    report.resolved_by = actor
    report.resolution_notes = notes
    report.resolved_at = timezone.now()
    report.save()
    _audit(
        actor=actor,
        action=f"moderation_{action}",
        entity_type="moderation_report",
        entity_id=report.id,
        metadata={"listing_id": str(report.listing_id)},
    )
    return report


@transaction.atomic
def suspend_listing(*, listing: PropertyListing, actor: str, reason: str = "") -> PropertyListing:
    listing.verification_status = PropertyVerificationStatus.SUSPENDED
    listing.active = False
    listing.save(update_fields=["verification_status", "active", "updated_at"])
    _audit(
        actor=actor,
        action="suspend_listing",
        entity_type="listing",
        entity_id=listing.id,
        metadata={"reason": reason},
    )
    return listing


@transaction.atomic
def open_dispute(
    *,
    subject_type: str,
    subject_id: uuid.UUID,
    opened_by: str,
    reason: str,
    listing: PropertyListing | None = None,
    lease: PropertyLease | None = None,
) -> PropertyDispute:
    dispute = PropertyDispute.objects.create(
        subject_type=subject_type,
        subject_id=subject_id,
        listing=listing,
        lease=lease,
        opened_by=opened_by,
        reason=reason,
    )
    _audit(
        actor=opened_by,
        action="open_dispute",
        entity_type="dispute",
        entity_id=dispute.id,
        metadata={"subject_type": subject_type, "subject_id": str(subject_id)},
    )
    return dispute


def list_disputes(*, status: str = "", limit: int = 50) -> list[PropertyDispute]:
    qs = PropertyDispute.objects.select_related("listing", "lease").order_by("-created_at")
    if status:
        qs = qs.filter(status=status)
    return list(qs[:limit])


def dispute_payload(dispute: PropertyDispute) -> dict[str, Any]:
    return {
        "id": str(dispute.id),
        "subject_type": dispute.subject_type,
        "subject_id": str(dispute.subject_id),
        "listing_id": str(dispute.listing_id) if dispute.listing_id else None,
        "lease_id": str(dispute.lease_id) if dispute.lease_id else None,
        "opened_by": dispute.opened_by,
        "reason": dispute.reason,
        "status": dispute.status,
        "assigned_ops": dispute.assigned_ops,
        "resolution": dispute.resolution,
        "created_at": dispute.created_at.isoformat(),
        "resolved_at": dispute.resolved_at.isoformat() if dispute.resolved_at else None,
    }


@transaction.atomic
def assign_dispute(*, dispute: PropertyDispute, ops_principal: str, actor: str) -> PropertyDispute:
    dispute.status = PropertyDisputeStatus.INVESTIGATING
    dispute.assigned_ops = ops_principal
    dispute.save(update_fields=["status", "assigned_ops"])
    _audit(
        actor=actor,
        action="assign_dispute",
        entity_type="dispute",
        entity_id=dispute.id,
        metadata={"assigned_ops": ops_principal},
    )
    return dispute


@transaction.atomic
def resolve_dispute(
    *,
    dispute: PropertyDispute,
    actor: str,
    resolution: str,
    approve: bool = True,
) -> PropertyDispute:
    dispute.status = PropertyDisputeStatus.RESOLVED if approve else PropertyDisputeStatus.REJECTED
    dispute.resolution = resolution
    dispute.resolved_at = timezone.now()
    dispute.save(update_fields=["status", "resolution", "resolved_at"])
    _audit(
        actor=actor,
        action="resolve_dispute",
        entity_type="dispute",
        entity_id=dispute.id,
        metadata={"approved": approve},
    )
    return dispute
