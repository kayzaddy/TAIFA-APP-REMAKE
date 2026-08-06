# 09 — Database Model

**Schema:** `transport_payments` (mobility)

---

## Executive summary

ER for transport registry, routes, tickets, passes, journeys, validation audit—**financial references only** (`payment_id`, `refund_id`, `merchant_id`).

---

## Business purpose

SoR for mobility entitlements and network; not for money.

---

## ER diagram

```mermaid
erDiagram
  OPERATOR ||--o{ FLEET : owns
  FLEET ||--o{ VEHICLE : contains
  VEHICLE ||--o{ DRIVER_ASSIGNMENT : has
  OPERATOR ||--o{ ROUTE : operates
  ROUTE ||--o{ ROUTE_PATTERN : has
  ROUTE_PATTERN ||--o{ STOP_SEQUENCE : includes
  STOP ||--o{ STOP_SEQUENCE : at
  FARE_PRODUCT ||--o{ FARE_RULE : has
  PASSENGER ||--o{ TICKET : holds
  PASSENGER ||--o{ PASS_SUBSCRIPTION : has
  TICKET ||--o| PAYMENT_REF : links
  JOURNEY ||--o{ JOURNEY_LEG : contains
  JOURNEY ||--o| PAYMENT_REF : links
  TICKET {
    uuid id PK
    enum status
    uuid payment_id
    text qr_nonce
  }
  PAYMENT_REF {
    uuid payment_id PK
    enum tnpi_status
  }
  OPERATOR {
    uuid id PK
    uuid merchant_id
    enum mode
  }
```

---

## Key entities

| Entity | Notes |
| --- | --- |
| `Passenger` | `identity_subject_id` |
| `Operator` / `Fleet` / `Vehicle` / `Driver` | Operational |
| `Route` / `Stop` / `FareProduct` | Network |
| `Ticket` | Entitlement |
| `PassSubscription` | Renewal refs TNPI |
| `Journey` / `JourneyLeg` | Multimodal |
| `ValidationEvent` | Append-only |
| `InspectionRecord` | Compliance |

---

## Anti-patterns (forbidden)

- Wallet balance columns  
- Local payment capture state machine duplicating orchestration  
- Settlement batch tables (read cache OK)  

---

## API / events

Align with [07_API_SPECIFICATION.md](07_API_SPECIFICATION.md) and [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md).

---

## Security

Encrypt conductor device keys; row-level operator isolation.

---

## AWS

RDS PostgreSQL; PostGIS for stops; read replicas for analytics.

---

## Implementation strategy

Partition `validation_event` by month; archive to data lake.

---

## Future expansion

Toll tag registry table linking vehicle → pass.

---

## Cross-references

[04_ROUTE_MANAGEMENT.md](04_ROUTE_MANAGEMENT.md)
