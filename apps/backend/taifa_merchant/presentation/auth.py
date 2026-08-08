from __future__ import annotations

from dataclasses import dataclass
from typing import Any
from uuid import UUID

import jwt
from django.conf import settings
from rest_framework import authentication, exceptions, permissions

from taifa_merchant.domain.enums import ROLE_PERMISSIONS
from taifa_merchant.infrastructure.identity.jwt_tokens import decode_access_token
from taifa_merchant.infrastructure.models import Employee, Merchant


@dataclass
class MerchantPrincipal:
    user_id: UUID
    email: str
    merchant_id: UUID | None
    roles: list[str]

    def has_permission(self, permission: str) -> bool:
        for role in self.roles:
            perms = ROLE_PERMISSIONS.get(role, frozenset())
            if permission in perms:
                return True
        return False


class MerchantJWTAuthentication(authentication.BaseAuthentication):
    keyword = "bearer"

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).decode("latin-1")
        if not header:
            return None
        parts = header.split()
        if parts[0].lower() != self.keyword or len(parts) != 2:
            raise exceptions.AuthenticationFailed("Malformed Authorization header.")
        try:
            claims = decode_access_token(parts[1])
        except jwt.PyJWTError as exc:
            raise exceptions.AuthenticationFailed("Invalid token.") from exc
        merchant_id = claims.get("merchant_id")
        principal = MerchantPrincipal(
            user_id=UUID(claims["sub"]),
            email=claims.get("email", ""),
            merchant_id=UUID(merchant_id) if merchant_id else None,
            roles=list(claims.get("roles") or []),
        )
        return (principal, principal)


class IsMerchantAuthenticated(permissions.BasePermission):
    def has_permission(self, request, view) -> bool:
        return isinstance(getattr(request, "user", None), MerchantPrincipal)


class HasMerchantPermission(permissions.BasePermission):
    required_permission = "merchant:read"

    def has_permission(self, request, view) -> bool:
        user = getattr(request, "user", None)
        if not isinstance(user, MerchantPrincipal):
            return False
        perm = getattr(view, "required_permission", self.required_permission)
        return user.has_permission(perm)


def require_merchant_context(principal: MerchantPrincipal) -> UUID:
    if principal.merchant_id is None:
        raise exceptions.PermissionDenied("Complete merchant registration first.")
    if not Merchant.objects.filter(pk=principal.merchant_id).exists():
        raise exceptions.PermissionDenied("Merchant not found.")
    return principal.merchant_id


def current_employee(principal: MerchantPrincipal, merchant_id: UUID) -> Employee | None:
    return Employee.objects.filter(
        merchant_id=merchant_id,
        identity_user_id=principal.user_id,
        status="active",
    ).first()


# Teaches drf-spectacular how to document this bearer scheme (mirrors
# payments.auth.DeviceTokenScheme) so schema generation doesn't warn.
try:
    from drf_spectacular.extensions import OpenApiAuthenticationExtension

    class MerchantJWTScheme(OpenApiAuthenticationExtension):
        target_class = "taifa_merchant.presentation.auth.MerchantJWTAuthentication"
        name = "MerchantJWT"

        def get_security_definition(self, auto_schema):
            return {
                "type": "http",
                "scheme": "bearer",
                "bearerFormat": "JWT",
                "description": "Merchant BFF session token from the login/register endpoints.",
            }
except ImportError:  # pragma: no cover - drf-spectacular optional at runtime
    pass
