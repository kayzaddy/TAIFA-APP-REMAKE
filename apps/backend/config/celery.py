"""Celery application for async payment work (webhooks, retries, reconciliation)."""
from __future__ import annotations

import os

from celery import Celery

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

app = Celery("taifa")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()
