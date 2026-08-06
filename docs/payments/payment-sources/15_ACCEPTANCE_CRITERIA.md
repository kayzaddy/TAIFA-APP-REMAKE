# 15 — Acceptance Criteria

---

## Executive summary

Staging sign-off criteria for Payment Sources Phase 2 and **gate to Phase 3 (Payment Orchestration Platform)**.

---

## Business purpose

Objective quality gate.

---

## Functional

| ID | Criterion |
| --- | --- |
| AC-F1 | Customer grants consent and links M-Pesa → `active` source |
| AC-F2 | Customer links second provider; sets default; `default_changed` event |
| AC-F3 | Unlink revokes consent cascade |
| AC-F4 | `validate` fails appropriately for suspended source |
| AC-F5 | Provider discovery returns only enabled providers |
| AC-F6 | Provider unavailable surfaces `503` / UI banner |
| AC-F7 | Card link via tokenization — no PAN in app logs |
| AC-F8 | Airtel (or 2nd MM) link path in staging |

---

## Non-functional

| ID | Criterion |
| --- | --- |
| AC-N1 | Link API p95 &lt; 3s excluding PSP user step |
| AC-N2 | 99.9% API availability 30d staging |
| AC-N3 | Webhook processing idempotent (replay test) |

---

## Security

| ID | Criterion |
| --- | --- |
| AC-S1 | Threat model signed |
| AC-S2 | ABAC denial tests customer A ≠ B |
| AC-S3 | Consent required on all link paths |

---

## Architecture

| ID | Criterion |
| --- | --- |
| AC-A1 | No `charge`, `capture`, `settlement` endpoints deployed |
| AC-A2 | OpenAPI `tnpi-payment-sources-v1` published |
| AC-A3 | Orchestrator service **not** processing money in Phase 2 env |

---

## Exit to Phase 3 (Orchestration)

See [PHASE2_GATE_PACKAGE.md](PHASE2_GATE_PACKAGE.md) §4.

---

## AWS / implementation / future

Evidence folder `docs/payments/payment-sources/evidence/` (future).

---

## Cross-references

[16_DEFINITION_OF_DONE.md](16_DEFINITION_OF_DONE.md)
