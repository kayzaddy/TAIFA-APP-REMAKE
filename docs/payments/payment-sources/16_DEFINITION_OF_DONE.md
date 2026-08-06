# 16 — Definition of Done

---

## Executive summary

Story and release DoD for Payment Sources work.

---

## Business purpose

Consistent merge bar.

---

## Story DoD

| # | Item |
| --- | --- |
| 1 | OpenAPI + event schema updated |
| 2 | Adapter conformance tests if PSP touched |
| 3 | Integration test link → verify |
| 4 | Consent + audit verified |
| 5 | No secrets in logs; PSP creds in SM only |
| 6 | Idempotency on callbacks |
| 7 | PR links PSB-xxx |

---

## Release DoD

Dashboards, runbook, rollback, feature flag doc.

---

## Architecture / API / events / AWS / security

Align [architecture/09](../../architecture/09_DEFINITION_OF_DONE.md).

---

## Implementation strategy

PR template section **TNPI Payment Sources**.

---

## Future expansion

Performance budgets per provider.

---

## Cross-references

[15_ACCEPTANCE_CRITERIA.md](15_ACCEPTANCE_CRITERIA.md)
