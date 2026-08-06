# TNPI Payment Sources Platform — Documentation Index

**Program:** Taifa National Payment Infrastructure (TNPI)  
**Phase:** 2 — Payment Sources Platform  
**Status:** Architecture & implementation planning — **no production code in this pack**  
**Prerequisite:** [Merchant Platform Phase 1](../merchant/PHASE1_GATE_PACKAGE.md) gate passed (approved)  
**Authority:** [00_PAYMENT_PROGRAM.md](../00_PAYMENT_PROGRAM.md) · [02_WALLET_AGGREGATION.md](../02_WALLET_AGGREGATION.md) (program summary)

---

## Mission

Securely **connect, manage, and abstract** every customer payment instrument for Taifa—without holding customer funds or competing with PSPs. This is the **Apple Wallet + provider abstraction** layer for Tanzania and East Africa, preparatory to Phase 3 orchestration.

---

## Scope boundary (Phase 2)

| In scope | Out of scope (later phases) |
| --- | --- |
| Link / verify / unlink payment sources | Payment **processing** (charge/capture) |
| Tokens, consent, preferences, provider health | **Settlement** execution |
| Provider adapters (auth, link, status—not pay) | **Reconciliation** |
| Customer payment profiles | **SoftPOS** / **QR** acceptance |
| Default & priority ordering | Orchestration routing (Phase 3) |

---

## Bounded context

**`finance.payment_sources`** (alias: wallet aggregation in legacy docs) — SoR for linked instruments, consents, token references, provider registry, and customer payment preferences.

---

## Document map

| # | Document |
| --- | --- |
| 00 | [00_INDEX.md](00_INDEX.md) (this file) |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_PROVIDER_ABSTRACTION.md](02_PROVIDER_ABSTRACTION.md) |
| 03 | [03_PAYMENT_SOURCE_MODEL.md](03_PAYMENT_SOURCE_MODEL.md) |
| 04 | [04_TOKENIZATION.md](04_TOKENIZATION.md) |
| 05 | [05_CONSENT_MANAGEMENT.md](05_CONSENT_MANAGEMENT.md) |
| 06 | [06_PROVIDER_ADAPTERS.md](06_PROVIDER_ADAPTERS.md) |
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

**Phase 2 gate package:** [PHASE2_GATE_PACKAGE.md](PHASE2_GATE_PACKAGE.md)

---

## Event naming note

Program events use `payment_source.*` and `consent.*`. Legacy TNPI draft used `wallet.linked` — map in [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md).

---

## Cross-references

- Merchant SoR (Phase 1): [merchant/00_INDEX.md](../merchant/00_INDEX.md)  
- Future orchestration: [03_PAYMENT_ORCHESTRATION.md](../03_PAYMENT_ORCHESTRATION.md) (Phase 3 — **not in scope**)
