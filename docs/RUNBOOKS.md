# TAIFA Production Runbooks

Executable operator procedures. Prefer automation; use these when alerts fire.

## Restart workers

```bash
cd apps/backend
docker compose -f docker-compose.prod.yml up -d --force-recreate worker beat
docker compose -f docker-compose.prod.yml exec worker celery -A config inspect ping
curl -sf localhost/metrics | grep taifa_worker_heartbeat
```

## Replay failed webhooks

1. Identify `WebhookEvent` rows with `result` in (`failed`, empty) via Admin (read-only) or shell.
2. Re-queue: `process_mpesa_stk_callback_task.delay(payload)`.
3. Never call demo-complete in production.

## Retry settlements / provider reconciliation

```bash
python manage.py ingest_settlement_csv /path/to/day.csv --provider mpesa --reconcile
python manage.py ingest_settlement_csv /path/to/day.csv --reconcile --full-day
```

Clear exceptions only after finance signs off; do not delete ledger rows.

## Ledger mismatch

```bash
python manage.py reconcile_ledger --json
# Investigate taifa_ledger_reconciliation_breaks
# Fix via compensating journals through Payment Engine / Orchestrator only
```

## Recover backups

```bash
./deploy/scripts/verify_backup.sh var/backups/taifa_YYYYMMDD….sql.gz.enc
# On staging first:
./deploy/scripts/restore_postgres.sh var/backups/taifa_YYYYMMDD….sql.gz.enc
curl -sf localhost/startupz && curl -sf localhost/readyz
```

## Rotate secrets

1. Generate new `DJANGO_SECRET_KEY`, `MPESA_WEBHOOK_SHARED_SECRET`, DB password.
2. Deploy new secret to secret manager → roll web/worker/beat.
3. Update edge HMAC injection; keep old secret for skew window ≤ 1 hour if dual-read supported (today: single secret — coordinate cutover).
4. Revoke devices if token material leaked.

## Rotate certificates

1. Renew TLS at LB / cert-manager.
2. Monitor expiry (90/30/7 day tickets).
3. Confirm HSTS and `SECURE_SSL_REDIRECT` remain on.

## Recover database

See [`DISASTER_RECOVERY.md#database-failure`](DISASTER_RECOVERY.md).

## Recover queues

1. Restore Redis AOF or fresh Redis.
2. Restart worker/beat.
3. Re-drive durable webhook events from Postgres.

## Webhook outage

1. Check `taifa_webhook_auth_failures_total` reasons.
2. Validate IP allow-list + shared secret + HMAC skew.
3. Check provider status; scale workers if backlog only.

## Queue failure

1. Alert `TaifaQueueBacklog` / `TaifaWorkerDown`.
2. Scale workers; inspect Celery logs; clear poison messages after quarantine.

## Payment delay

1. Distinguish provider pending vs internal backlog.
2. `/depsz` + Grafana Payments / Webhook dashboards.
3. Do not manually mark succeeded without provider confirmation.
