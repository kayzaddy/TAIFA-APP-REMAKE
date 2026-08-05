"""Notification delivery — SMS, email, push (HTTP providers, fail-closed in prod)."""
from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Protocol

from django.conf import settings
from django.core.mail import send_mail

from .http_client import IntegrationHttpClient, IntegrationHttpError

logger = logging.getLogger("taifa.integrations.notify")


@dataclass(frozen=True)
class DeliveryResult:
    channel: str
    accepted: bool
    provider_ref: str
    detail: dict


class NotificationChannel(Protocol):
    channel: str

    def send(self, *, to: str, subject: str, body: str, metadata: dict | None = None) -> DeliveryResult: ...


class NotificationNotConfigured(RuntimeError):
    pass


class HttpSmsAdapter:
    channel = "sms"

    def __init__(self):
        cfg = getattr(settings, "TAIFA_SMS_PROVIDER", None) or {}
        base_url = (cfg.get("base_url") or "").strip()
        if not base_url:
            raise NotificationNotConfigured("SMS provider not configured (TAIFA_SMS_PROVIDER_JSON)")
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        api_key = cfg.get("api_key") or ""
        if api_key:
            headers["Authorization"] = f"{cfg.get('auth_scheme', 'Bearer')} {api_key}"
        self._client = IntegrationHttpClient(
            integration="notify.sms",
            base_url=base_url,
            timeout_s=float(cfg.get("timeout_seconds", 15)),
            default_headers=headers,
        )
        self._path = cfg.get("send_path", "/v1/sms/send")
        self._from = cfg.get("from", "TAIFA")

    def send(self, *, to: str, subject: str, body: str, metadata: dict | None = None) -> DeliveryResult:
        try:
            resp = self._client.request(
                "POST",
                self._path,
                operation="sms_send",
                json={
                    "to": to,
                    "from": self._from,
                    "message": body,
                    "subject": subject,
                    "metadata": metadata or {},
                },
            )
            data = resp.json() if resp.content else {}
            return DeliveryResult(
                channel="sms",
                accepted=True,
                provider_ref=str(data.get("id") or data.get("message_id") or ""),
                detail=data if isinstance(data, dict) else {},
            )
        except IntegrationHttpError as exc:
            return DeliveryResult(
                channel="sms",
                accepted=False,
                provider_ref="",
                detail={"error": str(exc), "status_code": exc.status_code},
            )


class DjangoEmailAdapter:
    channel = "email"

    def send(self, *, to: str, subject: str, body: str, metadata: dict | None = None) -> DeliveryResult:
        from_email = getattr(settings, "DEFAULT_FROM_EMAIL", "") or settings.EMAIL_HOST_USER or "noreply@taifa.local"
        if not getattr(settings, "EMAIL_HOST", "") and not getattr(settings, "EMAIL_BACKEND", "").endswith(
            "console.EmailBackend"
        ):
            # Allow console backend in DEBUG; otherwise require SMTP host.
            if not settings.DEBUG and not getattr(settings, "RUNNING_TESTS", False):
                if not getattr(settings, "EMAIL_HOST", ""):
                    raise NotificationNotConfigured("EMAIL_HOST is not configured for production email")
        try:
            n = send_mail(subject, body, from_email, [to], fail_silently=False)
            return DeliveryResult(
                channel="email",
                accepted=n > 0,
                provider_ref=f"django-mail-{to}",
                detail={"sent": n},
            )
        except Exception as exc:  # noqa: BLE001 — surface provider failures
            return DeliveryResult(
                channel="email",
                accepted=False,
                provider_ref="",
                detail={"error": str(exc)},
            )


class HttpPushAdapter:
    channel = "push"

    def __init__(self):
        cfg = getattr(settings, "TAIFA_PUSH_PROVIDER", None) or {}
        base_url = (cfg.get("base_url") or "").strip()
        if not base_url:
            raise NotificationNotConfigured("Push provider not configured (TAIFA_PUSH_PROVIDER_JSON)")
        headers = {"Content-Type": "application/json", "Accept": "application/json"}
        api_key = cfg.get("api_key") or ""
        if api_key:
            headers["Authorization"] = f"{cfg.get('auth_scheme', 'Bearer')} {api_key}"
        self._client = IntegrationHttpClient(
            integration="notify.push",
            base_url=base_url,
            timeout_s=float(cfg.get("timeout_seconds", 15)),
            default_headers=headers,
        )
        self._path = cfg.get("send_path", "/v1/push/send")

    def send(self, *, to: str, subject: str, body: str, metadata: dict | None = None) -> DeliveryResult:
        try:
            resp = self._client.request(
                "POST",
                self._path,
                operation="push_send",
                json={
                    "device_token": to,
                    "title": subject,
                    "body": body,
                    "data": metadata or {},
                },
            )
            data = resp.json() if resp.content else {}
            return DeliveryResult(
                channel="push",
                accepted=True,
                provider_ref=str(data.get("id") or ""),
                detail=data if isinstance(data, dict) else {},
            )
        except IntegrationHttpError as exc:
            return DeliveryResult(
                channel="push",
                accepted=False,
                provider_ref="",
                detail={"error": str(exc)},
            )


def deliver_notification(
    *,
    channel: str,
    to: str,
    subject: str,
    body: str,
    metadata: dict | None = None,
) -> DeliveryResult:
    """Route a notification to the configured channel adapter."""
    channel = (channel or "").lower()
    if channel == "sms":
        return HttpSmsAdapter().send(to=to, subject=subject, body=body, metadata=metadata)
    if channel == "email":
        return DjangoEmailAdapter().send(to=to, subject=subject, body=body, metadata=metadata)
    if channel == "push":
        return HttpPushAdapter().send(to=to, subject=subject, body=body, metadata=metadata)
    raise NotificationNotConfigured(f"unknown notification channel: {channel}")
