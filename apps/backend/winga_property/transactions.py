"""Winga Property Phase 5 — applications, verification, leases, wallet payments."""
from __future__ import annotations

import uuid
from datetime import date, datetime, timedelta
from typing import Any

from django.db import transaction
from django.utils import timezone

from commerce.services import CommerceError, ensure_platform_commerce_merchant
from continental.adapters import resolve_identity_adapter
from enterprise.orchestrator import PlatformContext, default_platform
from payments.money import Currency, Money

from .models import (
    PropertyApplication,
    PropertyApplicationDocument,
    PropertyApplicationDocumentKind,
    PropertyApplicationStatus,
    PropertyApplicationVerification,
    PropertyLease,
    PropertyLeasePayment,
    PropertyLeasePaymentKind,
    PropertyLeasePaymentStatus,
    PropertyLeaseStatus,
    PropertyListing,
    PropertyMovePhase,
    PropertyMoveStatus,
    PropertyMoveWorkflow,
    PropertyTimelineEventType,
    PropertyVerificationCheckKind,
    PropertyVerificationCheckStatus,
    PropertyVerificationStatus,
    PropertyWingaAssignment,
)


class TransactionError(Exception):
    pass


DEFAULT_MOVE_IN_CHECKLIST = [
    {"code": "keys", "label": "Collect keys", "done": False},
    {"code": "meter_reading", "label": "Record utility meter readings", "done": False},
    {"code": "inventory", "label": "Complete property inventory", "done": False},
    {"code": "deposit_paid", "label": "Confirm deposit received", "done": False},
]

DEFAULT_MOVE_OUT_CHECKLIST = [
    {"code": "inspection", "label": "Final inspection walkthrough", "done": False},
    {"code": "utilities", "label": "Settle utility bills", "done": False},
    {"code": "keys_return", "label": "Return keys", "done": False},
    {"code": "deposit_release", "label": "Process deposit release", "done": False},
]

INCOME_RENT_RATIO_MIN = 3


def _notify(recipient: str, template: str, payload: dict) -> None:
    try:
        from integrations.notifications import deliver_notification

        deliver_notification(channel="push", recipient=recipient, template=template, payload=payload)
    except Exception:
        pass


def _timeline_for_assignment(
    assignment: PropertyWingaAssignment | None,
    *,
    event_type: str,
    title: str,
    actor: str,
    notes: str = "",
    metadata: dict | None = None,
) -> None:
    if not assignment:
        return
    from .human_winga import _timeline

    _timeline(
        assignment=assignment,
        event_type=event_type,
        title=title,
        notes=notes,
        actor=actor,
        metadata=metadata or {},
    )


@transaction.atomic
def create_application(
    *,
    listing: PropertyListing,
    applicant_principal: str,
    employment_status: str = "",
    monthly_income_minor: int = 0,
    national_id: str = "",
    move_in_date: date | None = None,
    notes: str = "",
    assignment: PropertyWingaAssignment | None = None,
) -> PropertyApplication:
    if listing.verification_status != PropertyVerificationStatus.VERIFIED:
        raise TransactionError("listing must be verified before applying")
    existing = PropertyApplication.objects.filter(
        listing=listing,
        applicant_principal=applicant_principal,
        status__in=[
            PropertyApplicationStatus.DRAFT,
            PropertyApplicationStatus.SUBMITTED,
            PropertyApplicationStatus.UNDER_REVIEW,
            PropertyApplicationStatus.APPROVED,
        ],
    ).first()
    if existing:
        return existing
    return PropertyApplication.objects.create(
        listing=listing,
        applicant_principal=applicant_principal,
        assignment=assignment,
        employment_status=employment_status,
        monthly_income_minor=monthly_income_minor,
        national_id=national_id,
        move_in_date=move_in_date,
        notes=notes,
    )


def list_applications(*, principal: str, limit: int = 20) -> list[PropertyApplication]:
    return list(
        PropertyApplication.objects.filter(applicant_principal=principal)
        .select_related("listing")
        .prefetch_related("documents", "verifications")
        .order_by("-created_at")[:limit]
    )


@transaction.atomic
def upload_application_document(
    *,
    application: PropertyApplication,
    kind: str,
    title: str,
    url: str,
    uploaded_by: str,
) -> PropertyApplicationDocument:
    if application.applicant_principal != uploaded_by:
        raise TransactionError("only applicant may upload documents")
    if application.status not in {
        PropertyApplicationStatus.DRAFT,
        PropertyApplicationStatus.SUBMITTED,
        PropertyApplicationStatus.UNDER_REVIEW,
    }:
        raise TransactionError(f"cannot upload in status {application.status}")
    return PropertyApplicationDocument.objects.create(
        application=application,
        kind=kind or PropertyApplicationDocumentKind.OTHER,
        title=title,
        url=url,
        uploaded_by=uploaded_by,
    )


@transaction.atomic
def submit_application(*, application: PropertyApplication, actor: str) -> PropertyApplication:
    if application.applicant_principal != actor:
        raise TransactionError("only applicant may submit")
    if application.status != PropertyApplicationStatus.DRAFT:
        raise TransactionError(f"cannot submit from status {application.status}")
    if not application.national_id:
        raise TransactionError("national_id required before submit")
    application.status = PropertyApplicationStatus.SUBMITTED
    application.submitted_at = timezone.now()
    application.save(update_fields=["status", "submitted_at", "updated_at"])
    for kind in PropertyVerificationCheckKind:
        PropertyApplicationVerification.objects.get_or_create(
            application=application,
            check_kind=kind.value,
            defaults={"status": PropertyVerificationCheckStatus.PENDING},
        )
    application.status = PropertyApplicationStatus.UNDER_REVIEW
    application.save(update_fields=["status", "updated_at"])
    _timeline_for_assignment(
        application.assignment,
        event_type=PropertyTimelineEventType.APPLICATION,
        title="Rental application submitted",
        actor=actor,
        metadata={"application_id": str(application.id)},
    )
    _notify(
        application.listing.owner.principal,
        "winga_property_application_submitted",
        {"application_id": str(application.id), "listing_id": str(application.listing_id)},
    )
    return application


@transaction.atomic
def verify_identity(
    *,
    application: PropertyApplication,
    actor: str,
    country_code: str = "TZ",
    provider_code: str = "nida",
) -> PropertyApplicationVerification:
    if application.applicant_principal != actor:
        raise TransactionError("only applicant may verify identity")
    if not application.national_id:
        raise TransactionError("national_id required")
    adapter = resolve_identity_adapter(country_code, provider_code)
    result = adapter.lookup(identifier=application.national_id)
    check, _ = PropertyApplicationVerification.objects.get_or_create(
        application=application,
        check_kind=PropertyVerificationCheckKind.IDENTITY,
    )
    if result.matched:
        check.status = PropertyVerificationCheckStatus.VERIFIED
        check.provider_ref = result.reference
        check.details = {"provider": result.provider, "attributes": result.attributes}
        check.verified_at = timezone.now()
    else:
        check.status = PropertyVerificationCheckStatus.FAILED
        check.details = {"provider": result.provider, "matched": False}
    check.save()
    return check


@transaction.atomic
def verify_income(*, application: PropertyApplication, actor: str) -> PropertyApplicationVerification:
    if application.applicant_principal != actor:
        raise TransactionError("only applicant may verify income")
    rent = application.listing.price_minor
    income = application.monthly_income_minor
    ratio = (income / rent) if rent else 0
    passed = income > 0 and ratio >= INCOME_RENT_RATIO_MIN
    check, _ = PropertyApplicationVerification.objects.get_or_create(
        application=application,
        check_kind=PropertyVerificationCheckKind.INCOME,
    )
    check.status = (
        PropertyVerificationCheckStatus.VERIFIED
        if passed
        else PropertyVerificationCheckStatus.FAILED
    )
    check.details = {
        "monthly_income_minor": income,
        "rent_minor": rent,
        "ratio": round(ratio, 2),
        "required_ratio": INCOME_RENT_RATIO_MIN,
    }
    check.verified_at = timezone.now() if passed else None
    check.save()
    return check


def _verifications_complete(application: PropertyApplication) -> bool:
    checks = application.verifications.all()
    if checks.count() < 2:
        return False
    return all(c.status == PropertyVerificationCheckStatus.VERIFIED for c in checks)


@transaction.atomic
def approve_application(*, application: PropertyApplication, actor: str) -> PropertyApplication:
    if not _verifications_complete(application):
        raise TransactionError("identity and income verification must pass before approval")
    application.status = PropertyApplicationStatus.APPROVED
    application.reviewed_at = timezone.now()
    application.save(update_fields=["status", "reviewed_at", "updated_at"])
    _timeline_for_assignment(
        application.assignment,
        event_type=PropertyTimelineEventType.APPLICATION,
        title="Application approved",
        actor=actor,
        metadata={"application_id": str(application.id)},
    )
    _notify(
        application.applicant_principal,
        "winga_property_application_approved",
        {"application_id": str(application.id)},
    )
    return application


def _generate_contract_text(*, application: PropertyApplication, lease: PropertyLease) -> str:
    listing = application.listing
    text = (
        f"RESIDENTIAL LEASE AGREEMENT\n\n"
        f"Property: {listing.title}\n"
        f"Address: {listing.address_line}, {listing.ward}, {listing.district}\n"
        f"Tenant: {application.applicant_principal}\n"
        f"Landlord: {listing.owner.display_name} ({listing.owner.principal})\n\n"
        f"Term: {lease.start_date.isoformat()} to {lease.end_date.isoformat()}\n"
        f"Monthly rent: {lease.rent_minor:,} {lease.currency}\n"
        f"Security deposit: {lease.deposit_minor:,} {lease.currency}\n\n"
        f"This digital contract is issued via Taifa Winga Property. "
        f"Payments are processed through Taifa Wallet. "
        f"Both parties must sign electronically to activate the lease."
    )
    try:
        from ecosystem.ai import invoke_ai

        result = invoke_ai(
            capability_code="natural_language",
            principal=application.applicant_principal,
            payload={
                "task": "property_lease_summary",
                "listing_title": listing.title,
                "rent_minor": lease.rent_minor,
                "deposit_minor": lease.deposit_minor,
                "term_months": 12,
            },
            domain_code="winga_property",
        )
        summary = result.get("summary") or result.get("text")
        if summary:
            text += f"\n\nSummary:\n{summary}"
    except Exception:
        pass
    return text


@transaction.atomic
def generate_lease(*, application: PropertyApplication, actor: str) -> PropertyLease:
    if application.status != PropertyApplicationStatus.APPROVED:
        raise TransactionError("application must be approved before lease generation")
    if hasattr(application, "lease"):
        return application.lease
    listing = application.listing
    start = application.move_in_date or (timezone.now().date() + timedelta(days=14))
    end = start + timedelta(days=365)
    deposit = listing.deposit_minor or listing.price_minor
    lease = PropertyLease.objects.create(
        application=application,
        listing=listing,
        tenant_principal=application.applicant_principal,
        owner_principal=listing.owner.principal,
        status=PropertyLeaseStatus.PENDING_SIGNATURES,
        rent_minor=listing.price_minor,
        deposit_minor=deposit,
        currency=listing.currency,
        start_date=start,
        end_date=end,
        contract_url=f"https://contracts.taifa.local/leases/{application.id}.pdf",
    )
    lease.contract_text = _generate_contract_text(application=application, lease=lease)
    lease.save(update_fields=["contract_text", "updated_at"])
    _timeline_for_assignment(
        application.assignment,
        event_type=PropertyTimelineEventType.CONTRACT,
        title="Lease contract generated",
        actor=actor,
        metadata={"lease_id": str(lease.id)},
    )
    return lease


@transaction.atomic
def sign_lease(*, lease: PropertyLease, actor: str) -> PropertyLease:
    now = timezone.now()
    if actor == lease.tenant_principal:
        lease.tenant_signed_at = now
    elif actor == lease.owner_principal:
        lease.owner_signed_at = now
    else:
        raise TransactionError("not authorized to sign lease")
    lease.save(update_fields=["tenant_signed_at", "owner_signed_at", "updated_at"])
    if lease.tenant_signed_at and lease.owner_signed_at:
        lease.status = PropertyLeaseStatus.ACTIVE
        lease.save(update_fields=["status", "updated_at"])
        _create_initial_payments(lease)
        schedule_move_workflow(
            lease=lease,
            phase=PropertyMovePhase.MOVE_IN,
            scheduled_at=timezone.make_aware(datetime.combine(lease.start_date, datetime.min.time())),
            actor=actor,
        )
        _timeline_for_assignment(
            lease.application.assignment if lease.application else None,
            event_type=PropertyTimelineEventType.CONTRACT,
            title="Lease signed and active",
            actor=actor,
            metadata={"lease_id": str(lease.id)},
        )
    return lease


def _create_initial_payments(lease: PropertyLease) -> None:
    PropertyLeasePayment.objects.get_or_create(
        lease=lease,
        kind=PropertyLeasePaymentKind.DEPOSIT,
        defaults={
            "amount_minor": lease.deposit_minor,
            "currency": lease.currency,
            "due_date": lease.start_date,
        },
    )
    PropertyLeasePayment.objects.get_or_create(
        lease=lease,
        kind=PropertyLeasePaymentKind.FIRST_RENT,
        defaults={
            "amount_minor": lease.rent_minor,
            "currency": lease.currency,
            "due_date": lease.start_date,
        },
    )


@transaction.atomic
def collect_lease_payment(
    *,
    payment: PropertyLeasePayment,
    payer_principal: str,
    actor: str,
    idempotency_key: str,
) -> PropertyLeasePayment:
    lease = payment.lease
    if payer_principal != lease.tenant_principal:
        raise TransactionError("only tenant may pay lease charges")
    if payment.status == PropertyLeasePaymentStatus.PAID and payment.payment_ref:
        return payment
    if payment.status != PropertyLeasePaymentStatus.PENDING_PAYMENT:
        raise TransactionError(f"cannot pay in status {payment.status}")

    merchant = ensure_platform_commerce_merchant(sector="winga_property")
    try:
        txn = default_platform().capture_merchant_payment(
            ctx=PlatformContext(actor=actor),
            merchant=merchant,
            payer_owner=payer_principal,
            amount=Money(payment.amount_minor, Currency.from_code(payment.currency)),
            idempotency_key=idempotency_key,
            note=f"WingaProperty Lease {payment.kind} {payment.pk}",
        )
    except Exception as exc:
        raise CommerceError(str(exc)) from exc

    payment.payment_ref = str(txn.id)
    payment.status = PropertyLeasePaymentStatus.PAID
    payment.paid_at = timezone.now()
    payment.save()
    _timeline_for_assignment(
        lease.application.assignment if lease.application else None,
        event_type=PropertyTimelineEventType.PAYMENT,
        title=f"Lease payment: {payment.kind}",
        actor=actor,
        metadata={"payment_id": str(payment.id), "amount_minor": payment.amount_minor},
    )
    _notify(
        lease.owner_principal,
        "winga_property_lease_payment",
        {"lease_id": str(lease.id), "kind": payment.kind, "amount_minor": payment.amount_minor},
    )
    return payment


@transaction.atomic
def renew_lease(*, lease: PropertyLease, actor: str, months: int = 12) -> PropertyLease:
    if lease.status != PropertyLeaseStatus.ACTIVE:
        raise TransactionError("only active leases may be renewed")
    if actor not in {lease.tenant_principal, lease.owner_principal}:
        raise TransactionError("not authorized to renew lease")
    new_start = lease.end_date + timedelta(days=1)
    new_end = new_start + timedelta(days=30 * months)
    lease.end_date = new_end
    lease.save(update_fields=["end_date", "updated_at"])
    PropertyLeasePayment.objects.create(
        lease=lease,
        kind=PropertyLeasePaymentKind.RENEWAL,
        amount_minor=lease.rent_minor,
        currency=lease.currency,
        due_date=new_start,
    )
    application = lease.application
    _timeline_for_assignment(
        application.assignment if application else None,
        event_type=PropertyTimelineEventType.CONTRACT,
        title="Lease renewed",
        actor=actor,
        metadata={"lease_id": str(lease.id), "new_end_date": new_end.isoformat()},
    )
    return lease


@transaction.atomic
def schedule_move_workflow(
    *,
    lease: PropertyLease,
    phase: str,
    scheduled_at,
    actor: str,
    notes: str = "",
) -> PropertyMoveWorkflow:
    checklist = (
        list(DEFAULT_MOVE_IN_CHECKLIST)
        if phase == PropertyMovePhase.MOVE_IN
        else list(DEFAULT_MOVE_OUT_CHECKLIST)
    )
    workflow = PropertyMoveWorkflow.objects.create(
        lease=lease,
        phase=phase,
        scheduled_at=scheduled_at,
        checklist=checklist,
        notes=notes,
    )
    _timeline_for_assignment(
        lease.application.assignment if lease.application else None,
        event_type=PropertyTimelineEventType.MOVE,
        title=f"{phase.replace('_', ' ').title()} scheduled",
        actor=actor,
        metadata={"workflow_id": str(workflow.id)},
    )
    return workflow


@transaction.atomic
def complete_move_workflow(*, workflow: PropertyMoveWorkflow, actor: str) -> PropertyMoveWorkflow:
    lease = workflow.lease
    if actor not in {lease.tenant_principal, lease.owner_principal}:
        raise TransactionError("not authorized")
    workflow.status = PropertyMoveStatus.COMPLETED
    workflow.completed_at = timezone.now()
    checklist = list(workflow.checklist or [])
    for item in checklist:
        item["done"] = True
    workflow.checklist = checklist
    workflow.save()
    _timeline_for_assignment(
        lease.application.assignment if lease.application else None,
        event_type=PropertyTimelineEventType.MOVE,
        title=f"{workflow.phase.replace('_', ' ').title()} completed",
        actor=actor,
        metadata={"workflow_id": str(workflow.id)},
    )
    return workflow


def application_payload(application: PropertyApplication) -> dict[str, Any]:
    verifications = {
        v.check_kind: {
            "status": v.status,
            "provider_ref": v.provider_ref,
            "details": v.details,
            "verified_at": v.verified_at.isoformat() if v.verified_at else None,
        }
        for v in application.verifications.all()
    }
    return {
        "id": str(application.id),
        "listing_id": str(application.listing_id),
        "listing_title": application.listing.title,
        "status": application.status,
        "employment_status": application.employment_status,
        "monthly_income_minor": application.monthly_income_minor,
        "national_id_masked": _mask_id(application.national_id),
        "move_in_date": application.move_in_date.isoformat() if application.move_in_date else None,
        "notes": application.notes,
        "submitted_at": application.submitted_at.isoformat() if application.submitted_at else None,
        "verifications": verifications,
        "documents": [
            {
                "id": str(d.id),
                "kind": d.kind,
                "title": d.title,
                "url": d.url,
                "created_at": d.created_at.isoformat(),
            }
            for d in application.documents.all()
        ],
        "ready_for_approval": _verifications_complete(application),
        "created_at": application.created_at.isoformat(),
    }


def lease_payload(lease: PropertyLease) -> dict[str, Any]:
    return {
        "id": str(lease.id),
        "application_id": str(lease.application_id),
        "listing_id": str(lease.listing_id),
        "status": lease.status,
        "rent_minor": lease.rent_minor,
        "deposit_minor": lease.deposit_minor,
        "currency": lease.currency,
        "start_date": lease.start_date.isoformat(),
        "end_date": lease.end_date.isoformat(),
        "contract_text": lease.contract_text,
        "contract_url": lease.contract_url,
        "tenant_signed_at": lease.tenant_signed_at.isoformat() if lease.tenant_signed_at else None,
        "owner_signed_at": lease.owner_signed_at.isoformat() if lease.owner_signed_at else None,
        "payments": [
            {
                "id": str(p.id),
                "kind": p.kind,
                "status": p.status,
                "amount_minor": p.amount_minor,
                "currency": p.currency,
                "due_date": p.due_date.isoformat() if p.due_date else None,
                "paid_at": p.paid_at.isoformat() if p.paid_at else None,
                "payment_ref": p.payment_ref,
            }
            for p in lease.payments.all()
        ],
        "move_workflows": [
            {
                "id": str(w.id),
                "phase": w.phase,
                "status": w.status,
                "scheduled_at": w.scheduled_at.isoformat(),
                "checklist": w.checklist,
                "completed_at": w.completed_at.isoformat() if w.completed_at else None,
            }
            for w in lease.move_workflows.all()
        ],
    }


def _mask_id(national_id: str) -> str:
    if len(national_id) <= 4:
        return "****"
    return national_id[:2] + "***" + national_id[-2:]
