"""Registry RBAC/ABAC built on shared enterprise principals."""
from __future__ import annotations

from enterprise.models import PlatformPrincipal
from enterprise.rbac import permissions_for


def request_owner(request) -> str:
    return str(getattr(getattr(request, "auth", None), "owner", "") or "")


def principal_for(request) -> PlatformPrincipal | None:
    owner = request_owner(request)
    if not owner:
        return None
    return (
        PlatformPrincipal.objects.prefetch_related("roles")
        .filter(principal_id=owner, active=True)
        .first()
    )


def has_registry_permission(request, permission: str) -> bool:
    principal = principal_for(request)
    if not principal:
        return False
    permissions = permissions_for(principal)
    return "*" in permissions or permission in permissions


def may_access_region(request, region: str) -> bool:
    principal = principal_for(request)
    if not principal:
        return False
    regions = (principal.attributes or {}).get("regions", [])
    return not regions or "*" in regions or region in regions
