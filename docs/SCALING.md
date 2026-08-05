# TAIFA Regional Scaling (East Africa)

How TAIFA grows from Tanzania to Kenya and Uganda (and beyond) **without a
rewrite**. The money core was built multi-currency and multi-rail on purpose.

## What's already portable

- **Currencies** — `Currency` is a single enum (TZS, KES, UGX, USD, EUR, BTC …)
  with per-currency precision. Adding one is one entry; `Money` math and ledger
  balancing are currency-generic.
- **Rails** — the `PaymentGateway` abstraction + `PaymentRouter` mean a new
  country's operators (M-Pesa KE, MTN/Airtel UG, banks) are new adapters + a
  registry entry; business logic is untouched.
- **Ledger** — account identifiers namespace by owner and currency
  (`user:{owner}:wallet:{CUR}`), so per-currency wallets already work.
- **Contract-first API** — versioned OpenAPI lets regional clients/partners
  integrate against a stable spec.

## Scaling axes

### 1. Traffic (vertical market growth)
- Stateless `web` + `worker` scale horizontally behind the LB.
- Redis-backed throttling + Celery concurrency tuned per capacity model
  (`PERFORMANCE.md`).
- Ledger tables partitioned by month; read replicas for reporting/analytics.

### 2. Geographic (new countries)
- **Data residency** — add a `region` dimension to money-bearing rows; deploy a
  regional stack (app + Postgres + Redis) per country to meet local regulation
  (Bank of Tanzania / CBK / BoU) and latency.
- **Regional routing** — the edge routes users to their home region; cross-border
  flows settle via FX (see below).
- **Per-region rails & compliance** — country-specific KYC tiers, limits, and
  operator adapters selected by region config.

### 3. Product (more modules/portals)
- New domains (mobility, commerce, gov) are new services sharing auth +
  observability + the payment engine — they never re-implement money.

## Cross-border FX (design)

- Introduce a **FX/Settlement engine** behind the existing `CurrencyEngine`
  interface: live mid-market rates + spread policy; the rate is captured at
  authorisation and pinned to the ledger entry (never a display rate).
- Cross-currency transfers post a balanced multi-account entry (source wallet,
  FX suspense, destination) so the books stay zero-sum per currency.

## Reliability at scale

- Multi-AZ Postgres with PITR; Redis HA for the broker.
- Idempotency + append-only ledger make retries and failovers safe.
- Daily **reconciliation** job asserts "books balanced" per currency/region and
  reconciles against provider statements; breaks page on-call (`OBSERVABILITY.md`).
- Disaster recovery: documented RPO/RTO; restore drills before each regional
  launch.

## Rollout sequence

1. Harden TZ (KYC, MFA, real Daraja prod, load tests).
2. Kenya: add KES + M-Pesa KE adapter + regional stack + local compliance.
3. Uganda: add UGX + MTN/Airtel UG adapters.
4. Cross-border remittance corridors with the FX engine.

Each step is additive — currencies and rails plug into the same core proven by
the Tanzania Wallet slice.
