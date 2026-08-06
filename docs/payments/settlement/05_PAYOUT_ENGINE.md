# 05 — Payout Engine

---

## Executive summary

Execute **payouts**: bank transfer, mobile money (M-Pesa B2C, etc.), batch/scheduled, retry, failure recovery, notifications.

---

## Business purpose

Convert settlement obligations into PSP money movement instructions.

---

## Architecture

```mermaid
flowchart LR
  PO[Payout] --> ADP[PSP Payout Adapter]
  ADP --> MM[Mobile Money]
  ADP --> BNK[Bank RTGS/ACH]
  PO --> RET[Retry Queue]
```

---

## Payout state

```mermaid
stateDiagram-v2
  [*] --> initiated
  initiated --> submitted: send_psp
  submitted --> completed: confirm
  submitted --> failed: error
  failed --> retry_pending: retryable
  retry_pending --> submitted: retry
  completed --> [*]
```

---

## Sequence: M-Pesa B2C payout

```mermaid
sequenceDiagram
  participant S as Settlement
  participant P as Payout Engine
  participant MP as M-Pesa B2C
  participant M as Merchant
  S->>P: payout.initiated
  P->>MP: disperse funds
  MP-->>P: ConversationID
  P-->>Bus: payout.completed
  P-->>M: notification webhook
```

---

## Capabilities

| Feature | Phase 5 |
| --- | --- |
| Bank transfer | ● |
| Mobile money payout | ● |
| Batch payout | ● |
| Scheduled | ● |
| Instant T+0 | Future flag |
| Retry | ● |
| Failure recovery | ● |

Destination accounts from [Merchant Platform settlement accounts](../merchant/07_API_SPECIFICATION.md).

---

## API / events / security

Payout approval workflow for high value; KMS for API keys.

---

## AWS

SQS retry; DLQ; Lambda status callbacks.

---

## Implementation strategy

Idempotent payout per `settlement_item_id`.

---

## Operational model

Treasury reconciliation handoff to Phase 6.

---

## Future expansion

Multi-currency nostro.

---

## Cross-references

[07_EVENT_CATALOG.md](07_EVENT_CATALOG.md)
