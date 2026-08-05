# 13 — Database Architecture

> **Governance:** Platform schema law — [`../../architecture/04_DATABASE_STANDARDS.md`](../../architecture/04_DATABASE_STANDARDS.md). Below: Tourism **table ownership** and CQRS notes.

**Rule:** One writer per table; orchestration stores refs only.

**Primary store:** Amazon Aurora PostgreSQL (multi-AZ)  
**Principle:** **One write owner per table**; cross-domain via IDs and events only.

---

## Schema ownership matrix

| Schema / prefix | Domain | Notes |
| --- | --- | --- |
| `tourism_*` | Orchestration (+ phase-1 connectivity/protection tables) | Trip, checkout, esim order, assistance case |
| `commerce_*` | Booking | All reservation tables |
| `trips_*` | Mobility | National mobility |
| `payments_*`, `enterprise_*` | Finance (platform) | Ledger |
| `discovery_*` | Discovery (future) | Places, reviews |

---

## CQRS read models

| Read model | Source events | Store |
| --- | --- | --- |
| `trip_timeline_view` | checkout, booking, mobility | Redis / Dynamo |
| `place_rating_agg` | review.submitted | Aurora materialized |
| `traveler_expense_summary` | finance.captured | Warehouse |

```mermaid
flowchart LR
  W[Write DB Aurora] --> Outbox[outbox]
  Outbox --> EB[EventBridge]
  EB --> Proj[Projectors]
  Proj --> R[Read stores]
```

---

## Migrations

- Per-domain migration app labels (`taifa_tourism`, `commerce`).  
- No FK across domain boundaries—use UUID refs + eventual consistency.

---

## Indexing (orchestration)

`(owner, status)`, `(trip_id)` on checkout, GIN on itinerary JSONB for ops queries.

---

## Backup & DR

Aurora backups 35d; cross-region read replica (Dar + failover region); RPO/RTO per [15_AWS_DEPLOYMENT.md](15_AWS_DEPLOYMENT.md).

## Risks

Shared monolith DB temptation — enforce module boundaries in code reviews.
