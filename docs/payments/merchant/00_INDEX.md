# TNPI Merchant Platform — Documentation Index

**Program:** Taifa National Payment Infrastructure (TNPI)  
**Phase:** 1 — Merchant Platform (first production TNPI product)  
**Status:** Architecture & implementation planning — **no production code in this pack**  
**Authority:** [00_PAYMENT_PROGRAM.md](../00_PAYMENT_PROGRAM.md) · [01_PAYMENT_FOUNDATION.md](../01_PAYMENT_FOUNDATION.md) · [Taifa Core](../../platform/00_PLATFORM_OVERVIEW.md)

---

## Scope boundary (Phase 1)

| In scope | Out of scope (later phases) |
| --- | --- |
| Merchant identity, KYB, hierarchy, users, devices (registry only) | Payment orchestration |
| Settlement **account** metadata (not payout execution) | Wallet aggregation |
| API keys, webhooks (registration only) | SoftPOS transaction processing |
| Dashboard design, analytics **views** (merchant master data) | QR payment processing |
| Events & APIs for merchant lifecycle | Charging, routing, settlement batches |

---

## Document map

| # | Document |
| --- | --- |
| 00 | [00_INDEX.md](00_INDEX.md) (this file) |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_BUSINESS_CAPABILITIES.md](02_BUSINESS_CAPABILITIES.md) |
| 03 | [03_DOMAIN_MODEL.md](03_DOMAIN_MODEL.md) |
| 04 | [04_MERCHANT_ONBOARDING.md](04_MERCHANT_ONBOARDING.md) |
| 05 | [05_DEVICE_MANAGEMENT.md](05_DEVICE_MANAGEMENT.md) |
| 06 | [06_EMPLOYEE_MANAGEMENT.md](06_EMPLOYEE_MANAGEMENT.md) |
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

**Phase 1 gate package:** [PHASE1_GATE_PACKAGE.md](PHASE1_GATE_PACKAGE.md) — readiness report, roadmap, sprints, dependency graph, exit to Phase 2.

**Taifa Merchant (business application):** consumes this platform — [taifa-merchant/00_INDEX.md](../../taifa-merchant/00_INDEX.md); does not duplicate TNPI merchant SoR.

---

## Bounded context

**`finance.merchant`** — system of record for merchant digital identity, organizational hierarchy, workforce, device inventory, settlement account references, and developer credentials.

---

## Cross-references

- TNPI events (program): [15_EVENT_CATALOG.md](../15_EVENT_CATALOG.md) — merchant events detailed in [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md)
- TNPI APIs (program): [14_API_CATALOG.md](../14_API_CATALOG.md) — merchant APIs in [07_API_SPECIFICATION.md](07_API_SPECIFICATION.md)
