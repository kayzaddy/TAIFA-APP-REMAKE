# TNPI Merchant Acceptance Platform (MAP) — Index

**Phase:** 4 — Merchant Acceptance  
**Bounded context:** `finance.acceptance`  
**Status:** Architecture & implementation planning — **no production code**  
**Prerequisites:** [Merchant Platform](../merchant/PHASE1_GATE_PACKAGE.md) · [Payment Sources](../payment-sources/PHASE2_GATE_PACKAGE.md) · [Orchestration](../orchestration/PHASE3_GATE_PACKAGE.md) (approved)

---

## Mission

**MAP** is the customer-facing acceptance layer: SoftPOS, QR, payment links, in-app/e-com checkout—every channel **creates payments via Orchestration** and never settles or reconciles funds.

```
Channel (MAP) → POST /payments (Orchestration) → Payment Sources / PSP
```

---

## Scope boundary

| In scope | Out of scope |
| --- | --- |
| SoftPOS, QR, links, checkout UX, receipts (presentation) | Payment orchestration logic (Phase 3) |
| Terminal/session, offline queue, sync | **Settlement** platform (Phase 5) |
| Refund **requests** via orchestration API | **Reconciliation** |
| Device trust at acceptance edge | **Fraud engine** (hooks only) |
| Merchant dashboard **acceptance** views | Consumer wallet linking (Phase 2) |

---

## Document map

| # | Document |
| --- | --- |
| 00 | [00_INDEX.md](00_INDEX.md) |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_SOFTPOS.md](02_SOFTPOS.md) |
| 03 | [03_QR_PAYMENTS.md](03_QR_PAYMENTS.md) |
| 04 | [04_PAYMENT_LINKS.md](04_PAYMENT_LINKS.md) |
| 05 | [05_DEVICE_MANAGEMENT.md](05_DEVICE_MANAGEMENT.md) |
| 06 | [06_TRANSACTION_FLOW.md](06_TRANSACTION_FLOW.md) |
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

**Gate package:** [PHASE4_GATE_PACKAGE.md](PHASE4_GATE_PACKAGE.md)

**Legacy:** [tap_pay/](../../tap_pay/00_INDEX.md) · program [06_SOFTPOS](../06_SOFTPOS.md) · [07_QR_PAYMENTS](../07_QR_PAYMENTS.md)
