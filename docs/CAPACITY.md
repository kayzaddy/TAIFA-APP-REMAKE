# TAIFA Capacity Planning

Measure continuously via Prometheus; revise quarterly.

## Observed signals

| Signal | Metric |
|--------|--------|
| Request TPS | `sum(rate(taifa_http_requests_total[1m]))` |
| Payment TPS | rate of money-write paths / txn creates |
| Peak vs average | Grafana Operations dashboard |
| Ledger growth | `taifa_ledger_entries_total`, `taifa_postings_total` |
| Queue depth | `taifa_celery_queue_depth` |
| DB size | `pg_database_size_bytes` |
| CPU / mem / disk | node-exporter |

## Load test

```bash
BASE_URL=http://localhost:8000 k6 run apps/backend/deploy/scripts/load_k6.js
```

Targets: 10 → 100 → 1_000 arrivals/sec on health/ready probes as smoke; extend
scenario with authenticated wallet/transfer flows before go-live.

## Scale model (pilot → enterprise)

Assumptions: ~20 API reads per payment write; p95 write < 500ms excl. rail;
Postgres 16; Redis AOF; gunicorn sync workers.

| Users | Peak TPS (writes) | Web replicas | Workers | Postgres | Redis |
|-------|-------------------|--------------|---------|----------|-------|
| 100K | ~50 | 2× (4 workers) | 2 | db.r6g.large | cache.m6g.large |
| 1M | ~200 | 4–6 | 4–6 | db.r6g.xlarge + read replica | cache.m6g.xlarge |
| 10M | ~1_000 | 12–20 + HPA | 12–20 | Primary + 2 replicas, partitioning | Redis Cluster |
| 50M | ~5_000+ | Multi-region active-active | Sharded workers | Sharded / Citus-class | Multi-AZ cluster |

## Growth actions

1. Enable Redis-backed Django cache for throttles (`CACHE_URL`).
2. Partition ledger postings by month before 50M users.
3. Materialized wallet balances if `balance_of` p95 regresses.
4. Autoscale on CPU **and** `taifa_celery_queue_depth`.

## Chaos

```bash
./deploy/scripts/chaos_drill.sh worker
./deploy/scripts/chaos_drill.sh redis
./deploy/scripts/chaos_drill.sh web
```

Cadence: monthly on staging; quarterly game-day with finance + risk.
