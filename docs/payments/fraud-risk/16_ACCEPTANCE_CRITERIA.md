# 16 — Acceptance Criteria

---

## Executive summary

Staging acceptance for FRP before production and Phase 8 Developer Platform kickoff.

---

## Functional — assess (AC-F1–F4)

| ID | Criterion |
| --- | --- |
| AC-F1 | Orchestration calls assess; approve path completes payment in sandbox |
| AC-F2 | Decline blocks payment with reason codes |
| AC-F3 | Review holds payment until case resolve webhook |
| AC-F4 | Idempotent assess returns same `assessment_id` |

---

## Rules & lists (AC-F5–F8)

| ID | Criterion |
| --- | --- |
| AC-F5 | Velocity rule triggers review in test scenario |
| AC-F6 | Blacklist decline without override |
| AC-F7 | Whitelist fast-path approve documented |
| AC-F8 | Rule publish requires checker approval |

---

## Cases & async (AC-F9–F12)

| ID | Criterion |
| --- | --- |
| AC-F9 | `payment.completed` triggers post-auth rule |
| AC-F10 | Case created from escalate decision |
| AC-F11 | Investigator close updates disposition + audit |
| AC-F12 | Recon signal increases merchant risk score in test |

---

## Non-functional (AC-N1–N4)

| ID | Criterion |
| --- | --- |
| AC-N1 | p99 assess &lt; 150 ms at 100 RPS staging |
| AC-N2 | FRP unavailable: fail-closed prod policy verified in drill |
| AC-N3 | All assess decisions in immutable audit |
| AC-N4 | No PAN in logs (automated scan) |

---

## Exit Phase 8

See [PHASE7_GATE_PACKAGE.md](PHASE7_GATE_PACKAGE.md) §6.

---

## Cross-references

[17_DEFINITION_OF_DONE.md](17_DEFINITION_OF_DONE.md)
