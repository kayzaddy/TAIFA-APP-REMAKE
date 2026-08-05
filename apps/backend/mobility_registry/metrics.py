from django.db.models import Count
from django.utils import timezone
from prometheus_client import Gauge

from payments.metrics import _registry

from .models import (
    ApplicationStatus,
    ApplicationType,
    ComplianceFinding,
    RegistryApplication,
    RegistryDocument,
    RegistryNotification,
)

APPLICATIONS = Gauge(
    "taifa_mobility_registry_applications",
    "Registry applications by type and status",
    ["type", "status"],
    registry=_registry,
)
EXPIRING_DOCUMENTS = Gauge(
    "taifa_mobility_registry_documents_expiring",
    "Current documents expiring within horizon",
    ["horizon_days"],
    registry=_registry,
)
OPEN_FINDINGS = Gauge(
    "taifa_mobility_registry_compliance_findings_open",
    "Open compliance findings by severity",
    ["severity"],
    registry=_registry,
)
NOTIFICATION_BACKLOG = Gauge(
    "taifa_mobility_registry_notification_backlog",
    "Registry notifications awaiting publication",
    registry=_registry,
)


def refresh_registry_metrics() -> None:
    counts = {
        (row["application_type"], row["status"]): row["count"]
        for row in RegistryApplication.objects.values(
            "application_type", "status"
        ).annotate(count=Count("id"))
    }
    for app_type, _ in ApplicationType.choices:
        for app_status, _ in ApplicationStatus.choices:
            APPLICATIONS.labels(type=app_type, status=app_status).set(
                counts.get((app_type, app_status), 0)
            )
    today = timezone.localdate()
    for days in (1, 7, 14, 30):
        EXPIRING_DOCUMENTS.labels(horizon_days=str(days)).set(
            RegistryDocument.objects.filter(
                current=True,
                expiry_date__gte=today,
                expiry_date__lte=today + timezone.timedelta(days=days),
            ).count()
        )
    finding_counts = {
        row["severity"]: row["count"]
        for row in ComplianceFinding.objects.filter(status="open")
        .values("severity")
        .annotate(count=Count("id"))
    }
    OPEN_FINDINGS.clear()
    for severity in ("critical", "high", "medium", "low", *finding_counts):
        OPEN_FINDINGS.labels(severity=severity).set(finding_counts.get(severity, 0))
    NOTIFICATION_BACKLOG.set(RegistryNotification.objects.filter(status="pending").count())
