"""Compliance monitoring and notification fan-out."""
from __future__ import annotations

from celery import shared_task
from django.db import transaction
from django.utils import timezone

from enterprise import event_bus

from .models import (
    ApplicationStatus,
    ComplianceFinding,
    DocumentStatus,
    RegistryApplication,
    RegistryDocument,
    RegistryNotification,
)
from .services import ActorContext, policy_for, suspend_application


@shared_task(name="mobility_registry.monitor_expiry")
def monitor_document_expiry() -> dict:
    today = timezone.localdate()
    checked = reminders = expired = suspended = 0
    applications = RegistryApplication.objects.filter(
        status=ApplicationStatus.APPROVED
    ).prefetch_related("documents")
    for application in applications.iterator(chunk_size=500):
        policy = policy_for(application)
        expiry_kinds = set(policy.expiry_required_kinds or [])
        reminder_days = {int(value) for value in (policy.reminder_days or [30, 14, 7, 1, 0])}
        for document in application.documents.filter(
            current=True,
            kind__in=expiry_kinds,
            expiry_date__isnull=False,
        ):
            checked += 1
            days = (document.expiry_date - today).days
            if days in reminder_days and days >= 0:
                _, created = RegistryNotification.objects.get_or_create(
                    deduplication_key=f"document-expiry:{document.id}:{days}",
                    defaults={
                        "recipient_principal": application.applicant_principal,
                        "event_type": "mobility.registry.document_expiring",
                        "application": application,
                        "payload": {
                            "document_kind": document.kind,
                            "days_remaining": days,
                            "expiry_date": str(document.expiry_date),
                        },
                    },
                )
                reminders += int(created)
            if days < 0 and document.status != DocumentStatus.EXPIRED:
                with transaction.atomic():
                    locked = RegistryDocument.objects.select_for_update().get(pk=document.pk)
                    locked.status = DocumentStatus.EXPIRED
                    locked.save(update_fields=["status"])
                    ComplianceFinding.objects.get_or_create(
                        application=application,
                        code=f"document_expired:{document.kind}",
                        status="open",
                        defaults={
                            "severity": "critical",
                            "details": {
                                "document_id": str(document.id),
                                "kind": document.kind,
                                "expiry_date": str(document.expiry_date),
                            },
                        },
                    )
                    RegistryNotification.objects.get_or_create(
                        deduplication_key=f"document-expired:{document.id}",
                        defaults={
                            "recipient_principal": application.applicant_principal,
                            "event_type": "mobility.registry.document_expired",
                            "application": application,
                            "payload": {"document_kind": document.kind},
                        },
                    )
                    expired += 1
                if policy.suspend_on_expiry and application.status == ApplicationStatus.APPROVED:
                    suspend_application(
                        application.id,
                        actor=ActorContext(principal="system:registry-expiry"),
                        reason=f"required document expired: {document.kind}",
                    )
                    suspended += 1
    return {
        "checked": checked,
        "reminders": reminders,
        "expired": expired,
        "suspended": suspended,
    }


@shared_task(name="mobility_registry.publish_notifications")
def publish_registry_notifications(limit: int = 500) -> dict:
    delivered = 0
    rows = list(
        RegistryNotification.objects.filter(status="pending")
        .select_related("application")
        .order_by("created_at")[:limit]
    )
    for row in rows:
        event_bus.publish(
            row.event_type,
            aggregate_type="registry_notification",
            aggregate_id=str(row.id),
            owner=row.recipient_principal,
            payload={
                **row.payload,
                "recipient_principal": row.recipient_principal,
                "application_id": str(row.application_id) if row.application_id else None,
            },
        )
        row.status = "published"
        row.published_at = timezone.now()
        row.save(update_fields=["status", "published_at"])
        delivered += 1
    return {"published": delivered}
