# 05 — Engineering Standards

---

## Executive summary

Engineering standards for Taifa products: **consume approved platforms**, architecture alignment, API usage, data boundaries, observability.

---

## Platform consumption (mandatory)

| Capability | Platform | Product rule |
| --- | --- | --- |
| Identity / SSO / MFA | [Taifa Core](../platform/00_PLATFORM_OVERVIEW.md) | Never custom auth |
| Payments | [TNPI](../payments/00_PAYMENT_PROGRAM.md) | Never payment engines in product |
| Notifications | Core | Never standalone SMS gateway |
| Maps | Core | Never embed third-party keys in client |
| Media | Core | Presigned uploads |
| Search | Core | Index via approved pipelines |
| Analytics | Core / product plan | Event taxonomy in `15_ANALYTICS_PLAN.md` |
| Integration | [TIP](../integration/00_PLATFORM_OVERVIEW.md) | All partner/API traffic via TIP |
| Government services | [GDSP](../government/00_PLATFORM_OVERVIEW.md) | No agency workflows in product |
| Mobility ops | [TNMP](../mobility/00_PLATFORM_OVERVIEW.md) | Fares/tickets via [TPP](../transport/00_PLATFORM_OVERVIEW.md) → TNPI |

Document all usage in product `12_API_USAGE.md`.

---

## Technical design standards

- BFF pattern for mobile/web when aggregating platforms  
- OpenAPI-first for product-owned APIs  
- Idempotency on all money-adjacent operations (delegate to TNPI)  
- Feature flags for rollout ([08_RELEASE_STANDARDS.md](08_RELEASE_STANDARDS.md))  
- Correlation IDs propagated (`X-Taifa-Request-Id`)

---

## Architecture review

Required **before implementation**—[16_REFERENCE_ARCHITECTURE.md](16_REFERENCE_ARCHITECTURE.md); ARB sign-off recorded in `24_DECISION_LOG.md`.

---

## Code & repo

- Monorepo conventions per [SPRINT_0](../platform/SPRINT_0_ENGINEERING_PLAN.md)  
- Domain code in `apps/`; product docs in `docs/products/{slug}/`  
- No secrets in git; Secrets Manager only

---

## Observability

- Structured logging, metrics, traces on BFF and workers  
- SLOs defined before production

---

## Cross-references

[06_SECURITY_STANDARDS.md](06_SECURITY_STANDARDS.md) · [07_QA_STANDARDS.md](07_QA_STANDARDS.md)
