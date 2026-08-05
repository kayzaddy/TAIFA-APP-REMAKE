"""Winga Property ops RBAC — enterprise PlatformPrincipal permissions."""
from __future__ import annotations

from rest_framework.permissions import BasePermission

from enterprise.models import PlatformPrincipal
from enterprise.rbac import permissions_for


PERM_OPS_READ = "winga.property.ops.read"
PERM_OPS_WRITE = "winga.property.ops.write"


def owner_of(request) -> str:
    return str(getattr(getattr(request, "auth", None), "owner", "") or "")


def has_permission(request, permission: str) -> bool:
    owner = owner_of(request)
    if not owner:
        return False
    try:
        principal = PlatformPrincipal.objects.prefetch_related("roles").get(
            principal_id=owner,
            active=True,
        )
    except PlatformPrincipal.DoesNotExist:
        return False
    permissions = permissions_for(principal)
    return "*" in permissions or permission in permissions


class IsPropertyOpsReader(BasePermission):
    message = "Winga Property ops read permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, PERM_OPS_READ) or has_permission(request, PERM_OPS_WRITE)


class IsPropertyOpsWriter(BasePermission):
    message = "Winga Property ops write permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, PERM_OPS_WRITE)
