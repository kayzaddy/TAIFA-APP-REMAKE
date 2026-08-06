# TNPI Fraud & Risk Platform (FRP) — Index

**Phase:** 7 — Fraud & Risk  
**Bounded context:** `risk.fraud`  
**Status:** Architecture & implementation planning — **no production code**  
**Prerequisites:** Phases 1–6 · Orchestration pre-auth hook · Recon exception signals (read-only)

---

## Mission

**Centralized intelligence and protection** for TNPI: every payment **assessed before authorization** and **monitored after completion**—risk scoring, rules, lists, cases, AML readiness—without processing payments, settlement, or reconciliation.

```
Orchestration (sync assess) + Events (async monitor) + Recon signals → FRP → Approve | Review | Decline | Escalate
```

---

## Scope boundary

| In scope | Out of scope |
| --- | --- |
| Real-time & post-auth risk assessment | Payment capture / routing (Phase 3) |
| Rules engine, scoring, lists, cases | Settlement & payouts (Phase 5) |
| Merchant/customer/device profiles | Financial matching (Phase 6) |
| ML hooks (modular, optional) | PCI card data storage beyond tokens/refs |
| Compliance monitoring & audit | Consumer wallet float |

---

## Document map

| # | Document |
| --- | --- |
| Gate | [PHASE7_GATE_PACKAGE.md](PHASE7_GATE_PACKAGE.md) |

| # | File |
| --- | --- |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_RISK_ENGINE.md](02_RISK_ENGINE.md) |
| 03 | [03_RULE_ENGINE.md](03_RULE_ENGINE.md) |
| 04 | [04_RISK_SCORING.md](04_RISK_SCORING.md) |
| 05 | [05_CASE_MANAGEMENT.md](05_CASE_MANAGEMENT.md) |
| 06 | [06_MACHINE_LEARNING.md](06_MACHINE_LEARNING.md) |
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

**Upstream:** [orchestration/00_INDEX.md](../orchestration/00_INDEX.md) · [reconciliation/00_INDEX.md](../reconciliation/00_INDEX.md)
