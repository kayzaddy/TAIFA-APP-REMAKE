"""Prometheus metrics for the TAIFA payment service.

Business gauges are refreshed from the DB on each scrape. HTTP / risk / webhook
auth counters and histograms accumulate in-process across scrapes.
"""
from __future__ import annotations

from datetime import timedelta
from pathlib import Path

from django.conf import settings
from django.db.models import Count
from django.http import HttpResponse
from django.utils import timezone
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Gauge,
    Histogram,
    generate_latest,
)

from .models import Device, Transaction, TransactionStatus, WebhookEvent
from .webhook_auth import client_ip, ip_is_allowed

_registry = CollectorRegistry(auto_describe=True)

TXN_BY_STATUS = Gauge(
    "taifa_transactions",
    "Count of payment transactions by status",
    ["status"],
    registry=_registry,
)
WEBHOOK_BY_RESULT = Gauge(
    "taifa_webhook_events",
    "Count of webhook events by processing result",
    ["result"],
    registry=_registry,
)
PENDING_OLDER_THAN = Gauge(
    "taifa_pending_transactions_older_than_seconds",
    "Processing transactions older than the given age threshold (webhook backlog)",
    ["threshold_seconds"],
    registry=_registry,
)
DEVICES_TOTAL = Gauge(
    "taifa_devices_total",
    "Registered device principals",
    registry=_registry,
)
APP_INFO = Gauge(
    "taifa_app_info",
    "Build/runtime info (always 1)",
    ["service", "environment"],
    registry=_registry,
)
RECON_OK = Gauge(
    "taifa_ledger_reconciliation_ok",
    "1 if the last ledger reconciliation found no breaks, else 0 (absent until first run)",
    registry=_registry,
)
RECON_BREAKS = Gauge(
    "taifa_ledger_reconciliation_breaks",
    "Break count from the last ledger reconciliation, by check name",
    ["check"],
    registry=_registry,
)
RECON_CHECKED_AT = Gauge(
    "taifa_ledger_reconciliation_checked_at_seconds",
    "Unix timestamp of the last ledger reconciliation run",
    registry=_registry,
)
PROVIDER_RECON_EXCEPTIONS = Gauge(
    "taifa_provider_reconciliation_exceptions",
    "Open provider settlement reconciliation exceptions by code",
    ["code"],
    registry=_registry,
)
PROVIDER_RECON_MATCHED = Gauge(
    "taifa_provider_reconciliation_matched_total",
    "Matched settlement lines across reconciled batches",
    registry=_registry,
)
HTTP_REQUESTS = Counter(
    "taifa_http_requests_total",
    "HTTP requests by method, normalized path, and status",
    ["method", "path", "status"],
    registry=_registry,
)
HTTP_LATENCY = Histogram(
    "taifa_http_request_duration_seconds",
    "HTTP request latency seconds",
    ["method", "path"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0, 10.0),
    registry=_registry,
)
RISK_DECISIONS = Counter(
    "taifa_risk_decisions_total",
    "Risk engine decisions",
    ["decision"],
    registry=_registry,
)
WEBHOOK_AUTH_FAILURES = Counter(
    "taifa_webhook_auth_failures_total",
    "Webhook authentication/verification failures",
    ["reason"],
    registry=_registry,
)
CELERY_QUEUE_DEPTH = Gauge(
    "taifa_celery_queue_depth",
    "Approximate Celery broker queue depth",
    ["queue"],
    registry=_registry,
)
WORKER_HEARTBEAT = Gauge(
    "taifa_worker_heartbeat",
    "1 if Celery workers are reachable via inspect ping",
    registry=_registry,
)
LEDGER_ENTRIES_TOTAL = Gauge(
    "taifa_ledger_entries_total",
    "Total ledger entries (growth signal)",
    registry=_registry,
)
POSTINGS_TOTAL = Gauge(
    "taifa_postings_total",
    "Total ledger postings (growth signal)",
    registry=_registry,
)
SLO_INFO = Gauge(
    "taifa_slo_target",
    "Declared SLO target (fraction)",
    ["slo"],
    registry=_registry,
)
BACKUP_LAST_SUCCESS = Gauge(
    "taifa_backup_last_success_timestamp_seconds",
    "Unix timestamp of last verified backup success marker",
    registry=_registry,
)

_KNOWN_RECON_CHECKS = (
    "empty_entry",
    "unbalanced_entry",
    "global_imbalance",
    "currency_mismatch",
    "succeeded_without_ledger",
    "orphan_ledger_link",
)
_KNOWN_PROVIDER_CODES = (
    "missing_settlement",
    "duplicate_settlement",
    "amount_mismatch",
    "currency_mismatch",
    "unexpected_settlement",
    "late_settlement",
    "unknown_transaction",
)


def observe_http_request(*, method: str, path: str, status: int, duration_seconds: float) -> None:
    HTTP_REQUESTS.labels(method=method, path=path, status=str(status)).inc()
    HTTP_LATENCY.labels(method=method, path=path).observe(duration_seconds)


def observe_risk_decision(decision: str) -> None:
    RISK_DECISIONS.labels(decision=decision).inc()


def observe_webhook_auth_failure(reason: str) -> None:
    WEBHOOK_AUTH_FAILURES.labels(reason=reason[:64]).inc()


def _refresh_celery_metrics() -> None:
    CELERY_QUEUE_DEPTH.labels(queue="celery").set(0)
    WORKER_HEARTBEAT.set(0)
    if getattr(settings, "CELERY_TASK_ALWAYS_EAGER", True):
        return
    broker = getattr(settings, "CELERY_BROKER_URL", "") or ""
    if broker.startswith("redis://"):
        try:
            import redis

            client = redis.Redis.from_url(broker, socket_connect_timeout=1, socket_timeout=1)
            depth = int(client.llen("celery") or 0)
            CELERY_QUEUE_DEPTH.labels(queue="celery").set(depth)
        except Exception:
            pass
    try:
        from config.celery import app

        inspector = app.control.inspect(timeout=0.5)
        ping = inspector.ping() if inspector else None
        WORKER_HEARTBEAT.set(1 if ping else 0)
    except Exception:
        WORKER_HEARTBEAT.set(0)


def refresh_business_metrics() -> None:
    """Recompute gauges from the live database (called on each scrape)."""
    for status, _label in TransactionStatus.choices:
        TXN_BY_STATUS.labels(status=status).set(
            Transaction.objects.filter(status=status).count()
        )

    result_counts = {
        row["result"]: row["c"]
        for row in WebhookEvent.objects.exclude(result="")
        .values("result")
        .annotate(c=Count("id"))
    }
    for result in ("succeeded", "failed", "unmatched", *result_counts):
        WEBHOOK_BY_RESULT.labels(result=result).set(result_counts.get(result, 0))

    cutoff = timezone.now() - timedelta(minutes=5)
    PENDING_OLDER_THAN.labels(threshold_seconds="300").set(
        Transaction.objects.filter(
            status=TransactionStatus.PROCESSING,
            updated_at__lt=cutoff,
        ).count()
    )

    DEVICES_TOTAL.set(Device.objects.count())

    env = getattr(settings, "MPESA", {}).get("ENVIRONMENT", "unknown")
    APP_INFO.labels(service="taifa-payments", environment=str(env)).set(1)

    from .reconciliation import last_reconciliation

    recon = last_reconciliation()
    if recon is not None:
        RECON_OK.set(1 if recon.ok else 0)
        RECON_CHECKED_AT.set(recon.checked_at.timestamp())
        by_check = recon.by_check()
        for check in (*_KNOWN_RECON_CHECKS, *by_check):
            RECON_BREAKS.labels(check=check).set(by_check.get(check, 0))

    from .models import LedgerEntry, Posting, ReconciliationException, SettlementBatch

    code_counts = {
        row["code"]: row["c"]
        for row in ReconciliationException.objects.values("code").annotate(c=Count("id"))
    }
    for code in (*_KNOWN_PROVIDER_CODES, *code_counts):
        PROVIDER_RECON_EXCEPTIONS.labels(code=code).set(code_counts.get(code, 0))
    PROVIDER_RECON_MATCHED.set(
        sum(SettlementBatch.objects.values_list("matched_count", flat=True)) or 0
    )
    LEDGER_ENTRIES_TOTAL.set(LedgerEntry.objects.count())
    POSTINGS_TOTAL.set(Posting.objects.count())

    try:
        from config.slo import SLOS

        for name, meta in SLOS.items():
            SLO_INFO.labels(slo=name).set(float(meta["target"]))
    except Exception:
        pass

    marker = Path(getattr(settings, "BASE_DIR")) / "var" / "backup_last_success"
    try:
        if marker.is_file():
            BACKUP_LAST_SUCCESS.set(float(marker.read_text(encoding="utf-8").strip() or "0"))
    except Exception:
        pass

    _refresh_celery_metrics()

    try:
        from enterprise.metrics import refresh_enterprise_metrics

        refresh_enterprise_metrics()
    except Exception:
        pass

    try:
        from trips.metrics import refresh_mobility_metrics

        refresh_mobility_metrics()
    except Exception:
        pass

    try:
        from mobility_registry.metrics import refresh_registry_metrics

        refresh_registry_metrics()
    except Exception:
        pass


def metrics_payload() -> bytes:
    refresh_business_metrics()
    return generate_latest(_registry)


def metrics_view(request):
    """Prometheus scrape endpoint. Optional IP allow-list via METRICS_ALLOWED_IPS."""
    allowed = list(getattr(settings, "METRICS_ALLOWED_IPS", []) or [])
    if allowed and not ip_is_allowed(client_ip(request), allowed):
        return HttpResponse("Forbidden", status=403, content_type="text/plain")
    return HttpResponse(metrics_payload(), content_type=CONTENT_TYPE_LATEST)
