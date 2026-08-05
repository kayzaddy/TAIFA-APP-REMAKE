"""Append-only audit log — answers who/when/where, never money truth."""
from __future__ import annotations

from .models import AuditRecord


def record(
    *,
    actor: str,
    action: str,
    resource_type: str,
    resource_id: str = "",
    ip: str | None = None,
    device_id: str = "",
    reason: str = "",
    before: dict | None = None,
    after: dict | None = None,
    metadata: dict | None = None,
) -> AuditRecord:
    return AuditRecord.objects.create(
        actor=actor,
        action=action,
        resource_type=resource_type,
        resource_id=str(resource_id),
        ip=ip,
        device_id=device_id or "",
        reason=reason,
        before=before,
        after=after,
        metadata=metadata or {},
    )
