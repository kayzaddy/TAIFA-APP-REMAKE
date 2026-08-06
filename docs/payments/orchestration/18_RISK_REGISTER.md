# 18 — Risk Register

---

## Executive summary

Orchestration-phase risks.

---

## Risks

| ID | Risk | Pri | Mitigation |
| --- | --- | --- | --- |
| OR-01 | Double spend idempotency failure | P1 | Chaos tests, DB constraints |
| OR-02 | Saga compensation incomplete | P1 | Step Functions tests, runbooks |
| OR-03 | Router sends to unhealthy PSP | P1 | Health gating |
| OR-04 | Legacy + new router divergence | P1 | Shadow mode |
| OR-05 | Vertical modules bypass orchestrator | P1 | Governance + lint |
| OR-06 | Webhook replay attack | P2 | HMAC + timestamp |
| OR-07 | Pending payment stuck | P2 | Sweeper + alerts |
| OR-08 | Settlement event without settlement service | P2 | Consumer optional until Phase 2 settlement build |

---

## Cross-references

[PHASE3_GATE_PACKAGE.md](PHASE3_GATE_PACKAGE.md)
