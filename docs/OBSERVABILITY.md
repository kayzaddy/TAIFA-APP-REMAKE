# TAIFA Observability

Operators must detect, measure, log, trace, and alert every failure. Silent
failures are forbidden. Full ops manual: [`OPERATIONS.md`](OPERATIONS.md).
Phase 2 readiness: [`OPERATIONS_READINESS.md`](OPERATIONS_READINESS.md).

## Health probes

| Endpoint | Meaning | Use |
|----------|---------|-----|
| `GET /healthz` | Liveness — process is serving | k8s/docker liveness |
| `GET /readyz` | Readiness — DB, Redis (when not eager), engines | LB / readiness |
| `GET /startupz` | Startup — migrations + core imports | startupProbe |
| `GET /depsz` | Dependency report — ledger, risk, provider config | operator diagnostics |
| `GET /metrics` | Prometheus text exposition | scrape |

```bash
curl -sf localhost:8000/healthz
curl -sf localhost:8000/readyz
curl -sf localhost:8000/startupz
curl -sf localhost:8000/depsz | jq .
```

## Request correlation & tracing

`RequestIDMiddleware` mints/honours `X-Request-ID`. Optional business headers:
`X-Transaction-Id`, `X-Wallet-Id`, `X-User-Id`.

OpenTelemetry (Django + requests + Celery) activates when
`OTEL_EXPORTER_OTLP_ENDPOINT` is set (e.g. `http://otel-collector:4318`).
Traces land in Tempo; log lines include `trace_id` / `span_id`.

## Structured JSON logging

Production default: `TAIFA_LOG_JSON=true` (when `DEBUG=false`). Each line is JSON:

`timestamp`, `severity`, `service`, `environment`, `trace_id`, `request_id`,
`correlation_id`, `transaction_id`, `wallet_id`, `merchant_id`, `user_id`, …

Secrets, PINs, passwords, and card-like numbers are redacted
(`config/logging_json.py`).

## Error tracking / APM

Sentry activates **only when `SENTRY_DSN` is set** (Django + Celery integrations).

```bash
SENTRY_DSN=https://…  SENTRY_TRACES_SAMPLE_RATE=0.1
```

## Prometheus metrics (selected)

| Metric | Meaning |
|--------|---------|
| `taifa_transactions{status}` | Txn counts |
| `taifa_http_requests_total` / `taifa_http_request_duration_seconds` | API throughput / latency |
| `taifa_risk_decisions_total{decision}` | Risk allow/deny/review |
| `taifa_webhook_auth_failures_total` | Webhook trust failures |
| `taifa_celery_queue_depth` / `taifa_worker_heartbeat` | Queue / workers |
| `taifa_ledger_*` / `taifa_provider_reconciliation_*` | Accounting + settlement |
| `taifa_slo_target{slo}` | Declared SLO targets |
| `taifa_backup_last_success_timestamp_seconds` | Backup marker age |

Infra exporters: node, Redis, Postgres (see `docker-compose.observability.yml`).

## Grafana dashboards

Provisioned under `deploy/observability/grafana/dashboards/`:

Executive · Operations · Payments · Settlement · Ledger · Risk · Infrastructure ·
Database · Webhook · Security

Regenerate: `python deploy/observability/generate_dashboards.py`

## Alerting

Rules: `deploy/observability/alert_rules.yml`  
Routing: `deploy/observability/alertmanager.yml` (Slack, Teams, email, PagerDuty, SMS gateway)

Critical examples: ledger imbalance, settlement exceptions, webhook auth spike,
worker down, CPU/mem/disk exhaustion, backup missing.

## Bring-up observability stack

```bash
docker compose -f docker-compose.prod.yml -f docker-compose.observability.yml --env-file .env up -d
# Grafana :3000  Prometheus :9090  Alertmanager :9093  Tempo :3200
```

## Ledger & provider reconciliation

```bash
python manage.py reconcile_ledger --json
python manage.py ingest_settlement_csv /path/to/day.csv --reconcile
```

## Planned follow-ons

- Live Alertmanager secrets in the cluster (templates checked in).
- Automated Daraja settlement file pull.
- Synthetic multi-region `/readyz` checks.
