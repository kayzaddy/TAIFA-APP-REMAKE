# Taifa Merchant — Documentation Index

**Product:** Taifa Merchant (flagship business application)  
**Bounded context:** `commerce.taifa_merchant` (application)  
**Status:** Architecture & implementation planning — **no production code**  
**TPOS:** Align with [TPOS document standard](../tpos/03_PRODUCT_DOCUMENT_TEMPLATE.md) — [migration guide](../tpos/12_IMPLEMENTATION_GUIDE.md).  
**Position:** First **production business app** on Taifa; consumes platforms, does not replace them.

---

## Executive summary

**Taifa Merchant** is the **Digital Operating System for businesses in Tanzania**—onboarding, branches, staff, devices, acceptance (QR, SoftPOS, links), transactions, refunds, receipts, customers, analytics, and AI insights—built on **Taifa Identity, TNPI, Core services**, and **TIP**.

---

## Platform boundary

| Capability | Owner | Taifa Merchant |
| --- | --- | --- |
| Merchant legal identity / KYB SoR | [TNPI Merchant Platform](../payments/merchant/00_INDEX.md) | **Client** — onboard via API |
| Payments, refunds, orchestration | TNPI | **Client** |
| SoftPOS / QR rails | TNPI MAP | **Client** |
| Login, MFA, business users | Taifa Identity | **Client** |
| Push/email/SMS | Notifications | **Client** |
| Files (logos, exports) | Media | **Client** |
| AI insights | Taifa AI | **Client** |
| Audit evidence | Core Audit | **Emit + query** |
| Maps (branch geo) | Maps | **Client** |
| Search (transactions catalog) | Search | **Client** |
| App UX, dashboards, workflows | **Taifa Merchant** | **Owner** |

---

## Document map

| # | Document |
| --- | --- |
| **PRD (product SoT)** | [**Product Requirements**](../products/merchant/00_PRODUCT_REQUIREMENTS_DOCUMENT.md) · [**Backlog**](../products/merchant/26_PRODUCT_BACKLOG.md) |
| Gate | [TAIFA_MERCHANT_GATE_PACKAGE.md](TAIFA_MERCHANT_GATE_PACKAGE.md) |
| 01 | [01_PRODUCT_VISION.md](01_PRODUCT_VISION.md) |
| 02 | [02_BUSINESS_ARCHITECTURE.md](02_BUSINESS_ARCHITECTURE.md) |
| 03 | [03_DOMAIN_MODEL.md](03_DOMAIN_MODEL.md) |
| 04 | [04_COMPONENT_ARCHITECTURE.md](04_COMPONENT_ARCHITECTURE.md) |
| 05 | [05_DATABASE_DESIGN.md](05_DATABASE_DESIGN.md) |
| 06 | [06_API_SPECIFICATION.md](06_API_SPECIFICATION.md) |
| 07 | [07_PLATFORM_INTEGRATION.md](07_PLATFORM_INTEGRATION.md) |
| 08 | [08_AWS_ARCHITECTURE.md](08_AWS_ARCHITECTURE.md) |
| 09 | [09_MODULE_CATALOG.md](09_MODULE_CATALOG.md) |
| 10 | [10_IMPLEMENTATION_ROADMAP.md](10_IMPLEMENTATION_ROADMAP.md) |
| 11 | [11_SPRINT_PLAN.md](11_SPRINT_PLAN.md) |
| 12 | [12_MVP_DEFINITION.md](12_MVP_DEFINITION.md) |
| 13 | [13_ACCEPTANCE_CRITERIA.md](13_ACCEPTANCE_CRITERIA.md) |
| 14 | [14_DEFINITION_OF_DONE.md](14_DEFINITION_OF_DONE.md) |
| 15 | [15_RISK_REGISTER.md](15_RISK_REGISTER.md) |
| 16 | [16_DEPLOYMENT_STRATEGY.md](16_DEPLOYMENT_STRATEGY.md) |

---

## Cross-references

[Product Portfolio](../TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md) (P-03) · [GOVERNANCE](../GOVERNANCE.md)
