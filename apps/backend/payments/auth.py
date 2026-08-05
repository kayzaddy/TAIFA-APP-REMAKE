"""Device-bound token authentication.

The mobile client generates a stable `device_id`, registers once to receive an
opaque bearer token, and thereafter presents both on every call:

    Authorization: Bearer <token>
    X-Device-Id: <device_id>

We store only the SHA-256 of the token. Binding the token to the device id means
a leaked token is useless without the matching device header, and the server can
revoke a single device without touching others.
"""
from __future__ import annotations

import hashlib
import secrets

from rest_framework import authentication, exceptions, permissions

from .models import Device

_DEVICE_ID_HEADER = "X-Device-Id"


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def issue_token() -> str:
    return secrets.token_urlsafe(32)


class DeviceTokenAuthentication(authentication.BaseAuthentication):
    keyword = "bearer"

    def authenticate(self, request):
        header = authentication.get_authorization_header(request).decode("latin-1")
        if not header:
            return None
        parts = header.split()
        if parts[0].lower() != self.keyword:
            return None
        if len(parts) != 2:
            raise exceptions.AuthenticationFailed("Malformed Authorization header.")

        try:
            device = Device.objects.get(token_hash=hash_token(parts[1]))
        except Device.DoesNotExist:
            raise exceptions.AuthenticationFailed("Invalid or revoked device token.")

        presented = request.headers.get(_DEVICE_ID_HEADER)
        from django.conf import settings

        require_binding = bool(getattr(settings, "REQUIRE_DEVICE_BINDING", False))
        if require_binding and not presented:
            raise exceptions.AuthenticationFailed("X-Device-Id header is required.")
        if presented and presented != device.device_id:
            raise exceptions.AuthenticationFailed("Token is not bound to this device.")

        return (device, device)

    def authenticate_header(self, request):
        return "Bearer"


class IsDevice(permissions.BasePermission):
    message = "A registered device token is required."

    def has_permission(self, request, view) -> bool:
        return isinstance(getattr(request, "auth", None), Device)


# Teaches drf-spectacular how to document our device-bound bearer scheme so the
# OpenAPI/Swagger "Authorize" button works.
try:
    from drf_spectacular.extensions import OpenApiAuthenticationExtension

    class DeviceTokenScheme(OpenApiAuthenticationExtension):
        target_class = "payments.auth.DeviceTokenAuthentication"
        name = "DeviceToken"

        def get_security_definition(self, auto_schema):
            return {
                "type": "http",
                "scheme": "bearer",
                "description": (
                    "Device-bound token from `POST /auth/device/register`. Send it "
                    "as `Authorization: Bearer <token>` together with the "
                    "`X-Device-Id` header."
                ),
            }
except ImportError:  # pragma: no cover - drf-spectacular optional at runtime
    pass
