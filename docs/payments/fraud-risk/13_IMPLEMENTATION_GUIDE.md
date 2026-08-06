# 13 — Implementation Guide

---

## Executive summary

Phased delivery FR-0–FR-7: platform shell, sync assess, rules, lists/cases, post-auth, ML hook, hardening, Phase 8 handoff.

---

## Business purpose

De-risk build order: orchestration dependency first, ops tooling before ML.

---

## Prerequisites

| Prerequisite | Owner |
| --- | --- |
| Orchestration pre-auth hook contract | Phase 3 |
| `payment.*` events on EventBridge | Phase 3 |
| Recon exception aggregates API/event | Phase 6 |
| Taifa Core identity for analyst RBAC | Platform |
| Redis + RDS provisioned | IaC |

---

## Service boundaries

| Service | Responsibility |
| --- | --- |
| `frp-assess` | Sync pipeline |
| `frp-rules` | Rule CRUD + compiler |
| `frp-cases` | Cases + alerts |
| `frp-lists` | Lists + maker-checker |
| `frp-workers` | Async consumers |

---

## Sprint map

See [PHASE7_GATE_PACKAGE.md](PHASE7_GATE_PACKAGE.md) §3 and [15_BACKLOG.md](15_BACKLOG.md).

---

## Orchestration integration

1. Orchestration calls `POST /risk/assess` before PSP route.  
2. On `decline`, orchestration fails payment with `risk_declined`.  
3. On `review`, hold state until case resolution webhook.  
4. Pass `assessment_id` on authorization record.

---

## Reconciliation integration

Subscribe to daily `reconciliation.exception.summary` (or poll API) — update merchant trust deltas only; **no write to recon**.

---

## Risk decision flow (implementation)

Feature flags: `frp_enabled`, `frp_fail_closed`, `frp_shadow_mode` (log only).

---

## Testing strategy

- Contract tests with orchestration stub  
- Load test 500 RPS assess staging  
- Rule dry-run on synthetic dataset  
- Pen test on admin APIs  

---

## AWS rollout

Dev → test → staging → prod; blue/green assess service.

---

## Security gate

SoD, audit, KMS before prod lists publish.

---

## DoD

[17_DEFINITION_OF_DONE.md](17_DEFINITION_OF_DONE.md)

---

## Future expansion

Partner merchant fraud API (read-only scores).

---

## Cross-references

[14_ROADMAP.md](14_ROADMAP.md) · [16_ACCEPTANCE_CRITERIA.md](16_ACCEPTANCE_CRITERIA.md)
