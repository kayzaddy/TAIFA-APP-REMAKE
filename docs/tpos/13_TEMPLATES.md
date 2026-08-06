# 13 — Templates

---

## Executive summary

Copy-paste **templates** for standard product documents. Create files under `docs/products/{product-slug}/`.

---

## 00_PRODUCT_CHARTER.md (template)

```markdown
# Product Charter — {Product Name}

**Status:** Draft | Approved  
**Sponsor:**  
**Product Lead:**  
**Last updated:**

## Executive summary
(2–3 sentences)

## Problem statement

## Goals & non-goals
### Goals
### Non-goals

## Scope (in / out)

## Stakeholders

## Success criteria (link 22_SUCCESS_METRICS.md)

## Platform dependencies (link 12_API_USAGE.md)

## Timeline (link 18_ROADMAP.md)

## Approval
| Role | Name | Date |
| PRB | | |
```

---

## 02_BUSINESS_CASE.md (template)

```markdown
## Market opportunity
## Customer segments
## Competitive landscape
## Business value
## ROI model (assumptions)
## Investment required (squads, $)
## Risks (link 23)
## Recommendation
```

---

## 06_FEATURE_CATALOG.md (template)

| ID | Feature | Priority | Status | Owner | Notes |
| --- | --- | --- | --- | --- | --- |
| F-001 | | Must | Planned | | |

---

## 12_API_USAGE.md (template)

| Platform API | Use case | Environment | Owner service |
| --- | --- | --- | --- |
| Identity OIDC | Login | prod | merchant-bff |
| TNPI /v1/payments | Accept | staging | |

---

## 16_TEST_PLAN.md (template)

## Scope
## Test environments
## Test cases by journey (link 05)
## UAT participants
## Exit criteria

---

## 20_MVP.md (template)

## MVP summary (1 paragraph)
## In scope (bullets)
## Out of scope
## Success metrics
## Target date
## Dependencies

---

## 24_DECISION_LOG.md (template)

| ID | Date | Decision | Rationale | Approver |
| --- | --- | --- | --- | --- |

---

## 25_RETROSPECTIVE.md (template)

## Release / period
## What went well
## What to improve
## Actions (owner, due)

---

## Full list

See [03_PRODUCT_DOCUMENT_TEMPLATE.md](03_PRODUCT_DOCUMENT_TEMPLATE.md) for all 26 files—use section headers from peer products (e.g. [taifa-merchant](../taifa-merchant/01_PRODUCT_VISION.md)) as style reference.

---

## Cross-references

[14_CHECKLISTS.md](14_CHECKLISTS.md)
