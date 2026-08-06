# 16 — Definition of Done

---

## Executive summary

Per-story and per-release DoD for Merchant Platform work—aligned with [architecture/09_DEFINITION_OF_DONE.md](../../architecture/09_DEFINITION_OF_DONE.md).

---

## Business purpose

Consistent quality bar before merge and release.

---

## Story DoD

| # | Item |
| --- | --- |
| 1 | OpenAPI updated if API changed |
| 2 | Event schema updated if event added/changed |
| 3 | Migration reviewed (forward-only) |
| 4 | Unit tests for domain invariants |
| 5 | Integration test for happy path |
| 6 | RBAC test for new endpoint |
| 7 | Audit event verified |
| 8 | No secrets in logs |
| 9 | PR description links MB-xxx |
| 10 | CODEOWNERS review for `merchant` paths |

---

## Release DoD (staging)

| # | Item |
| --- | --- |
| 1 | Changelog / release notes |
| 2 | Runbook updated |
| 3 | Dashboards for error rate + latency |
| 4 | Rollback procedure tested |
| 5 | Feature flag default documented |

---

## Architecture / security

Threat model ticket closed or deferred with ADR.

---

## AWS

IaC change in PR if infra touched; `terraform validate` green.

---

## Implementation strategy

Enforce via PR template checklist section **TNPI Merchant**.

---

## Future expansion

Add performance budget per endpoint group.

---

## Cross-references

[15_ACCEPTANCE_CRITERIA.md](15_ACCEPTANCE_CRITERIA.md)
