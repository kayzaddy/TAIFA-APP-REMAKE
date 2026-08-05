# TAIFA Disaster Recovery

RTO/RPO targets: `config/slo.py` and [`OPERATIONS.md`](OPERATIONS.md).

Backups are incomplete until restore is verified
(`deploy/scripts/verify_backup.sh` + periodic restore drill).

## Scenarios

### Database failure

1. Confirm Postgres down (`/readyz` DB fail; `up{job="postgres"}==0`).
2. Fail over to standby / restore latest encrypted dump:
   `./deploy/scripts/restore_postgres.sh var/backups/taifa_….sql.gz.enc`
3. Run migrations if needed; `curl -sf /startupz /readyz`.
4. Run `reconcile_ledger --json`.
5. **RTO ≤ 15m**, **RPO ≤ 5m** with PITR enabled in managed Postgres.

### Region failure

1. DNS / LB fail to secondary region (warm standby recommended for pilot).
2. Promote secondary DB; update `DATABASE_URL`, Redis, Celery.
3. Validate `/depsz` and payment smoke (register → wallet → small transfer).

### Worker failure

1. `docker compose … up -d --scale worker=N`
2. Or `./deploy/scripts/chaos_drill.sh worker` recovery path
3. Confirm `taifa_worker_heartbeat == 1` and queue depth falling.

### Redis failure

1. Restore Redis from AOF volume or new empty Redis (accept task loss only if
   webhook events are durable in Postgres — re-drive from `WebhookEvent`).
2. Restart workers/beat; verify broker ping via `/readyz`.

### Provider outage (M-Pesa / Airtel)

1. Payments remain `processing`; do not forge settles.
2. Communicate delay; poll-status / webhook resume when provider recovers.
3. Reconcile settlement files after recovery.

### Storage corruption

1. Stop writers; restore from last verified backup.
2. Diff ledger recon before opening traffic.

### Message queue failure

1. Same as Redis failure for Celery broker.
2. Replay unprocessed webhook payloads from `WebhookEvent` where `result` empty.

### Network partition / power outage

1. Prefer multi-AZ managed Postgres + Redis.
2. After power restore: start DB → Redis → release → web → worker → beat → nginx.
3. Chaos drill: `./deploy/scripts/chaos_drill.sh web`

## Backup schedule

| Job | Cadence | Artifact |
|-----|---------|----------|
| Encrypted `pg_dump` | Hourly | `var/backups/*.sql.gz.enc` |
| Marker for metrics | On success | `var/backup_last_success` |
| Verify decrypt | Daily | `verify_backup.sh` |
| Full restore drill | Monthly | Staging DB |

```bash
export DATABASE_URL=…
export BACKUP_ENCRYPTION_KEY=…
./deploy/scripts/backup_postgres.sh
./deploy/scripts/verify_backup.sh var/backups/taifa_….sql.gz.enc
```

Alert: `TaifaBackupMissing` if marker older than 36h.
