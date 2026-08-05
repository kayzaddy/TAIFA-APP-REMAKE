"""Mobility authorization using shared Taifa identity + enterprise RBAC."""
from __future__ import annotations

from rest_framework.permissions import BasePermission

from enterprise.models import PlatformPrincipal
from enterprise.rbac import permissions_for


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


class IsMobilityOperator(BasePermission):
    message = "Mobility operations permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, "mobility.operations")


class CanManageStations(BasePermission):
    message = "Station management permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, "mobility.station.manage")


class CanViewNational(BasePermission):
    message = "National mobility operations permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, "mobility.operations") or has_permission(
            request, "mobility.national.read"
        )


class CanViewRegulatory(BasePermission):
    message = "Mobility regulatory reporting permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, "mobility.regulatory.read")


PERM_TRANSIT_VALIDATE = "mobility.transit.validate"
PERM_TRANSIT_DRIVER = "mobility.transit.driver"


class IsTransitValidator(BasePermission):
    message = "Transit ticket validation permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, PERM_TRANSIT_VALIDATE) or has_permission(
            request, "mobility.operations"
        )


class IsTransitDriver(BasePermission):
    message = "Transit driver permission required."

    def has_permission(self, request, view) -> bool:
        return has_permission(request, PERM_TRANSIT_DRIVER) or has_permission(
            request, "mobility.operations"
        )
