# TAIFA Operational Manual (Phase 2)

Enterprise operations for 24×7 payment processing. Product features are out of
scope — this manual covers detection, alerting, recovery, and capacity.

Companion docs:

| Doc | Purpose |
|-----|---------|
| [`OBSERVABILITY.md`](OBSERVABILITY.md) | Metrics, logs, traces, probes |
| [`INCIDENT_RESPONSE.md`](INCIDENT_RESPONSE.md) | Detect → diagnose → contain → recover → postmortem |
| [`DISASTER_RECOVERY.md`](DISASTER_RECOVERY.md) | Failure scenarios + RTO/RPO |
| [`RUNBOOKS.md`](RUNBOOKS.md) | Step-by-step operator actions |
| [`ONCALL.md`](ONCALL.md) | On-call expectations |
| [`CAPACITY.md`](CAPACITY.md) | TPS / growth model |
| [`OPERATIONS_READINESS.md`](OPERATIONS_READINESS.md) | Phase 2 certification scorecard |
| [`PRODUCTION_GATE.md`](PRODUCTION_GATE.md) | Phase 1 money-safety gate |

## Stack topology

```
Client → nginx → gunicorn (N replicas)
                      ↓
                 Postgres (primary; PITR)
                 Redis (AOF) ← Celery worker (N) + beat (1)
                      ↓
         Prometheus → Alertmanager → Slack/Teams/Email/PagerDuty/SMS
         Grafana ← Prometheus / Loki / Tempo
         OTel Collector ← app traces → Tempo
```

## Bring-up

```bash
cd apps/backend
docker compose -f docker-compose.prod.yml --env-file .env up -d --build
docker compose -f docker-compose.prod.yml -f docker-compose.observability.yml --env-file .env up -d
```

Probes:

| Probe | URL | Use |
|-------|-----|-----|
| Liveness | `/healthz` | Process alive |
| Readiness | `/readyz` | DB + Redis + engines |
| Startup | `/startupz` | Migrations applied |
| Dependencies | `/depsz` | Full subsystem report |
| Metrics | `/metrics` | Prometheus scrape |

## Scaling

```bash
docker compose -f docker-compose.prod.yml up -d --scale web=3 --scale worker=2
```

Zero-downtime: rolling restart behind nginx; release job migrates before web
becomes healthy (`start_period` + `/startupz`).

## SLOs (summary)

See `config/slo.py` and [`CAPACITY.md`](CAPACITY.md).

| SLO | Target |
|-----|--------|
| API availability | 99.95% |
| Ledger availability | 99.99% |
| Payment success | 99.9% |
| Webhook processing | 99.95% |
| RTO (DB failover) | 15 min |
| RPO (Postgres PITR) | 5 min |
