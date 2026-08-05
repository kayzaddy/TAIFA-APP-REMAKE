# Winga Hotels Field Pilot — Program Index

**Pilot code:** `hotels-v1`  
**Industry:** Hotels · **City:** Dar es Salaam · **Area:** Harbour View / CBD  
**Duration:** 6 weeks (field)  
**Status:** **Week 0 — Pre-launch** (ops system ready · **0 real bookings**)  
**Constraint:** No architecture / payment / commission redesign  

---

## Primary success question

> Can Winga successfully connect customers, Wingas, and hotels while creating measurable value for every participant?

**Answer today:** **Unknown — field not started.** Lab software works. Business-model proof requires real money and real stays.

---

## Cohort targets vs scaffold

| Role | Target | Scaffold in DB | Field-verified (ops) |
| --- | --- | --- | --- |
| Hotels | 10 | 10 roster slots | **1** (Harbour View anchor) |
| Wingas | 20 | 20 roster slots | **5** (training-ready flags) |
| Customers | 50–100 | 0 | **0** |
| Completed bookings | ≥30 exit | — | **0** |

Scaffold ≠ onboarded. Launch only when hotels & Wingas complete Phases 1–2 checklists.

---

## Deliverables (field program)

| # | Deliverable | Path |
| --- | --- | --- |
| 0 | Field program runbook (Phases 1–10) | [`FIELD_PROGRAM.md`](FIELD_PROGRAM.md) |
| 1 | Daily Operations Dashboard | Canvas + [`01_DAILY_OPERATIONS.md`](01_DAILY_OPERATIONS.md) |
| 2 | Weekly Pilot Report | [`02_WEEKLY_PILOT_REPORT.md`](02_WEEKLY_PILOT_REPORT.md) |
| 3 | Customer Research Report | [`03_CUSTOMER_RESEARCH.md`](03_CUSTOMER_RESEARCH.md) |
| 4 | Winga Performance Report | [`04_WINGA_PERFORMANCE.md`](04_WINGA_PERFORMANCE.md) |
| 5 | Hotel Performance Report | [`05_HOTEL_PERFORMANCE.md`](05_HOTEL_PERFORMANCE.md) |
| 6 | Marketplace Metrics Dashboard | Canvas + [`06_MARKETPLACE_METRICS.md`](06_MARKETPLACE_METRICS.md) |
| 7 | Support Operations Report | [`07_SUPPORT_OPERATIONS.md`](07_SUPPORT_OPERATIONS.md) |
| 8 | Financial Integrity Report | [`08_FINANCIAL_INTEGRITY.md`](08_FINANCIAL_INTEGRITY.md) |
| 9 | Lessons Learned Report | [`09_LESSONS_LEARNED.md`](09_LESSONS_LEARNED.md) |
| 10 | Hotels Industry Blueprint v1 | [`10_HOTELS_BLUEPRINT_V1.md`](10_HOTELS_BLUEPRINT_V1.md) |
| 11 | National Expansion Go / No-Go | [`11_NATIONAL_EXPANSION_GO_NO_GO.md`](11_NATIONAL_EXPANSION_GO_NO_GO.md) |

Lab pack (software readiness): [`../00_INDEX.md`](../00_INDEX.md)  
**Operations handbook (run Winga daily):** [`../../winga_ops/00_INDEX.md`](../../winga_ops/00_INDEX.md)

---

## Exit criteria (all required)

| Criterion | Bar | Week 0 |
| --- | --- | --- |
| Completed hotel bookings | ≥ 30 | 0 |
| Wingas earning commissions | ≥ 8 | 0 |
| Hotels requesting continue | ≥ 8 | 0 |
| CSAT | ≥ 4.2 / 5 | n/a |
| Unresolved financial integrity issues | 0 | 0 open (no field txns) |
| Commission calculation errors | 0 | Lab clean |
| Settlement discrepancies | 0 | Lab clean |
| Platform availability | Ops target | Platform ops PASSED |
| Repeat booking rate | Demonstrates interest | n/a |

**Blueprint certification and national expansion: blocked until all bars pass with real data.**

---

## Commands

```bash
cd apps/backend
python manage.py seed_winga
python manage.py seed_winga_pilot_hotels
```
