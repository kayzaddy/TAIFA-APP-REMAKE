# TNPI Payment Orchestration Platform — Index

**Phase:** 3 — Payment Orchestration  
**Bounded context:** `finance.orchestration`  
**Status:** Architecture & implementation planning — **no production code**  
**Prerequisites:** [Merchant Platform](../merchant/PHASE1_GATE_PACKAGE.md) · [Payment Sources](../payment-sources/PHASE2_GATE_PACKAGE.md) gates passed (approved)

---

## Mission

The **single payment brain** for Taifa: authorize, route, retry, fail over, and manage lifecycle for every vertical—without holding funds or replacing PSPs. Channels (SoftPOS, QR, links, APIs) invoke orchestration; **settlement/reconciliation systems** are triggered, not implemented here.

---

## Scope boundary (Phase 3)

| In scope | Out of scope |
| --- | --- |
| Payment lifecycle, routing, sagas, idempotency | **Implementing** PSP adapters (use Payment Sources + execution adapters) |
| Risk/validation hooks, webhooks dispatch | **Settlement** engine implementation |
| Trigger events: settlement/recon/receipt requested | **Reconciliation** engine implementation |
| Workflow definitions (tourism, mobility, etc.) | **SoftPOS** / **QR** channel apps (Phase 4) |

---

## Document map

| # | Document |
| --- | --- |
| 00 | [00_INDEX.md](00_INDEX.md) |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_PAYMENT_LIFECYCLE.md](02_PAYMENT_LIFECYCLE.md) |
| 03 | [03_STATE_MACHINE.md](03_STATE_MACHINE.md) |
| 04 | [04_ROUTING_ENGINE.md](04_ROUTING_ENGINE.md) |
| 05 | [05_WORKFLOW_ENGINE.md](05_WORKFLOW_ENGINE.md) |
| 06 | [06_SAGA_ORCHESTRATION.md](06_SAGA_ORCHESTRATION.md) |
| 07 | [07_API_SPECIFICATION.md](07_API_SPECIFICATION.md) |
| 08 | [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md) |
| 09 | [09_DATABASE_MODEL.md](09_DATABASE_MODEL.md) |
| 10 | [10_SECURITY_MODEL.md](10_SECURITY_MODEL.md) |
| 11 | [11_AWS_ARCHITECTURE.md](11_AWS_ARCHITECTURE.md) |
| 12 | [12_OBSERVABILITY.md](12_OBSERVABILITY.md) |
| 13 | [13_IMPLEMENTATION_GUIDE.md](13_IMPLEMENTATION_GUIDE.md) |
| 14 | [14_ROADMAP.md](14_ROADMAP.md) |
| 15 | [15_BACKLOG.md](15_BACKLOG.md) |
| 16 | [16_ACCEPTANCE_CRITERIA.md](16_ACCEPTANCE_CRITERIA.md) |
| 17 | [17_DEFINITION_OF_DONE.md](17_DEFINITION_OF_DONE.md) |
| 18 | [18_RISK_REGISTER.md](18_RISK_REGISTER.md) |

**Phase 3 gate:** [PHASE3_GATE_PACKAGE.md](PHASE3_GATE_PACKAGE.md) (readiness, dependencies, sprints, Phase 4 exit, architecture review, production assessment).

**Program summary:** [03_PAYMENT_ORCHESTRATION.md](../03_PAYMENT_ORCHESTRATION.md)
