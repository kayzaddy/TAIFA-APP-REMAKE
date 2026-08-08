from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

import jwt
from django.conf import settings

from taifa_merchant.infrastructure.models import MerchantIdentityUser


def _hash_password(password: str) -> str:
    salt = getattr(settings, "MERCHANT_AUTH_PEPPER", "taifa-merchant-dev")
    return hashlib.sha256(f"{salt}:{password}".encode()).hexdigest()


def verify_password(user: MerchantIdentityUser, password: str) -> bool:
    return user.password_hash == _hash_password(password)


def set_password(user: MerchantIdentityUser, password: str) -> None:
    user.password_hash = _hash_password(password)


def issue_access_token(
    *,
    user_id: UUID,
    email: str,
    merchant_id: UUID | None,
    roles: list[str],
    mfa_verified: bool = True,
) -> str:
    now = datetime.now(timezone.utc)
    ttl = int(getattr(settings, "MERCHANT_JWT_TTL_SECONDS", 3600))
    payload: dict[str, Any] = {
        "sub": str(user_id),
        "email": email,
        "merchant_id": str(merchant_id) if merchant_id else None,
        "roles": roles,
        "mfa_verified": mfa_verified,
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(seconds=ttl)).timestamp()),
        "iss": getattr(settings, "MERCHANT_JWT_ISSUER", "taifa-identity"),
        "aud": getattr(settings, "MERCHANT_JWT_AUDIENCE", "taifa-merchant"),
    }
    secret = getattr(settings, "MERCHANT_JWT_SECRET", settings.SECRET_KEY)
    return jwt.encode(payload, secret, algorithm="HS256")


def decode_access_token(token: str) -> dict[str, Any]:
    secret = getattr(settings, "MERCHANT_JWT_SECRET", settings.SECRET_KEY)
    return jwt.decode(
        token,
        secret,
        algorithms=["HS256"],
        audience=getattr(settings, "MERCHANT_JWT_AUDIENCE", "taifa-merchant"),
        issuer=getattr(settings, "MERCHANT_JWT_ISSUER", "taifa-identity"),
    )


def generate_reset_token() -> str:
    return secrets.token_urlsafe(32)
