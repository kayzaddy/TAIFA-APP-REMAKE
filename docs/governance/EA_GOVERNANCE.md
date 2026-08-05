# Enterprise Architecture Governance

## Architecture principles

1. **Platform before product** — shared Identity, Payments, Registry, Notifications, GIS, AI, Audit first.
2. **Bounded contexts** — no cross-domain database coupling; integrate via APIs/events.
3. **Configuration over customization** — countries, compliance, rails via config/adapters.
4. **Never duplicate money or identity** — ledger and device auth are single sources of truth.
5. **Advisory AI only for critical paths** — human approval for financial/regulatory actions.
6. **Observable by default** — health, metrics, traces, audit for every service.
7. **Backward compatible evolution** — version APIs; deprecate with notice.
8. **Evidence-based change** — ADRs for material decisions.

## Reference architecture

```text
Clients (Super App · Partners · Governments)
        │
   Edge / API Gateway (/api/v1)
        │
 ┌──────┼──────────┬───────────┬────────────┐
 │      │          │           │            │
Payments Identity Ecosystem Continental AI OS
Ledger   Device    Domains    Countries  Infer
        │
 Mobility · Commerce · Registry · Enterprise
        │
 Postgres · Redis · Celery · Object storage
```

Capability map: Identity · Wallet/Payments · Financial Ops · Mobility · Registry · Commerce verticals · Ecosystem catalog · AI OS · Continental tenancy · Observability · Audit.

## Domain boundaries (enforced)

| Domain | Owns | Must not own |
| --- | --- | --- |
| payments | Ledger, wallet, risk engine | Business catalogs |
| enterprise | RBAC, workflow, treasury orchestration | Payment posting logic forks |
| trips | Dispatch, trips, national mobility | Payment settlement |
| mobility_registry | Eligibility / documents | Trip lifecycle |
| ecosystem | Module enablement, domain catalog | Money movement |
| ai_os | Inference, agents, knowledge | Ledger mutations |
| continental | Country/FX/compliance config | Hardcoded national product forks |
| commerce | Consumer vertical bookings | Auth/payments engines |

## Architecture Review Board (ARB)

**Quorum:** CTO (or delegate) + Platform Architect + domain Technical Owner + Security Owner for money/identity changes.

**Must review:** new Django apps/services, new public APIs, cross-border money flows, new AI capabilities that auto-apply, data residency exceptions, shared schema changes.

**Rejects:** duplicate wallets/auth, bypass of audit, hardcoded country regulation in product code, silent API breaks.

## ADRs

All material decisions → [`docs/adr/`](../adr/README.md). Status: proposed → accepted → superseded/deprecated.

## Technical debt

Register: [`TECHNICAL_DEBT.md`](TECHNICAL_DEBT.md). Debt items require owner, severity, and target quarter.

## Service ownership

See [`OWNERSHIP.md`](OWNERSHIP.md). Every service lists Business / Product / Technical / Security / Data / Ops / Platform owners.
