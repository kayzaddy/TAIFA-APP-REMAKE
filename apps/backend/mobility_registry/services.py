"""Transactional commands for registration, review, approval and compliance."""
from __future__ import annotations

import hashlib
import uuid
from dataclasses import dataclass
from datetime import date

from django.db import transaction
from django.db.models import Max, Q
from django.utils import timezone

from enterprise import event_bus
from enterprise.models import Merchant, MerchantStatus
from payments import audit
from trips.models import (
    Driver,
    DriverAvailability,
    DriverStatus,
    Fleet,
    Station,
    Vehicle,
    VehicleStatus,
    VerificationStatus,
)

from .adapters import adapter_for
from .crypto import blind_index, decrypt_bytes, encrypt_bytes, encrypt_text, mask
from .document_security import DocumentSecurityError, scan_document
from .models import (
    ApplicationStatus,
    ApplicationType,
    BlacklistEntry,
    ComplianceFinding,
    CompliancePolicy,
    DocumentStatus,
    DriverRegistration,
    ExternalVerificationRequest,
    FleetRegistration,
    RegistryApplication,
    RegistryDocument,
    RegistryNotification,
    StationRegistration,
    VehicleRegistration,
    VerificationStage,
    WorkflowTransition,
)


class RegistryError(Exception):
    pass


STAGE_ORDER = [
    VerificationStage.DOCUMENT_VALIDATION,
    VerificationStage.IDENTITY_VALIDATION,
    VerificationStage.VEHICLE_VALIDATION,
    VerificationStage.STATION_VALIDATION,
    VerificationStage.COMPLIANCE_REVIEW,
    VerificationStage.APPROVAL,
]


@dataclass(frozen=True)
class ActorContext:
    principal: str
    ip_address: str | None = None
    device_id: str = ""


def _application_number(application_type: str) -> str:
    prefix = {
        ApplicationType.DRIVER: "DRV",
        ApplicationType.VEHICLE: "VEH",
        ApplicationType.STATION: "STN",
        ApplicationType.FLEET: "FLT",
        ApplicationType.TRANSPORT_COMPANY: "TRC",
    }[application_type]
    return f"{prefix}-{timezone.now():%Y}-{uuid.uuid4().hex[:12].upper()}"


def _record_transition(
    application: RegistryApplication,
    *,
    previous_status: str,
    previous_stage: str,
    actor: ActorContext,
    reason: str = "",
    comments: str = "",
) -> None:
    WorkflowTransition.objects.create(
        application=application,
        from_status=previous_status,
        to_status=application.status,
        from_stage=previous_stage,
        to_stage=application.stage,
        actor=actor.principal,
        reason=reason,
        comments=comments,
        ip_address=actor.ip_address,
        device_id=actor.device_id,
    )
    audit.record(
        actor=actor.principal,
        action="mobility_registry.transition",
        resource_type="registry_application",
        resource_id=str(application.id),
        ip=actor.ip_address,
        device_id=actor.device_id,
        reason=reason,
        before={"status": previous_status, "stage": previous_stage},
        after={"status": application.status, "stage": application.stage},
    )
    event_bus.publish(
        f"mobility.registry.{application.status}",
        aggregate_type="registry_application",
        aggregate_id=str(application.id),
        owner=application.applicant_principal,
        payload={
            "application_number": application.application_number,
            "application_type": application.application_type,
            "stage": application.stage,
        },
    )


def _notify(application: RegistryApplication, event_type: str, payload: dict | None = None) -> None:
    RegistryNotification.objects.get_or_create(
        deduplication_key=f"{event_type}:{application.id}:{application.version}",
        defaults={
            "recipient_principal": application.applicant_principal,
            "event_type": event_type,
            "application": application,
            "payload": payload or {},
        },
    )


@transaction.atomic
def create_application(
    *,
    application_type: str,
    applicant_principal: str,
    client_reference: str,
    region: str,
    district: str,
    actor: ActorContext | None = None,
) -> RegistryApplication:
    existing = RegistryApplication.objects.filter(
        applicant_principal=applicant_principal,
        client_reference=client_reference,
    ).first()
    if existing:
        return existing
    application = RegistryApplication.objects.create(
        application_number=_application_number(application_type),
        application_type=application_type,
        applicant_principal=applicant_principal,
        client_reference=client_reference,
        region=region,
        district=district,
    )
    context = actor or ActorContext(principal=applicant_principal)
    audit.record(
        actor=context.principal,
        action="mobility_registry.application.create",
        resource_type="registry_application",
        resource_id=str(application.id),
        ip=context.ip_address,
        device_id=context.device_id,
        after={
            "application_number": application.application_number,
            "application_type": application_type,
            "region": region,
            "district": district,
        },
    )
    return application


def encrypted_text_fields(value: str, *, context: str) -> tuple[bytes, bytes]:
    encrypted = encrypt_text(value, context=context)
    return encrypted.ciphertext, encrypted.nonce


def policy_for(application: RegistryApplication) -> CompliancePolicy:
    policy = (
        CompliancePolicy.objects.filter(
            application_type=application.application_type,
            active=True,
            effective_from__lte=timezone.now(),
        )
        .order_by("-version", "-effective_from")
        .first()
    )
    if policy is None:
        raise RegistryError(f"no active compliance policy for {application.application_type}")
    return policy


def required_document_kinds(application: RegistryApplication) -> set[str]:
    policy = policy_for(application)
    required = set(policy.required_document_kinds or [])
    if application.application_type == ApplicationType.DRIVER:
        if policy.police_clearance_required:
            required.add("police_clearance")
        if policy.medical_certificate_required:
            required.add("medical_certificate")
    return required


@transaction.atomic
def upload_document(
    *,
    application_id,
    actor: ActorContext,
    kind: str,
    original_name: str,
    content_type: str,
    payload: bytes,
    document_number: str = "",
    issue_date: date | None = None,
    expiry_date: date | None = None,
) -> RegistryDocument:
    application = RegistryApplication.objects.select_for_update().get(pk=application_id)
    if actor.principal != application.applicant_principal:
        raise RegistryError("only the applicant may upload documents")
    if application.status in {
        ApplicationStatus.APPROVED,
        ApplicationStatus.BLOCKED,
    }:
        raise RegistryError("application does not accept applicant document changes")
    allowed_types = {
        "application/pdf",
        "image/jpeg",
        "image/png",
        "image/webp",
    }
    if content_type not in allowed_types:
        raise RegistryError("unsupported document content type")
    max_bytes = 10 * 1024 * 1024
    if not payload or len(payload) > max_bytes:
        raise RegistryError("document must be between 1 byte and 10 MiB")
    try:
        scan_document(
            payload=payload,
            filename=original_name,
            content_type=content_type,
        )
    except DocumentSecurityError as exc:
        raise RegistryError(str(exc)) from exc
    required = required_document_kinds(application)
    optional = {
        "passport",
        "tin_certificate",
        "medical_certificate",
        "police_clearance",
        "emission_certificate",
        "station_photo",
    }
    if kind not in required | optional:
        raise RegistryError("document kind is not allowed for this application")

    digest = hashlib.sha256(payload).hexdigest()
    if RegistryDocument.objects.filter(
        application=application,
        kind=kind,
        sha256=digest,
        current=True,
    ).exists():
        return RegistryDocument.objects.get(
            application=application,
            kind=kind,
            sha256=digest,
            current=True,
        )
    current = RegistryDocument.objects.filter(
        application=application,
        kind=kind,
        current=True,
    ).first()
    version = (RegistryDocument.objects.filter(
        application=application, kind=kind
    ).aggregate(value=Max("version"))["value"] or 0) + 1
    encrypted = encrypt_bytes(payload, context=f"registry-document:{application.id}:{kind}:{version}")
    number_ciphertext = number_nonce = None
    number_hash = number_masked = ""
    if document_number:
        number = encrypt_text(
            document_number,
            context=f"registry-document-number:{application.id}:{kind}:{version}",
        )
        number_ciphertext, number_nonce = number.ciphertext, number.nonce
        number_hash = blind_index(document_number)
        number_masked = mask(document_number)
    if current:
        current.current = False
        current.status = DocumentStatus.SUPERSEDED
        current.save(update_fields=["current", "status"])
    document = RegistryDocument.objects.create(
        application=application,
        kind=kind,
        version=version,
        original_name=original_name[:255],
        content_type=content_type,
        size_bytes=len(payload),
        sha256=digest,
        encrypted_payload=encrypted.ciphertext,
        encryption_nonce=encrypted.nonce,
        encryption_key_version=encrypted.key_version,
        document_number_ciphertext=number_ciphertext,
        document_number_nonce=number_nonce,
        document_number_hash=number_hash,
        document_number_masked=number_masked,
        issue_date=issue_date,
        expiry_date=expiry_date,
        uploaded_by=actor.principal,
    )
    application.version += 1
    application.save(update_fields=["version", "updated_at"])
    audit.record(
        actor=actor.principal,
        action="mobility_registry.document.upload",
        resource_type="registry_document",
        resource_id=str(document.id),
        ip=actor.ip_address,
        device_id=actor.device_id,
        after={
            "application_id": str(application.id),
            "kind": kind,
            "version": version,
            "sha256": digest,
        },
    )
    return document


def decrypt_document(document: RegistryDocument, *, actor: ActorContext) -> bytes:
    audit.record(
        actor=actor.principal,
        action="mobility_registry.document.download",
        resource_type="registry_document",
        resource_id=str(document.id),
        ip=actor.ip_address,
        device_id=actor.device_id,
        metadata={"application_id": str(document.application_id)},
    )
    return decrypt_bytes(
        document.encrypted_payload,
        document.encryption_nonce,
        key_version=document.encryption_key_version,
        context=f"registry-document:{document.application_id}:{document.kind}:{document.version}",
    )


@transaction.atomic
def submit_application(application_id, *, actor: ActorContext) -> RegistryApplication:
    application = RegistryApplication.objects.select_for_update().get(pk=application_id)
    if application.applicant_principal != actor.principal:
        raise RegistryError("application ownership mismatch")
    if application.status not in {
        ApplicationStatus.DRAFT,
        ApplicationStatus.DOCUMENTS_MISSING,
        ApplicationStatus.REJECTED,
    }:
        raise RegistryError(f"cannot submit from {application.status}")
    previous_status, previous_stage = application.status, application.stage
    present = set(
        application.documents.filter(current=True)
        .exclude(status=DocumentStatus.REJECTED)
        .values_list("kind", flat=True)
    )
    missing = sorted(required_document_kinds(application) - present)
    application.version += 1
    if missing:
        application.status = ApplicationStatus.DOCUMENTS_MISSING
        application.stage = VerificationStage.DOCUMENT_VALIDATION
        application.save(update_fields=["status", "stage", "version", "updated_at"])
        _record_transition(
            application,
            previous_status=previous_status,
            previous_stage=previous_stage,
            actor=actor,
            reason="missing required documents",
            comments=", ".join(missing),
        )
        _notify(application, "mobility.registry.documents_missing", {"missing": missing})
        return application
    application.status = ApplicationStatus.SUBMITTED
    application.stage = VerificationStage.DOCUMENT_VALIDATION
    application.submitted_at = timezone.now()
    application.rejection_reason = ""
    application.save(
        update_fields=[
            "status",
            "stage",
            "submitted_at",
            "rejection_reason",
            "version",
            "updated_at",
        ]
    )
    _record_transition(
        application,
        previous_status=previous_status,
        previous_stage=previous_stage,
        actor=actor,
    )
    _notify(application, "mobility.registry.application_submitted")
    return application


@transaction.atomic
def review_document(
    document_id,
    *,
    actor: ActorContext,
    decision: str,
    reason: str = "",
) -> RegistryDocument:
    if decision not in {DocumentStatus.VERIFIED, DocumentStatus.REJECTED}:
        raise RegistryError("invalid document decision")
    document = RegistryDocument.objects.select_for_update().select_related("application").get(
        pk=document_id,
        current=True,
    )
    if document.application.applicant_principal == actor.principal:
        raise RegistryError("maker cannot review their own document")
    if decision == DocumentStatus.REJECTED and not reason.strip():
        raise RegistryError("rejection reason is required")
    before = document.status
    document.status = decision
    document.reviewer = actor.principal
    document.reviewed_at = timezone.now()
    document.rejection_reason = reason.strip()
    document.save(
        update_fields=["status", "reviewer", "reviewed_at", "rejection_reason"]
    )
    audit.record(
        actor=actor.principal,
        action="mobility_registry.document.review",
        resource_type="registry_document",
        resource_id=str(document.id),
        ip=actor.ip_address,
        device_id=actor.device_id,
        reason=reason,
        before={"status": before},
        after={"status": decision},
    )
    if decision == DocumentStatus.REJECTED:
        application = document.application
        application.status = ApplicationStatus.DOCUMENTS_MISSING
        application.version += 1
        application.save(update_fields=["status", "version", "updated_at"])
        _notify(
            application,
            "mobility.registry.document_rejected",
            {"kind": document.kind, "reason": reason},
        )
    return document


def compliance_failures(application: RegistryApplication) -> list[dict]:
    failures: list[dict] = []
    today = timezone.localdate()
    documents = {
        row.kind: row
        for row in application.documents.filter(current=True)
    }
    for kind in sorted(required_document_kinds(application)):
        document = documents.get(kind)
        if not document:
            failures.append({"code": "document_missing", "kind": kind})
        elif document.status != DocumentStatus.VERIFIED:
            failures.append(
                {"code": "document_not_verified", "kind": kind, "status": document.status}
            )
        elif document.expiry_date and document.expiry_date < today:
            failures.append({"code": "document_expired", "kind": kind})
    identifiers: list[tuple[str, str]] = []
    if application.application_type == ApplicationType.DRIVER:
        identifiers.append(("national_id", application.driver.national_id_hash))
    elif application.application_type == ApplicationType.VEHICLE:
        identifiers.extend(
            [
                ("chassis_number", application.vehicle.chassis_number_hash),
                ("engine_number", application.vehicle.engine_number_hash),
                ("registration_number", application.vehicle.registration_number_hash),
            ]
        )
    for identifier_type, identifier_hash in identifiers:
        if BlacklistEntry.objects.filter(
            identifier_type=identifier_type,
            identifier_hash=identifier_hash,
            active=True,
        ).filter(Q(expires_at__isnull=True) | Q(expires_at__gt=timezone.now())).exists():
            failures.append({"code": "blacklisted", "identifier_type": identifier_type})
    return failures


@transaction.atomic
def advance_stage(
    application_id,
    *,
    actor: ActorContext,
    comments: str = "",
) -> RegistryApplication:
    application = RegistryApplication.objects.select_for_update().get(pk=application_id)
    if application.applicant_principal == actor.principal:
        raise RegistryError("applicant cannot review their own application")
    if application.status not in {
        ApplicationStatus.SUBMITTED,
        ApplicationStatus.PENDING_REVIEW,
    }:
        raise RegistryError(f"cannot review from {application.status}")
    previous_status, previous_stage = application.status, application.stage
    if application.stage == VerificationStage.DOCUMENT_VALIDATION:
        failures = compliance_failures(application)
        document_failures = [f for f in failures if f["code"].startswith("document_")]
        if document_failures:
            raise RegistryError("required documents are not verified")
    try:
        index = STAGE_ORDER.index(application.stage)
    except ValueError as exc:
        raise RegistryError("application is not in a review stage") from exc
    if index >= len(STAGE_ORDER) - 1:
        raise RegistryError("application is awaiting final approval")
    next_stage = STAGE_ORDER[index + 1]
    # Entity-specific stages are skipped when they do not apply.
    if next_stage == VerificationStage.VEHICLE_VALIDATION and application.application_type != ApplicationType.VEHICLE:
        next_stage = VerificationStage.STATION_VALIDATION
    if next_stage == VerificationStage.STATION_VALIDATION and application.application_type != ApplicationType.STATION:
        next_stage = VerificationStage.COMPLIANCE_REVIEW
    application.status = ApplicationStatus.PENDING_REVIEW
    application.stage = next_stage
    application.assigned_reviewer = actor.principal
    application.version += 1
    application.save(
        update_fields=["status", "stage", "assigned_reviewer", "version", "updated_at"]
    )
    _record_transition(
        application,
        previous_status=previous_status,
        previous_stage=previous_stage,
        actor=actor,
        comments=comments,
    )
    return application


@transaction.atomic
def request_external_verification(
    application_id,
    *,
    actor: ActorContext,
    provider: str,
    check_type: str,
    attributes: dict,
) -> ExternalVerificationRequest:
    application = RegistryApplication.objects.select_for_update().get(pk=application_id)
    adapter = adapter_for(provider)
    if check_type not in adapter.supported_checks:
        raise RegistryError("verification check is unsupported by provider")
    reference = f"{provider}:{application.id}:{check_type}:{application.version}"
    request, created = ExternalVerificationRequest.objects.get_or_create(
        request_reference=reference,
        defaults={
            "application": application,
            "provider": provider,
            "check_type": check_type,
            "request_payload": {"attribute_names": sorted(attributes)},
            "requested_by": actor.principal,
        },
    )
    if not created and request.status in {"verified", "rejected"}:
        return request
    result = adapter.verify(
        check_type=check_type,
        subject_reference=str(application.id),
        attributes=attributes,
    )
    request.status = "verified" if result.verified else "rejected"
    request.response_payload = {
        "provider_reference": result.provider_reference,
        "status": result.status,
        "attributes": result.attributes,
    }
    request.completed_at = timezone.now()
    request.save(update_fields=["status", "response_payload", "completed_at"])
    audit.record(
        actor=actor.principal,
        action="mobility_registry.external_verification",
        resource_type="registry_application",
        resource_id=str(application.id),
        after={"provider": provider, "check_type": check_type, "status": request.status},
    )
    return request


def _approval_reference(application: RegistryApplication) -> str:
    return f"MRA-{application.application_type.upper()}-{application.id.hex.upper()}"


def _project_approved(application: RegistryApplication) -> uuid.UUID:
    approval_id = application.id
    if application.application_type == ApplicationType.DRIVER:
        profile = application.driver
        driver, _ = Driver.objects.update_or_create(
            owner_principal=application.applicant_principal,
            defaults={
                "full_name": profile.full_name,
                "phone_masked": profile.phone_masked,
                "national_id_hash": profile.national_id_hash,
                "identity_status": VerificationStatus.VERIFIED,
                "license_status": VerificationStatus.VERIFIED,
                "status": DriverStatus.ACTIVE,
                "availability": DriverAvailability.OFFLINE,
                "station": profile.preferred_station,
                "registry_approval_id": approval_id,
            },
        )
        return driver.id
    if application.application_type == ApplicationType.VEHICLE:
        profile = application.vehicle
        assigned_driver = None
        if profile.assigned_driver_application_id:
            assigned_id = profile.assigned_driver_application.operational_object_id
            assigned_driver = Driver.objects.filter(pk=assigned_id).first()
        vehicle, _ = Vehicle.objects.update_or_create(
            registration_number=profile.registration_number,
            defaults={
                "mode": profile.mode,
                "make": profile.make,
                "model": profile.model,
                "color": profile.color,
                "capacity": profile.capacity,
                "owner_principal": profile.owner_principal,
                "assigned_driver": assigned_driver,
                "insurance_status": VerificationStatus.VERIFIED,
                "road_license_status": VerificationStatus.VERIFIED,
                "inspection_status": VerificationStatus.VERIFIED,
                "status": VehicleStatus.ACTIVE,
                "registry_approval_id": approval_id,
            },
        )
        return vehicle.id
    if application.application_type == ApplicationType.STATION:
        profile = application.station
        merchant_code = f"station-{profile.code}".lower().replace(" ", "-")[:64]
        merchant, _ = Merchant.objects.get_or_create(
            code=merchant_code,
            defaults={
                "legal_name": profile.name,
                "trading_name": profile.name,
                "status": MerchantStatus.ACTIVE,
                "sector": "mobility",
                "mcc": "4121",
                "owner_principal": profile.manager_principal,
                "metadata": {
                    "station_code": profile.code,
                    "registry_application_id": str(application.id),
                },
            },
        )
        if merchant.status != MerchantStatus.ACTIVE:
            merchant.status = MerchantStatus.ACTIVE
            merchant.save(update_fields=["status", "updated_at"])
        station, _ = Station.objects.update_or_create(
            code=profile.code,
            defaults={
                "name": profile.name,
                "latitude": profile.latitude,
                "longitude": profile.longitude,
                "region": application.region,
                "district": application.district,
                "ward": profile.ward,
                "street": profile.street,
                "capacity": profile.capacity,
                "operating_hours": profile.operating_hours,
                "manager_principal": profile.manager_principal,
                "active": True,
                "verification_status": VerificationStatus.VERIFIED,
                "registry_approval_id": approval_id,
                "payment_merchant": merchant,
            },
        )
        return station.id
    profile = application.fleet
    fleet, _ = Fleet.objects.update_or_create(
        owner_principal=profile.owner_principal,
        name=profile.business_name,
        defaults={
            "fleet_type": profile.fleet_type,
            "registration_number": profile.business_license_number,
            "status": VerificationStatus.VERIFIED,
            "registry_approval_id": approval_id,
        },
    )
    return fleet.id


@transaction.atomic
def approve_application(
    application_id,
    *,
    actor: ActorContext,
    comments: str = "",
) -> RegistryApplication:
    application = RegistryApplication.objects.select_for_update().get(pk=application_id)
    if application.applicant_principal == actor.principal:
        raise RegistryError("maker cannot approve their own application")
    if application.stage != VerificationStage.APPROVAL or application.status != ApplicationStatus.PENDING_REVIEW:
        raise RegistryError("application has not completed the review workflow")
    failures = compliance_failures(application)
    if failures:
        for failure in failures:
            ComplianceFinding.objects.get_or_create(
                application=application,
                code=f"{failure['code']}:{failure.get('kind', failure.get('identifier_type', ''))}",
                status="open",
                defaults={
                    "severity": "critical",
                    "details": failure,
                },
            )
        raise RegistryError("application has unresolved compliance failures")
    previous_status, previous_stage = application.status, application.stage
    operational_id = _project_approved(application)
    application.status = ApplicationStatus.APPROVED
    application.stage = VerificationStage.COMPLETE
    application.approval_reference = _approval_reference(application)
    application.operational_object_id = operational_id
    application.approved_at = timezone.now()
    application.assigned_reviewer = actor.principal
    application.version += 1
    application.save(
        update_fields=[
            "status",
            "stage",
            "approval_reference",
            "operational_object_id",
            "approved_at",
            "assigned_reviewer",
            "version",
            "updated_at",
        ]
    )
    _record_transition(
        application,
        previous_status=previous_status,
        previous_stage=previous_stage,
        actor=actor,
        comments=comments,
    )
    _notify(application, "mobility.registry.application_approved")
    return application


@transaction.atomic
def reject_application(
    application_id,
    *,
    actor: ActorContext,
    reason: str,
    comments: str = "",
) -> RegistryApplication:
    if not reason.strip():
        raise RegistryError("rejection reason is required")
    application = RegistryApplication.objects.select_for_update().get(pk=application_id)
    if application.applicant_principal == actor.principal:
        raise RegistryError("applicant cannot reject their own application")
    if application.status not in {
        ApplicationStatus.SUBMITTED,
        ApplicationStatus.PENDING_REVIEW,
        ApplicationStatus.DOCUMENTS_MISSING,
    }:
        raise RegistryError(f"cannot reject from {application.status}")
    previous_status, previous_stage = application.status, application.stage
    application.status = ApplicationStatus.REJECTED
    application.rejection_reason = reason.strip()
    application.rejected_at = timezone.now()
    application.assigned_reviewer = actor.principal
    application.version += 1
    application.save(
        update_fields=[
            "status",
            "rejection_reason",
            "rejected_at",
            "assigned_reviewer",
            "version",
            "updated_at",
        ]
    )
    _record_transition(
        application,
        previous_status=previous_status,
        previous_stage=previous_stage,
        actor=actor,
        reason=reason,
        comments=comments,
    )
    _notify(application, "mobility.registry.application_rejected", {"reason": reason})
    return application


def _suspend_projection(application: RegistryApplication, *, reason: str = "") -> None:
    object_id = application.operational_object_id
    if not object_id:
        return
    if application.application_type == ApplicationType.DRIVER:
        Driver.objects.filter(pk=object_id).update(
            status=DriverStatus.SUSPENDED,
            availability=DriverAvailability.OFFLINE,
        )
    elif application.application_type == ApplicationType.VEHICLE:
        vehicle_status = VehicleStatus.SUSPENDED
        if "insurance" in reason:
            vehicle_status = VehicleStatus.EXPIRED_INSURANCE
        elif "road_license" in reason:
            vehicle_status = VehicleStatus.EXPIRED_ROAD_LICENSE
        elif "inspection" in reason:
            vehicle_status = VehicleStatus.EXPIRED_INSPECTION
        Vehicle.objects.filter(pk=object_id).update(status=vehicle_status)
    elif application.application_type == ApplicationType.STATION:
        Station.objects.filter(pk=object_id).update(
            active=False,
            verification_status=VerificationStatus.SUSPENDED,
        )
    else:
        Fleet.objects.filter(pk=object_id).update(status=VerificationStatus.SUSPENDED)


@transaction.atomic
def add_blacklist_entry(
    *,
    identifier_type: str,
    identifier: str,
    reason: str,
    actor: ActorContext,
) -> BlacklistEntry:
    allowed = {"national_id", "registration_number", "chassis_number", "engine_number"}
    if identifier_type not in allowed:
        raise RegistryError("unsupported blacklist identifier type")
    if not identifier.strip() or not reason.strip():
        raise RegistryError("identifier and reason are required")
    digest = blind_index(identifier)
    entry, created = BlacklistEntry.objects.get_or_create(
        identifier_type=identifier_type,
        identifier_hash=digest,
        active=True,
        defaults={"reason": reason.strip(), "created_by": actor.principal},
    )
    if not created:
        return entry
    application_ids = []
    if identifier_type == "national_id":
        application_ids = DriverRegistration.objects.filter(
            national_id_hash=digest
        ).values_list("application_id", flat=True)
    else:
        lookup = {
            "registration_number": "registration_number_hash",
            "chassis_number": "chassis_number_hash",
            "engine_number": "engine_number_hash",
        }[identifier_type]
        application_ids = VehicleRegistration.objects.filter(
            **{lookup: digest}
        ).values_list("application_id", flat=True)
    for application in RegistryApplication.objects.filter(
        id__in=application_ids,
        status=ApplicationStatus.APPROVED,
    ):
        suspend_application(
            application.id,
            actor=actor,
            reason=f"blacklist: {reason.strip()}",
        )
    audit.record(
        actor=actor.principal,
        action="mobility_registry.blacklist.add",
        resource_type="registry_blacklist",
        resource_id=str(entry.id),
        ip=actor.ip_address,
        device_id=actor.device_id,
        reason=reason,
        after={"identifier_type": identifier_type, "identifier_hash": digest},
    )
    return entry


@transaction.atomic
def suspend_application(
    application_id,
    *,
    actor: ActorContext,
    reason: str,
) -> RegistryApplication:
    if not reason.strip():
        raise RegistryError("suspension reason is required")
    application = RegistryApplication.objects.select_for_update().get(pk=application_id)
    if application.status != ApplicationStatus.APPROVED:
        raise RegistryError("only approved applications can be suspended")
    previous_status, previous_stage = application.status, application.stage
    application.status = ApplicationStatus.SUSPENDED
    application.suspended_at = timezone.now()
    application.version += 1
    application.save(update_fields=["status", "suspended_at", "version", "updated_at"])
    _suspend_projection(application, reason=reason)
    _record_transition(
        application,
        previous_status=previous_status,
        previous_stage=previous_stage,
        actor=actor,
        reason=reason,
    )
    _notify(application, "mobility.registry.application_suspended", {"reason": reason})
    return application
