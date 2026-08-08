# 02 — Settlement Model

**Bounded context:** `finance.settlement`

---

## Executive summary

Core domain: **Settlement**, **SettlementItem**, instructions, commissions, fees, tax lines, linkage to `payment_id` from orchestration—Taifa tracks **obligations and payout state**, not consumer balances.

---

## Business purpose

Single SoR for what is owed and what was paid out.

---

## Architecture overview

```mermaid
flowchart LR
  PAY[payment_id] --> SI[SettlementItem]
  SI --> S[Settlement aggregate]
  S --> SB[SettlementBatch]
  SB --> PO[Payout]
```

---

## Aggregate: Settlement

| Attribute | Description |
| --- | --- |
| `settlement_id` | UUID |
| `payment_id` | Orchestration reference |
| `merchant_id` | Primary merchant |
| `workflow_type` | merchant, marketplace, gov, transport, tourism |
| `status` | pending, calculated, batched, executing, completed, failed, reversed |
| `gross_amount` | Money VO |
| `net_payable` | After fees/tax |
| `settlement_window` | Business date + cutoff |

---

## State machine

```mermaid
stateDiagram-v2
  [*] --> pending: payment_completed_event
  pending --> calculated: calculate
  calculated --> batched: assign_batch
  batched --> executing: payout_initiated
  executing --> completed: payout_ok
  executing --> failed: payout_fail
  failed --> executing: retry
  completed --> reversed: reversal
  reversed --> [*]
```

---

## Settlement workflows

| Workflow | Trigger metadata |
| --- | --- |
| Merchant standard | `channel`, MCC |
| Marketplace | `split_rules[]` |
| Government | `gov.agency_id`, levy codes |
| Transport | `mobility.operator_id` |
| Tourism | `tourism.product_type` |
| Refund settlement | `payment.refunded` adjustment |
| Chargeback | `payment.chargeback` |

---

## ER snippet

```mermaid
erDiagram
  SETTLEMENT ||--o{ SETTLEMENT_ITEM : contains
  SETTLEMENT }o--|| SETTLEMENT_BATCH : optional
  SETTLEMENT_ITEM ||--o{ COMMISSION : may_have
  SETTLEMENT_ITEM ||--o{ FEE : may_have
  SETTLEMENT_ITEM ||--o{ TAX_LINE : may_have
  SETTLEMENT_BATCH ||--o{ PAYOUT : generates
```

---

## API / events

[06](06_API_SPECIFICATION.md) · [07](07_EVENT_CATALOG.md)

---

## Security

Maker-checker on manual adjustments.

---

## AWS

RDS settlement schema.

---

## Implementation strategy

Idempotent ingest per `payment_id`.

---

## Future expansion

Multi-currency settlement records.

---

## Cross-references

[08_DATABASE_MODEL.md](08_DATABASE_MODEL.md)
