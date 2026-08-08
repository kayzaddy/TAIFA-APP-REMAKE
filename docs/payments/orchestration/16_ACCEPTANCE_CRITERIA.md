# 16 — Acceptance Criteria

---

## Executive summary

Staging/production criteria for orchestration and **Phase 4 (Merchant Acceptance Platform)** gate.

---

## Functional

| ID | Criterion |
| --- | --- |
| AC-F1 | End-to-end payment create → completed via M-Pesa sandbox |
| AC-F2 | Idempotent replay returns same payment |
| AC-F3 | Failover to secondary provider on retryable error |
| AC-F4 | Refund partial/full |
| AC-F5 | Tourism + mobility workflows complete in staging |
| AC-F6 | Webhook delivered with valid signature |
| AC-F7 | `payment.settlement.requested` emitted on completion |
| AC-F8 | Merchant suspended → new payments rejected |

---

## Non-functional

| ID | Criterion |
| --- | --- |
| AC-N1 | 1k TPS sustained load test |
| AC-N2 | 99.95% SLO staging 30d |
| AC-N3 | p95 &lt; 500ms excluding PSP user action |

---

## Security

AC-S1 threat model · AC-S2 pen test no critical · AC-S3 ABAC tests

---

## Exit to Phase 4

See [PHASE3_GATE_PACKAGE.md](PHASE3_GATE_PACKAGE.md) §4.

---

## Cross-references

[17_DEFINITION_OF_DONE.md](17_DEFINITION_OF_DONE.md)
