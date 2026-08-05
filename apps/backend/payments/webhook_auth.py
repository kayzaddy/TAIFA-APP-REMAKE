"""Production-grade M-Pesa webhook trust.

Layers (all evaluated; unsigned callbacks never change money in production):

1. Structural STK payload validation
2. Shared secret header (edge-injected) and/or HMAC-SHA256 over timestamp+body
3. Timestamp skew window
4. Replay fingerprint (payload hash) — append-only guard table
5. Optional IP / CIDR allow-list

HMAC headers (edge or client):
  X-TAIFA-Webhook-Timestamp: unix seconds
  X-TAIFA-Webhook-Signature: hex(hmac_sha256(f"{ts}.{raw_body}", secret))
"""
from __future__ import annotations

import hashlib
import hmac
import ipaddress
import logging
import secrets
import time
from typing import Any

from django.conf import settings
from django.db import IntegrityError
from rest_framework.exceptions import PermissionDenied, ValidationError

from .models import WebhookReplayGuard

logger = logging.getLogger(__name__)

SECRET_HEADER = "HTTP_X_TAIFA_MPESA_WEBHOOK_SECRET"
TS_HEADER = "HTTP_X_TAIFA_WEBHOOK_TIMESTAMP"
SIG_HEADER = "HTTP_X_TAIFA_WEBHOOK_SIGNATURE"


def client_ip(request) -> str:
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return (request.META.get("REMOTE_ADDR") or "").strip()


def _parse_networks(raw: list[str]) -> list:
    nets = []
    for item in raw:
        item = item.strip()
        if not item:
            continue
        try:
            if "/" in item:
                nets.append(ipaddress.ip_network(item, strict=False))
            else:
                ip = ipaddress.ip_address(item)
                nets.append(ipaddress.ip_network(f"{ip}/{ip.max_prefixlen}", strict=False))
        except ValueError:
            logger.warning("Ignoring invalid MPESA_WEBHOOK_ALLOWED_IPS entry: %s", item)
    return nets


def ip_is_allowed(ip: str, allowed: list[str]) -> bool:
    if not allowed:
        return True
    if not ip:
        return False
    try:
        addr = ipaddress.ip_address(ip)
    except ValueError:
        return False
    for net in _parse_networks(allowed):
        if addr in net:
            return True
    return False


def secret_is_valid(presented: str, expected: str) -> bool:
    if not expected:
        return True  # optional when not fail-closed
    if not presented:
        return False
    return secrets.compare_digest(presented, expected)


def compute_webhook_signature(secret: str, timestamp: str, raw_body: bytes) -> str:
    msg = f"{timestamp}.".encode("utf-8") + raw_body
    return hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).hexdigest()


def validate_stk_payload(payload: Any) -> tuple[str, str]:
    if not isinstance(payload, dict):
        raise ValidationError({"detail": "Webhook body must be a JSON object."})
    stk = (payload.get("Body") or {}).get("stkCallback") or {}
    if not isinstance(stk, dict):
        raise ValidationError({"detail": "Missing Body.stkCallback."})
    checkout_id = str(stk.get("CheckoutRequestID", "")).strip()
    if not checkout_id:
        raise ValidationError({"detail": "Missing CheckoutRequestID."})
    result_code = str(stk.get("ResultCode", "")).strip()
    return checkout_id, result_code


def _require_production_secret() -> bool:
    from .production_gates import is_production_runtime

    return is_production_runtime() or bool(getattr(settings, "MPESA_WEBHOOK_FAIL_CLOSED", False))


def assert_mpesa_stk_webhook_trusted(request) -> None:
    """Raise PermissionDenied / ValidationError when the callback fails trust checks."""
    try:
        _assert_mpesa_stk_webhook_trusted(request)
    except PermissionDenied as exc:
        reason = str(getattr(exc, "detail", exc) or "denied")[:64]
        try:
            from .metrics import observe_webhook_auth_failure

            observe_webhook_auth_failure(reason)
        except Exception:
            pass
        raise


def _assert_mpesa_stk_webhook_trusted(request) -> None:
    """Raise PermissionDenied / ValidationError when the callback fails trust checks."""
    allowed_ips = list(getattr(settings, "MPESA_WEBHOOK_ALLOWED_IPS", []) or [])
    expected_secret = getattr(settings, "MPESA_WEBHOOK_SHARED_SECRET", "") or ""
    require_hmac = bool(getattr(settings, "MPESA_WEBHOOK_REQUIRE_HMAC", False))
    max_skew = int(getattr(settings, "MPESA_WEBHOOK_MAX_SKEW_SECONDS", 300) or 300)
    fail_closed = _require_production_secret()

    ip = client_ip(request)
    if allowed_ips and not ip_is_allowed(ip, allowed_ips):
        logger.warning("M-Pesa webhook rejected: IP %s not in allow-list", ip or "<empty>")
        raise PermissionDenied(detail="Webhook source not allowed.")

    if fail_closed and not expected_secret:
        logger.error("M-Pesa webhook rejected: no shared secret configured in fail-closed mode")
        raise PermissionDenied(detail="Webhook secret not configured.")

    presented_secret = request.META.get(SECRET_HEADER, "") or ""
    ts = (request.META.get(TS_HEADER, "") or "").strip()
    sig = (request.META.get(SIG_HEADER, "") or "").strip()
    raw_body = getattr(request, "body", b"") or b""

    hmac_ok = False
    if expected_secret and ts and sig:
        try:
            ts_int = int(ts)
        except ValueError as exc:
            raise PermissionDenied(detail="Invalid webhook timestamp.") from exc
        now = int(time.time())
        if abs(now - ts_int) > max_skew:
            logger.warning("M-Pesa webhook rejected: timestamp skew (ts=%s now=%s)", ts, now)
            raise PermissionDenied(detail="Webhook timestamp expired.")
        expected_sig = compute_webhook_signature(expected_secret, ts, raw_body)
        if secrets.compare_digest(sig.lower(), expected_sig.lower()):
            hmac_ok = True
        elif require_hmac or fail_closed:
            logger.warning("M-Pesa webhook rejected: HMAC mismatch (ip=%s)", ip or "<empty>")
            raise PermissionDenied(detail="Webhook signature invalid.")

    if require_hmac and not hmac_ok:
        raise PermissionDenied(detail="Webhook HMAC required.")

    if expected_secret and not hmac_ok:
        # Shared-secret header path (edge injects secret without HMAC).
        if not secret_is_valid(presented_secret, expected_secret):
            logger.warning("M-Pesa webhook rejected: shared secret mismatch (ip=%s)", ip or "<empty>")
            raise PermissionDenied(detail="Webhook secret invalid.")
    elif fail_closed and not hmac_ok and not secret_is_valid(presented_secret, expected_secret):
        raise PermissionDenied(detail="Webhook authentication required.")

    checkout_id, result_code = validate_stk_payload(request.data)

    # Replay protection: unique fingerprint of provider_ref + result + body hash.
    body_hash = hashlib.sha256(raw_body).hexdigest()
    fingerprint = hashlib.sha256(
        f"mpesa|stk|{checkout_id}|{result_code}|{body_hash}".encode()
    ).hexdigest()
    try:
        WebhookReplayGuard.objects.create(
            fingerprint=fingerprint,
            provider="mpesa",
            provider_ref=checkout_id,
        )
    except IntegrityError:
        logger.warning("M-Pesa webhook rejected: replay fingerprint=%s", fingerprint[:16])
        raise PermissionDenied(detail="Webhook replay detected.") from None
