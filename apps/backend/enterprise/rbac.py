"""RBAC + lightweight ABAC for enterprise principals."""
from __future__ import annotations

from .models import PlatformPrincipal


class AccessDenied(Exception):
    pass


def principal(principal_id: str) -> PlatformPrincipal:
    return PlatformPrincipal.objects.prefetch_related("roles").get(principal_id=principal_id, active=True)


def permissions_for(p: PlatformPrincipal) -> set[str]:
    perms: set[str] = set()
    for role in p.roles.all():
        perms.update(role.permissions or [])
    return perms


def require(p: PlatformPrincipal, permission: str, *, attrs: dict | None = None) -> None:
    perms = permissions_for(p)
    if permission not in perms and "*" not in perms:
        raise AccessDenied(permission)
    required = attrs or {}
    for key, value in required.items():
        if key in p.attributes and p.attributes[key] != value:
            raise AccessDenied(f"attribute:{key}")
