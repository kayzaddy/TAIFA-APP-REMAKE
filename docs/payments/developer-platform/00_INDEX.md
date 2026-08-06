# TNPI Developer Platform — Index

**Phase:** 8 — Developer Platform  
**Bounded context:** `platform.developer`  
**Status:** Architecture & implementation planning — **no production code**  
**Prerequisites:** Phases 1–7 · Published OpenAPI from domain services · Identity (Taifa Core)

---

## Mission

**Official public integration gateway** for TNPI: developer registration, apps, API keys, OAuth, sandbox, webhooks, docs, SDKs, analytics, certification—**proxying** to merchant, orchestration, settlement, recon, MAP, and risk APIs without duplicating business logic.

```
Partner → Developer Portal + API Gateway → TNPI domain services (Phases 1–7)
```

---

## Scope boundary

| In scope | Out of scope |
| --- | --- |
| Portal, keys, OAuth, sandbox routing, webhooks delivery | Merchant KYC implementation (Phase 1) |
| API aggregation, versioning, quotas, analytics | Payment orchestration logic (Phase 3) |
| SDK distribution, OpenAPI, Postman | Settlement/recon/fraud engines |
| Partner certification workflow | Transport fare business rules (Phase 9) |

---

## Document map

| # | Document |
| --- | --- |
| Gate | [PHASE8_GATE_PACKAGE.md](PHASE8_GATE_PACKAGE.md) |

| # | File |
| --- | --- |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_DEVELOPER_PORTAL.md](02_DEVELOPER_PORTAL.md) |
| 03 | [03_API_PLATFORM.md](03_API_PLATFORM.md) |
| 04 | [04_SDK_PLATFORM.md](04_SDK_PLATFORM.md) |
| 05 | [05_SANDBOX.md](05_SANDBOX.md) |
| 06 | [06_WEBHOOK_PLATFORM.md](06_WEBHOOK_PLATFORM.md) |
| 07 | [07_API_SECURITY.md](07_API_SECURITY.md) |
| 08 | [08_API_SPECIFICATION.md](08_API_SPECIFICATION.md) |
| 09 | [09_EVENT_CATALOG.md](09_EVENT_CATALOG.md) |
| 10 | [10_DATABASE_MODEL.md](10_DATABASE_MODEL.md) |
| 11 | [11_AWS_ARCHITECTURE.md](11_AWS_ARCHITECTURE.md) |
| 12 | [12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md) |
| 13 | [13_ROADMAP.md](13_ROADMAP.md) |
| 14 | [14_BACKLOG.md](14_BACKLOG.md) |
| 15 | [15_ACCEPTANCE_CRITERIA.md](15_ACCEPTANCE_CRITERIA.md) |
| 16 | [16_DEFINITION_OF_DONE.md](16_DEFINITION_OF_DONE.md) |
| 17 | [17_PARTNER_ONBOARDING.md](17_PARTNER_ONBOARDING.md) |
| 18 | [18_CERTIFICATION_PROGRAM.md](18_CERTIFICATION_PROGRAM.md) |
| 19 | [19_RISK_REGISTER.md](19_RISK_REGISTER.md) |

**Domain APIs:** [merchant/](../merchant/00_INDEX.md) · [orchestration/](../orchestration/00_INDEX.md) · [fraud-risk/](../fraud-risk/00_INDEX.md)
