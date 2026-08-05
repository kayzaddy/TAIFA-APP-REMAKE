# TAIFA Architecture

**Canonical governance:** [`architecture/README.md`](architecture/README.md) · **Taifa Core Phase 1:** [`platform/README.md`](platform/README.md) · Tourism: [`tourism/00_INDEX.md`](tourism/00_INDEX.md).

This document captures the target architecture and the principles that let TAIFA
scale from 100 → 10M+ users without a rewrite. It will grow as phases land; the
sections marked _(planned)_ are design intent, not yet implemented.

---

## 1. Guiding principles

1. **Provider abstraction everywhere.** Payments, mobile money, banking, maps,
   messaging, AI and identity all sit behind interfaces. Adding/replacing a
   provider (e.g. a new bank, a new mobile-money operator) must not touch
   business logic.
2. **Feature-first modularity.** Each domain is a self-contained module with its
   own `presentation` / `application` / `domain` (and later `data`) layers.
3. **Offline-first, event-driven.** The client must degrade gracefully; writes
   are queued and reconciled. Server state changes emit immutable events.
4. **Security is not a phase.** Zero-trust, least privilege, encryption in
   transit and at rest, auditability from day one.
5. **Everything is measurable.** Structured logs, metrics, traces.

---

## 2. Mobile architecture (implemented foundation)

**Stack:** Flutter · Riverpod · GoRouter · google_fonts (Hive, SQLite,
WebSockets, Firebase Messaging, Maps to follow).

### Layered, feature-first structure

```
lib/
├─ app/                     # cross-cutting app wiring
│  ├─ theme/                # tokens + ThemeData + theme-mode Notifier
│  ├─ shell/                # AppShell (persistent bottom nav)
│  ├─ router.dart           # GoRouter StatefulShellRoute (per-tab stacks)
│  └─ app.dart / main.dart  # MaterialApp.router + ProviderScope
├─ shared/widgets/          # design-system components (no feature logic)
└─ features/<domain>/
   ├─ domain/               # immutable models, entities
   ├─ application/          # providers, repositories (interface), controllers
   └─ presentation/         # screens & feature widgets
```

### State management

- **Riverpod** is the single source of runtime state. Providers are declared per
  feature (`home_providers.dart`) and depend on **repository interfaces**, not
  implementations. Today `SeedHomeRepository` returns curated data; swapping to
  a `RestHomeRepository` later is a one-line provider override — **zero widget
  changes**. This is the key to scaling data sources without churn.

### Navigation

- **GoRouter `StatefulShellRoute.indexedStack`** gives each primary tab (Home,
  Mobility, AI, Wallet, Menu) an independent navigator + preserved state.
  Deep-linking and web URLs come for free.

### Theming

- Dual `ThemeData` built from one token set; `TaifaPalette` `ThemeExtension`
  carries semantic colors that lerp between modes. See `DESIGN_SYSTEM.md`.

---

## 3. Backend architecture _(planned)_

- **Django + DRF** for core domain APIs & admin; **FastAPI** for high-throughput
  / streaming edges; **Celery + Redis + RabbitMQ** for async work.
- **PostgreSQL** (multi-tenant, partitioned, read replicas, soft-deletes, audit
  tables, event sourcing, sharding-ready) + **TimescaleDB** for time series +
  **ElasticSearch** for search + **MinIO** for object storage.
- **API Gateway** fronts versioned REST; GraphQL gateway kept future-ready.

### Payment platform _(planned, highest-risk domain)_

`PaymentGateway` interface → per-provider adapters (M-Pesa, Mixx, Airtel Money,
Selcom, banks…) behind a **Transaction Engine + Ledger** with idempotency keys,
a **Webhook Processor**, **Retry Engine**, **Reconciliation**, **Refund/Dispute**
and **Fraud** engines. No provider is ever referenced by business logic directly.

---

## 4. Infrastructure _(planned)_

Docker → Kubernetes (autoscaling), NGINX, Cloudflare/CDN, GitHub Actions CI/CD,
Terraform IaC, Prometheus + Grafana + Loki + OpenTelemetry + Sentry, Vault for
secrets.

---

## 5. How this scales 100 → 10M

| Concern | Foundation choice | Scale path |
|---------|-------------------|------------|
| Data sources | repository interfaces + Riverpod | seed → REST → cached/offline, no UI change |
| Navigation | per-tab stacks | add routes/modules without restructuring |
| Payments | provider adapters + ledger | add operators/banks as adapters |
| DB | partition/shard-ready schema | replicas → partitions → shards |
| Delivery | feature-first modules | teams own modules in parallel |
| Ops | metrics/traces from day one | data-driven capacity planning |
