# TAIFA System Architecture

End-to-end view of how the app, backend, and portals fit together. The mobile
Wallet ↔ payment-service slice is built and live; this document shows how the
rest attaches to the same spine without reshaping it.

## High-level topology

```
        ┌───────────────────────────── Clients ─────────────────────────────┐
        │  Mobile (Flutter)      Web portals (planned)                       │
        │  consumer app          admin·merchant·driver·ops·gov·support·dev   │
        └───────────┬───────────────────────┬───────────────────────────────┘
                    │  HTTPS / REST (v1)     │
              ┌─────▼───────────────────────▼─────┐
              │        Edge (nginx / LB)          │  TLS, X-Request-ID, rate limit
              └─────┬───────────────────────┬─────┘
                    │                        │
         ┌──────────▼─────────┐    ┌─────────▼──────────┐
         │  Payment service   │    │  Future services   │
         │  (Django + DRF)    │    │  identity, mobility │
         │  engine · ledger   │    │  commerce, gov, …   │
         │  gateways · webhook│    │  (same patterns)    │
         └──┬───────┬─────────┘    └────────────────────┘
            │       │
    ┌───────▼──┐ ┌──▼─────┐   ┌───────────────┐   ┌──────────────────────┐
    │ Postgres │ │ Redis  │◀─▶│  Celery worker│──▶│ M-Pesa Daraja (rails) │
    │ (ledger) │ │(broker)│   │ webhooks/retry│   │ + Airtel/Selcom/card  │
    └──────────┘ └────────┘   └───────────────┘   └──────────────────────┘
```

## Principles

1. **Server is authoritative.** Clients render and initiate; balances, ledger and
   state transitions live server-side. The Dart domain mirrors the Python one so
   the two stay aligned by construction (see `PAYMENTS.md`).
2. **Interfaces over vendors.** Payment rails, maps, messaging, KYC all sit behind
   abstractions; swapping a provider is one adapter + one registry entry.
3. **Contract-first.** REST is versioned (`/api/v1`) and described by OpenAPI,
   validated in CI. Clients can be generated from the schema.
4. **Vertical slices.** Each feature ships UI → domain → API → tests, not layers
   in isolation.
5. **12-factor & stateless web.** Config via env; scale `web`/`worker`
   horizontally; state in Postgres/Redis.

## Mobile architecture

Feature-first, layered (`app/`, `shared/`, `features/<domain>/{domain,application,
presentation}`, `data/`). Riverpod for state, GoRouter for navigation, a `data/`
layer (versioned REST client + DTOs + device auth) behind repository interfaces.
The UI depends only on repositories, so seed↔live swaps are invisible. Details in
`ARCHITECTURE.md`.

## Backend architecture

Django + DRF service per bounded context. The payment service contains:
`money`, `models` (append-only ledger + transactions + idempotency + webhooks +
devices), `ledger`, `engine`, `gateways/*`, `webhooks`, `auth`, `serializers`,
`views`, plus `config/` (settings, request-id middleware, health/readiness,
OpenAPI, logging, Sentry). New domains (identity, mobility, commerce, gov) are new
apps/services following the same shape and sharing auth + observability.

## Cross-cutting concerns

| Concern | Mechanism |
|---------|-----------|
| AuthN/Z | Device-bound tokens; owner scoping (→ user identity + KYC next) |
| API contract | OpenAPI 3 via drf-spectacular; CI-validated |
| Async work | Celery + Redis (webhooks, retries, reconciliation) |
| Observability | `/healthz`, `/readyz`, request-id logging, Sentry (`OBSERVABILITY.md`) |
| Security | throttling, prod TLS/HSTS, CORS lock-down (`SECURITY.md`) |
| Data integrity | double-entry ledger, append-only guards, idempotency |
| Deploy | Docker compose (prod) → any container host / k8s (`DEPLOYMENT.md`) |

## Data flow: a send

1. App builds a `TransferCommand` + idempotency key; `POST /payments/transfers`
   with device token.
2. Engine: idempotency guard → create `Transaction` (owner-scoped) → route to a
   rail → on terminal success post a **balanced** ledger entry → settle.
3. Async rails (M-Pesa STK) return `processing`; the webhook resolves them to
   `succeeded`/`failed` via Celery.
4. App reflects the returned transaction; `GET /wallet` reconciles balance.

## Scaling & multi-region

Multi-currency, multi-rail core enables East-Africa expansion (Kenya/Uganda) by
adding currencies (one enum entry) and rail adapters, with data residency per
region. See `SCALING.md`.
