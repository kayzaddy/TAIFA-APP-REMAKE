# TNPI Reconciliation Platform — Index

**Phase:** 6 — Reconciliation  
**Bounded context:** `finance.reconciliation`  
**Status:** Architecture & implementation planning — **no production code**  
**Prerequisites:** Phases 1–5 · Settlement exports + orchestration/settlement events

---

## Mission

**Financial source of truth verification** for TNPI: match internal records (payments, settlements, payouts, refunds, fees, commissions, tax) to PSP/bank statements—**no payment auth, settlement execution, or fraud scoring**.

```
Orchestration + Settlement events + Provider files → Reconciliation → Exceptions / Close / Reports
```

---

## Scope boundary

| In scope | Out of scope |
| --- | --- |
| Matching, exceptions, closing, reports, adjustments (approved) | Payment orchestration (Phase 3) |
| Provider/merchant statement ingest | Settlement payouts (Phase 5) |
| Real-time + batch recon | Fraud detection (Phase 7) |
| Audit & compliance reporting | Authorization |

---

## Document map

| # | Document |
| --- | --- |
| 00–18 | See table below |
| Gate | [PHASE6_GATE_PACKAGE.md](PHASE6_GATE_PACKAGE.md) |

| # | File |
| --- | --- |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_RECONCILIATION_MODEL.md](02_RECONCILIATION_MODEL.md) |
| 03 | [03_MATCHING_ENGINE.md](03_MATCHING_ENGINE.md) |
| 04 | [04_EXCEPTION_MANAGEMENT.md](04_EXCEPTION_MANAGEMENT.md) |
| 05 | [05_FINANCIAL_CLOSING.md](05_FINANCIAL_CLOSING.md) |
| 06 | [06_REPORTING.md](06_REPORTING.md) |
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

**Program summary:** [05_RECONCILIATION.md](../05_RECONCILIATION.md)
