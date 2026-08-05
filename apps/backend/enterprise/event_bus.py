"""Enterprise event bus — DomainEvent (audit history) + Outbox (async fan-out).

Downstream systems must consume outbox/webhooks — never call payment services
directly for side effects.

`drain_outbox` delivers signed HTTP webhooks and only marks rows published on
success (or explicit no-consumer allow in DEBUG/tests).
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging
import urllib.error
import urllib.request

from django.conf import settings
from django.db import transaction as db_transaction
from django.utils import timezone

from payments import events as payment_events
from payments.models import DomainEvent, Transaction

from .models import EventOutbox, MerchantWebhookEndpoint

logger = logging.getLogger(__name__)


def publish(
    event_type: str,
    *,
    aggregate_type: str,
    aggregate_id: str,
    payload: dict | None = None,
    transaction: Transaction | None = None,
    owner: str = "",
) -> tuple[DomainEvent, EventOutbox]:
    """Atomically write domain event + outbox row."""
    body = payload or {}
    payment_txn = transaction
    with db_transaction.atomic():
        domain = payment_events.emit(
            event_type,
            transaction=payment_txn,
            owner=owner,
            payload={**body, "aggregate_type": aggregate_type, "aggregate_id": aggregate_id},
        )
        outbox = EventOutbox.objects.create(
            event_type=event_type,
            aggregate_type=aggregate_type,
            aggregate_id=str(aggregate_id),
            payload=body,
        )
    return domain, outbox


def _sign_body(secret: str, body: bytes) -> str:
    return hmac.new(secret.encode("utf-8"), body, hashlib.sha256).hexdigest()


def _platform_webhook_targets() -> list[tuple[str, str]]:
    """(url, secret) pairs from TAIFA_OUTBOX_WEBHOOK_URLS JSON list."""
    raw = getattr(settings, "TAIFA_OUTBOX_WEBHOOK_URLS", None) or []
    targets: list[tuple[str, str]] = []
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except json.JSONDecodeError:
            raw = []
    for item in raw:
        if isinstance(item, dict) and item.get("url"):
            targets.append((str(item["url"]), str(item.get("secret") or "")))
        elif isinstance(item, str) and item:
            targets.append((item, getattr(settings, "TAIFA_OUTBOX_WEBHOOK_SECRET", "") or ""))
    return targets


def _merchant_webhook_targets(event_type: str) -> list[tuple[str, str]]:
    targets: list[tuple[str, str]] = []
    for ep in MerchantWebhookEndpoint.objects.filter(active=True).select_related("merchant"):
        events = ep.events or []
        if events and event_type not in events and "*" not in events:
            continue
        # secret_hash stores a deploy-time shared secret material for HMAC (hex).
        secret = ep.secret_hash or ""
        targets.append((ep.url, secret))
    return targets


def _post_webhook(url: str, secret: str, envelope: dict, timeout: float = 5.0) -> bool:
    body = json.dumps(envelope, separators=(",", ":"), sort_keys=True).encode("utf-8")
    headers = {
        "Content-Type": "application/json",
        "User-Agent": "taifa-outbox/1.0",
        "X-Taifa-Event-Type": str(envelope.get("event_type", "")),
        "X-Taifa-Delivery-Id": str(envelope.get("outbox_id", "")),
    }
    if secret:
        headers["X-Taifa-Signature"] = f"sha256={_sign_body(secret, body)}"
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return 200 <= getattr(resp, "status", 0) < 300
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError) as exc:
        logger.warning("outbox delivery failed url=%s err=%s", url, exc)
        return False


def deliver_outbox_row(row: EventOutbox) -> bool:
    """Attempt delivery to all matching targets. True if all succeed (or none required)."""
    targets = _platform_webhook_targets() + _merchant_webhook_targets(row.event_type)
    envelope = {
        "outbox_id": str(row.id),
        "event_type": row.event_type,
        "aggregate_type": row.aggregate_type,
        "aggregate_id": row.aggregate_id,
        "payload": row.payload or {},
        "created_at": row.created_at.isoformat() if row.created_at else None,
    }
    if not targets:
        # No consumers configured: allow noop publish only in DEBUG/tests so
        # local drains don't silently claim production delivery.
        allow_noop = bool(getattr(settings, "DEBUG", False)) or bool(
            getattr(settings, "RUNNING_TESTS", False)
        )
        if allow_noop:
            logger.info("outbox noop-publish (no consumers) id=%s type=%s", row.id, row.event_type)
            return True
        logger.error("outbox undeliverable: no consumers configured for %s", row.event_type)
        return False

    ok = True
    for url, secret in targets:
        if not _post_webhook(url, secret, envelope):
            ok = False
    return ok


def drain_outbox(limit: int = 100) -> int:
    """Deliver pending outbox events; mark published only after successful delivery."""
    rows = list(EventOutbox.objects.filter(published=False).order_by("created_at")[:limit])
    now = timezone.now()
    published = 0
    for row in rows:
        if deliver_outbox_row(row):
            row.published = True
            row.published_at = now
            row.save(update_fields=["published", "published_at"])
            published += 1
    return published
