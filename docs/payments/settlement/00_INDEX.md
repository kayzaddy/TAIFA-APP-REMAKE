# TNPI Settlement Platform — Index

**Phase:** 5 — Settlement  
**Bounded context:** `finance.settlement`  
**Status:** Architecture & implementation planning — **no production code**  
**Prerequisites:** Phases 1–4 gates passed · Orchestration emits `payment.settlement.requested` / `payment.completed`

---

## Mission

Calculate, schedule, execute, and track **settlements and payouts** after successful payments—merchant, marketplace, government, transport, tourism, insurance—**without** authorizing payments or replacing PSPs.

```
Orchestration (payment.completed) → Event → Settlement Platform → Payout instructions → Reconciliation (Phase 6)
```

---

## Scope boundary

| In scope | Out of scope |
| --- | --- |
| Calculation, batches, splits, fees, commissions, tax hooks | Payment auth/capture (Phase 3) |
| Payout execution instructions (bank/MM) | Acceptance UX (Phase 4) |
| Settlement reports & audit | **Reconciliation matching** (Phase 6) |
| Maker-checker, settlement reversals | Consumer float custody |

---

## Document map

| # | Document |
| --- | --- |
| 00 | [00_INDEX.md](00_INDEX.md) |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_SETTLEMENT_MODEL.md](02_SETTLEMENT_MODEL.md) |
| 03 | [03_SPLIT_PAYMENTS.md](03_SPLIT_PAYMENTS.md) |
| 04 | [04_BATCH_PROCESSING.md](04_BATCH_PROCESSING.md) |
| 05 | [05_PAYOUT_ENGINE.md](05_PAYOUT_ENGINE.md) |
| 06 | [06_API_SPECIFICATION.md](06_API_SPECIFICATION.md) |
| 07 | [07_EVENT_CATALOG.md](07_EVENT_CATALOG.md) |
| 08 | [08_DATABASE_MODEL.md](08_DATABASE_MODEL.md) |
| 09 | [09_SECURITY_MODEL.md](09_SECURITY_MODEL.md) |
| 10 | [10_AWS_ARCHITECTURE.md](10_AWS_ARCHITECTURE.md) |
| 11 | [11_IMPLEMENTATION_GUIDE.md](11_IMPLEMENTATION_GUIDE.md) |
| 12 | [12_ROADMAP.md](12_ROADMAP.md) |
| 13 | [13_BACKLOG.md](13_BACKLOG.md) |
| 14 | [14_ACCEPTANCE_CRITERIA.md](14_ACCEPTANCE_CRITERIA.md) |
| 15 | [15_DEFINITION_OF_DONE.md](15_DEFINITION_OF_DONE.md) |
| 16 | [16_RISK_REGISTER.md](16_RISK_REGISTER.md) |

**Gate package:** [PHASE5_GATE_PACKAGE.md](PHASE5_GATE_PACKAGE.md)

**Program summary:** [04_SETTLEMENT.md](../04_SETTLEMENT.md)
