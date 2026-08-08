# 03 — State Machine

---

## Executive summary

**Canonical payment state machine** for all TNPI payments—including failure, retry, refund, and chargeback paths.

---

## Business purpose

Eliminate ambiguous payment status across modules.

---

## State diagram

```mermaid
stateDiagram-v2
  [*] --> created
  created --> validated: validate_ok
  created --> failed: validate_fail
  validated --> authorized: auth_ok
  validated --> failed: auth_fail
  authorized --> pending: async_psp
  pending --> captured: capture_ok
  pending --> failed: psp_fail
  pending --> expired: timeout
  authorized --> captured: auto_capture
  captured --> completed: confirm
  completed --> settlement_requested: emit
  settlement_requested --> reconciled: external
  reconciled --> archived: retention
  completed --> refunded: refund_full
  completed --> partially_refunded: refund_partial
  authorized --> cancelled: cancel
  created --> cancelled: cancel_early
  failed --> retry_pending: retryable
  retry_pending --> validated: retry
  completed --> chargeback: dispute
  chargeback --> reversed: lost
  failed --> [*]
  cancelled --> [*]
  archived --> [*]
```

---

## State definitions

| State | Description |
| --- | --- |
| `created` | Intent persisted, not validated |
| `validated` | Merchant, customer, source, amount OK |
| `authorized` | PSP hold or MM push accepted |
| `pending` | Awaiting PSP callback |
| `captured` | Funds instruction sent |
| `completed` | Terminal success for commerce |
| `settlement_requested` | Event to settlement service |
| `reconciled` | Matched by recon service (external) |
| `archived` | Cold storage policy |
| `failed` | Terminal failure |
| `cancelled` | Void before completion |
| `expired` | TTL exceeded |
| `refunded` / `partially_refunded` | Money return initiated |
| `reversed` | Chargeback lost |
| `chargeback` | Dispute open |
| `retry_pending` | Scheduled retry |
| `timed_out` | Alias mapped to `expired` in API |

---

## Transitions rules

- Only orchestrator service may transition state (SoR).
- Illegal transitions return `409 conflict`.
- All transitions emit `payment.*` event + audit.

---

## Sequence: retry path

```mermaid
sequenceDiagram
  participant O as Orchestrator
  participant Q as Retry Queue
  participant R as Router
  O->>Q: schedule retry_pending
  Q->>O: dequeue
  O->>R: select alternate provider
  R-->>O: attempt result
```

---

## API mapping

`GET /payments/{id}` returns `status` enum matching machine.

---

## Events

`payment.retry`, `payment.timeout`, etc. — [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md)

---

## Database

`payment.status`, `payment_attempt.status` — [09_DATABASE_MODEL.md](09_DATABASE_MODEL.md)

---

## Security / AWS / implementation

Immutable state history table; Step Functions sync with DB.

---

## Future expansion

`partial_success` for split payments.

---

## Cross-references

[02_PAYMENT_LIFECYCLE.md](02_PAYMENT_LIFECYCLE.md)
