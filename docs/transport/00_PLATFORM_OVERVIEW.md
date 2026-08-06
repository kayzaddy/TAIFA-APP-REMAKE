# Taifa Transport Payments Platform (TPP) — Overview

**Program:** Taifa Mobility — national OS; see [TNMP](../mobility/00_PLATFORM_OVERVIEW.md). TPP is the **TNPI payment/ticketing** product within this program.  
**Status:** Architecture & implementation planning — **no production code**  
**TNPI:** Consumer only — **no payment logic duplication**

---

## Mission

Tanzania’s **unified digital transport payment ecosystem**: one passenger experience across dala dala, BRT, rail, ferries, air, taxis, ride-hail, parking, and future tolls/EV—delegating **all money movement** to TNPI Core via [Developer Platform](../payments/developer-platform/00_INDEX.md) APIs and platform events.

```
Passenger / Operator / Govt → TPP (tickets, routes, passes) → TNPI (pay, settle, recon, risk)
```

---

## TNPI consumption (do not reimplement)

| Service | TPP usage |
| --- | --- |
| [Merchant Platform](../payments/merchant/00_INDEX.md) | Operator as merchant; fleet terminals |
| [Payment Sources](../payments/payment-sources/00_INDEX.md) | Passenger wallets / tokens |
| [Orchestration](../payments/orchestration/00_INDEX.md) | `payment_id` for every fare |
| [MAP](../payments/merchant-acceptance/00_INDEX.md) | QR, SoftPOS, NFC validation |
| [Settlement](../payments/settlement/00_INDEX.md) | Operator revenue splits (metadata) |
| [Reconciliation](../payments/reconciliation/00_INDEX.md) | Read-only operator reports |
| [Fraud & Risk](../payments/fraud-risk/00_INDEX.md) | Pre-auth via orchestration hook |
| [Developer Platform](../payments/developer-platform/00_INDEX.md) | Public `/v1/transport/*` edge |

**Identity** · **Notifications** · **Maps** · **AI** — Taifa platform services (consume, don’t duplicate).

---

## Document map

| # | Document |
| --- | --- |
| 00 | [00_PLATFORM_OVERVIEW.md](00_PLATFORM_OVERVIEW.md) (this file) |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_PASSENGER_PLATFORM.md](02_PASSENGER_PLATFORM.md) |
| 03 | [03_OPERATOR_PLATFORM.md](03_OPERATOR_PLATFORM.md) |
| 04 | [04_ROUTE_MANAGEMENT.md](04_ROUTE_MANAGEMENT.md) |
| 05 | [05_TICKETING.md](05_TICKETING.md) |
| 06 | [06_AI_JOURNEY_PLANNER.md](06_AI_JOURNEY_PLANNER.md) |
| 07 | [07_API_SPECIFICATION.md](07_API_SPECIFICATION.md) |
| 08 | [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md) |
| 09 | [09_DATABASE_MODEL.md](09_DATABASE_MODEL.md) |
| 10 | [10_SECURITY_MODEL.md](10_SECURITY_MODEL.md) |
| 11 | [11_AWS_ARCHITECTURE.md](11_AWS_ARCHITECTURE.md) |
| 12 | [12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md) |
| 13 | [13_ROADMAP.md](13_ROADMAP.md) |
| 14 | [14_BACKLOG.md](14_BACKLOG.md) |
| 15 | [15_ACCEPTANCE_CRITERIA.md](15_ACCEPTANCE_CRITERIA.md) |
| 16 | [16_DEFINITION_OF_DONE.md](16_DEFINITION_OF_DONE.md) |
| 17 | [17_RISK_REGISTER.md](17_RISK_REGISTER.md) |

**Program bridge:** [08_TRANSPORT_PAYMENTS.md](../payments/08_TRANSPORT_PAYMENTS.md)

---

## Supported modes (summary)

Dala dala · BRT · TRC · SGR · Ferries · Domestic airlines · Airport shuttle · Taxi · Ride-hailing · Bajaji · Bodaboda · Parking · Future toll · Future EV charging.

---

## Architecture principle

TPP owns **trip, ticket, pass, route, operator registry**; TNPI owns **payment intent, capture, settlement, ledger references**. TPP stores `payment_id`, `settlement_batch_ref` — never wallet float.

---

## Cross-references

[Architecture Constitution](../architecture/00_ARCHITECTURE_CONSTITUTION.md) · [GOVERNANCE](../GOVERNANCE.md)
