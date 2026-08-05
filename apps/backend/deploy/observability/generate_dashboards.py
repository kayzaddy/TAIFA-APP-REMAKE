"""Generate Grafana dashboard JSON + provisioning for TAIFA Phase 2 ops."""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]  # apps/backend
OUT = ROOT / "deploy" / "observability" / "grafana" / "dashboards"
DS = ROOT / "deploy" / "observability" / "grafana" / "provisioning" / "datasources"
DB = ROOT / "deploy" / "observability" / "grafana" / "provisioning" / "dashboards"


def panel(pid, title, expr, x, y, w=12, h=8, typ="timeseries"):
    p = {
        "id": pid,
        "type": typ,
        "title": title,
        "gridPos": {"h": h, "w": w, "x": x, "y": y},
        "targets": [{"expr": expr, "refId": "A"}],
        "datasource": {"type": "prometheus", "uid": "prometheus"},
    }
    if typ == "stat":
        p["options"] = {"reduceOptions": {"calcs": ["lastNotNull"]}}
    return p


def dashboard(uid, title, panels):
    return {
        "uid": uid,
        "title": title,
        "timezone": "browser",
        "schemaVersion": 39,
        "version": 1,
        "refresh": "30s",
        "tags": ["taifa", "phase2"],
        "panels": panels,
        "templating": {"list": []},
        "time": {"from": "now-6h", "to": "now"},
        "annotations": {"list": []},
    }


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    DS.mkdir(parents=True, exist_ok=True)
    DB.mkdir(parents=True, exist_ok=True)

    specs = [
        (
            "executive",
            "TAIFA Executive",
            [
                panel(1, "API Ready (up)", 'up{job="taifa-payments"}', 0, 0, 6, 4, "stat"),
                panel(2, "Ledger recon OK", "taifa_ledger_reconciliation_ok", 6, 0, 6, 4, "stat"),
                panel(
                    3,
                    "Payment success share",
                    'taifa_transactions{status="succeeded"}/clamp_min(sum(taifa_transactions),1)',
                    12,
                    0,
                    6,
                    4,
                    "stat",
                ),
                panel(
                    4,
                    "Open settlement exceptions",
                    "sum(taifa_provider_reconciliation_exceptions)",
                    18,
                    0,
                    6,
                    4,
                    "stat",
                ),
                panel(5, "Transactions by status", "taifa_transactions", 0, 4, 12, 8),
                panel(
                    6,
                    "HTTP 5xx rate",
                    'sum(rate(taifa_http_requests_total{status=~"5.."}[5m]))/clamp_min(sum(rate(taifa_http_requests_total[5m])),1)',
                    12,
                    4,
                    12,
                    8,
                ),
            ],
        ),
        (
            "operations",
            "TAIFA Operations",
            [
                panel(
                    1,
                    "HTTP p95 latency",
                    "histogram_quantile(0.95, sum(rate(taifa_http_request_duration_seconds_bucket[5m])) by (le))",
                    0,
                    0,
                ),
                panel(2, "Request rate", "sum(rate(taifa_http_requests_total[5m]))", 12, 0),
                panel(3, "Celery queue depth", "taifa_celery_queue_depth", 0, 8),
                panel(4, "Worker heartbeat", "taifa_worker_heartbeat", 12, 8, 12, 8, "stat"),
                panel(
                    5,
                    "Pending webhook backlog",
                    "taifa_pending_transactions_older_than_seconds",
                    0,
                    16,
                ),
            ],
        ),
        (
            "payments",
            "TAIFA Payments",
            [
                panel(1, "Txn by status", "taifa_transactions", 0, 0),
                panel(
                    2,
                    "HTTP payment paths",
                    'sum by (path) (rate(taifa_http_requests_total{path=~"/api/v1/payments.*"}[5m]))',
                    12,
                    0,
                ),
                panel(3, "Devices", "taifa_devices_total", 0, 8, 12, 8, "stat"),
            ],
        ),
        (
            "settlement",
            "TAIFA Settlement",
            [
                panel(1, "Provider exceptions by code", "taifa_provider_reconciliation_exceptions", 0, 0),
                panel(
                    2,
                    "Matched lines",
                    "taifa_provider_reconciliation_matched_total",
                    12,
                    0,
                    12,
                    8,
                    "stat",
                ),
            ],
        ),
        (
            "ledger",
            "TAIFA Ledger",
            [
                panel(1, "Recon OK", "taifa_ledger_reconciliation_ok", 0, 0, 6, 4, "stat"),
                panel(2, "Breaks by check", "taifa_ledger_reconciliation_breaks", 6, 0),
                panel(3, "Ledger entries growth", "taifa_ledger_entries_total", 0, 8),
                panel(4, "Postings growth", "taifa_postings_total", 12, 8),
            ],
        ),
        (
            "risk",
            "TAIFA Risk",
            [
                panel(1, "Risk decisions", "rate(taifa_risk_decisions_total[5m])", 0, 0),
                panel(
                    2,
                    "Deny rate",
                    'rate(taifa_risk_decisions_total{decision="deny"}[5m])',
                    12,
                    0,
                ),
            ],
        ),
        (
            "infrastructure",
            "TAIFA Infrastructure",
            [
                panel(
                    1,
                    "CPU",
                    '100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)',
                    0,
                    0,
                ),
                panel(
                    2,
                    "Memory used %",
                    "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
                    12,
                    0,
                ),
                panel(
                    3,
                    "Disk used %",
                    "(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100",
                    0,
                    8,
                ),
            ],
        ),
        (
            "database",
            "TAIFA Database",
            [
                panel(1, "Postgres up", 'up{job="postgres"}', 0, 0, 6, 4, "stat"),
                panel(2, "DB size bytes", "pg_database_size_bytes", 6, 0),
                panel(3, "Active connections", "pg_stat_activity_count", 0, 8),
            ],
        ),
        (
            "webhook",
            "TAIFA Webhooks",
            [
                panel(1, "Webhook results", "taifa_webhook_events", 0, 0),
                panel(2, "Auth failures", "rate(taifa_webhook_auth_failures_total[5m])", 12, 0),
                panel(
                    3,
                    "Backlog >5m",
                    "taifa_pending_transactions_older_than_seconds",
                    0,
                    8,
                    12,
                    8,
                    "stat",
                ),
            ],
        ),
        (
            "security",
            "TAIFA Security",
            [
                panel(1, "Webhook auth failures", "increase(taifa_webhook_auth_failures_total[1h])", 0, 0),
                panel(
                    2,
                    "HTTP 401/403",
                    'sum(rate(taifa_http_requests_total{status=~"401|403"}[5m]))',
                    12,
                    0,
                ),
                panel(
                    3,
                    "Risk denies",
                    'increase(taifa_risk_decisions_total{decision="deny"}[1h])',
                    0,
                    8,
                ),
            ],
        ),
    ]

    for uid, title, panels in specs:
        path = OUT / f"taifa-{uid}.json"
        path.write_text(json.dumps(dashboard(f"taifa-{uid}", title, panels), indent=2), encoding="utf-8")
        print("wrote", path)

    (DS / "datasources.yml").write_text(
        """apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    uid: prometheus
    url: http://prometheus:9090
    isDefault: true
  - name: Loki
    type: loki
    access: proxy
    uid: loki
    url: http://loki:3100
  - name: Tempo
    type: tempo
    access: proxy
    uid: tempo
    url: http://tempo:3200
""",
        encoding="utf-8",
    )
    (DB / "dashboards.yml").write_text(
        """apiVersion: 1
providers:
  - name: taifa
    orgId: 1
    folder: TAIFA
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    options:
      path: /var/lib/grafana/dashboards
""",
        encoding="utf-8",
    )
    print("provisioning ok")


if __name__ == "__main__":
    main()
