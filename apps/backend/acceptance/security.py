"""HMAC signing for QR payloads and payment links — tamper + spoofing protection."""
from __future__ import annotations

import hashlib
import hmac
from typing import Any

from django.conf import settings


def _secret() -> bytes:
    raw = getattr(settings, "MAP_SIGNING_SECRET", None) or settings.SECRET_KEY
    return str(raw).encode("utf-8")


def sign_payload(parts: list[Any]) -> str:
    message = "|".join("" if p is None else str(p) for p in parts).encode("utf-8")
    return hmac.new(_secret(), message, hashlib.sha256).hexdigest()


def verify_signature(parts: list[Any], signature: str) -> bool:
    if not signature:
        return False
    expected = sign_payload(parts)
    return hmac.compare_digest(expected, signature)


def qr_canonical(
    *,
    merchant_code: str,
    public_code: str,
    amount_minor: int | None,
    currency: str,
    intent_code: str | None,
    expires_epoch: int | None,
) -> str:
    """Stable QR payload string (not a second payment protocol)."""
    amt = "" if amount_minor is None else str(amount_minor)
    exp = "" if expires_epoch is None else str(expires_epoch)
    intent = intent_code or ""
    return f"taifa://pay/{merchant_code}?q={public_code}&a={amt}&c={currency}&i={intent}&e={exp}"
