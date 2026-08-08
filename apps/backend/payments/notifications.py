"""Push notifications for money events — a pluggable sender behind
`PushNotifier`, matching how `payments.gateways` keeps a real adapter
(Daraja) and an offline stand-in behind one interface.

No FCM/APNS credentials exist yet, so `default_notifier()` returns a
`LoggingPushNotifier` that persists a `PushNotification` row per call
(fanned out per registered device at send time) and marks it sent. Swap in
a real sender once `PUSH_FCM_SERVER_KEY` (or similar) is configured.
"""
from __future__ import annotations

from django.conf import settings
from django.utils import timezone


class PushNotifier:
    def send(self, *, owner: str, title: str, body: str, data: dict | None = None) -> None:
        raise NotImplementedError


class LoggingPushNotifier(PushNotifier):
    def send(self, *, owner: str, title: str, body: str, data: dict | None = None) -> None:
        from .models import Device, PushNotification, PushNotificationStatus

        note = PushNotification.objects.create(
            owner=owner, title=title, body=body, data=data or {}
        )
        has_device = Device.objects.filter(owner=owner).exclude(push_token="").exists()
        # "Sending" here just means recording delivery intent for every
        # device with a token on file — no real push provider is wired up.
        note.status = PushNotificationStatus.SENT if has_device else PushNotificationStatus.QUEUED
        note.sent_at = timezone.now() if has_device else None
        note.save(update_fields=["status", "sent_at"])


def default_notifier() -> PushNotifier:
    server_key = getattr(settings, "PUSH_FCM_SERVER_KEY", "")
    if server_key:
        raise NotImplementedError(
            "PUSH_FCM_SERVER_KEY is set but no real FCM sender is wired up yet."
        )
    return LoggingPushNotifier()


def notify(*, owner: str, title: str, body: str, data: dict | None = None) -> None:
    """Fire-and-forget: queues the actual send on Celery so a slow/broken
    notifier can never delay a money-moving HTTP response."""
    from .tasks import send_push_notification_task

    send_push_notification_task.delay(owner=owner, title=title, body=body, data=data or {})
