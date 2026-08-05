# TAIFA Performance

Targets and the concrete techniques used to hit them. TAIFA must feel instant on
mid-range Android over patchy networks.

## Budgets (SLOs)

| Surface | Metric | Target |
|---------|--------|--------|
| Mobile cold start | time to interactive | < 2.0s mid-range Android |
| Mobile frame | jank-free | 60fps; no frame > 16ms in scroll |
| API read (`/wallet`) | p95 latency | < 300ms |
| API money write | p95 latency | < 500ms (excl. external rail) |
| App size | initial download | lean; defer heavy modules |

## Mobile techniques

- **Lazy module loading** — GoRouter loads a feature's screens only when entered;
  the Wallet repository registers/loads on first Wallet-tab open, not at boot.
- **Repository seam** — offline seed vs. live REST is a swap; reads can be served
  from cache first, revalidated in the background (planned SWR).
- **Const widgets & narrow rebuilds** — Riverpod scopes rebuilds to the state that
  changed; design-system widgets are `const` where possible.
- **Exact money math** — integer minor units avoid float formatting cost and bugs.
- **Image/asset discipline** — resolution-aware assets; cache network images
  (planned) — no oversized bitmaps on low-DPI devices.
- **Offline tolerance** — typed `WalletException`/`NetworkException` drive reto
  retry/backoff and cached reads instead of spinners.

## Backend techniques

- **Indexes that match access paths** — `Transaction(owner, -created_at)`,
  `provider_ref`, `idempotency_key`, `status`, `type` (see `models.py`).
- **Balances via aggregation on indexed postings** — correct by construction;
  materialised balance snapshots are the scaling lever if needed.
- **`conn_max_age`** persistent DB connections; move throttle cache to Redis for a
  shared, fast limiter.
- **Async offload** — webhooks/retries/reconciliation on Celery, off the request
  path; money writes return quickly with `processing` for async rails.
- **Stateless web** — scale gunicorn workers/replicas horizontally behind nginx.
- **Pagination & projections** — `/wallet` returns the recent slice (cap 50), not
  full history; list endpoints will paginate.

## Load & capacity (planned)

- k6/Locust load tests against `/wallet` and `/transfers` to validate p95 budgets.
- Capacity model: transactions/sec → gunicorn workers, DB connections, Celery
  concurrency; autoscale on CPU + queue depth.
- Ledger partitioning by month (see `DATA_MODEL.md`) to keep hot queries fast as
  history grows.

## Regressions guardrail

Add latency assertions to load tests in CI (nightly) so a p95 regression fails
the pipeline, mirroring how `spectacular --fail-on-warn` guards the API contract.
