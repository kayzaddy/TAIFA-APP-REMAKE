# 15 — Backlog

---

## Executive summary

Orchestration MoSCoW backlog.

---

## Must have

| ID | Story | Pts | Sprint |
| --- | --- | --- | --- |
| ORB-001 | Payment aggregate + state machine | 13 | OR-1 |
| ORB-002 | Idempotency middleware | 5 | OR-1 |
| ORB-003 | Validate merchant (API) | 5 | OR-1 |
| ORB-004 | Validate payment_source (API) | 5 | OR-1 |
| ORB-005 | Create + get payment APIs | 8 | OR-1 |
| ORB-006 | Authorize/capture/cancel | 13 | OR-2 |
| ORB-007 | M-Pesa execution adapter | 13 | OR-2 |
| ORB-008 | PaymentAttempt persistence | 5 | OR-2 |
| ORB-009 | Router v1 rules | 8 | OR-3 |
| ORB-010 | Failover + retry queue | 8 | OR-3 |
| ORB-011 | Outbox + payment.* events | 8 | OR-4 |
| ORB-012 | Webhook dispatcher | 8 | OR-4 |
| ORB-013 | Refund API | 8 | OR-4 |
| ORB-014 | Workflow registry + standard | 8 | OR-5 |
| ORB-015 | mobility.ticket.v1 workflow | 5 | OR-5 |
| ORB-016 | tourism.checkout.v1 workflow | 8 | OR-5 |
| ORB-017 | Step Functions saga template | 13 | OR-6 |
| ORB-018 | Fraud hook integration stub | 5 | OR-3 |
| ORB-019 | settlement/recon requested events | 3 | OR-4 |
| ORB-020 | Observability dashboards | 5 | OR-7 |
| ORB-021 | Load test 1k TPS | 8 | OR-7 |
| ORB-022 | Legacy router shadow mode | 8 | OR-7 |
| ORB-023 | Phase 3 gate evidence | 3 | OR-8 |

---

## Won't have (Phase 3)

Settlement batch processing · Recon matcher · SoftPOS app · QR generator

---

## Implementation strategy

Map to [PHASE3_GATE_PACKAGE.md](PHASE3_GATE_PACKAGE.md).

---

## Cross-references

[16_ACCEPTANCE_CRITERIA.md](16_ACCEPTANCE_CRITERIA.md)
