# 08 — Database Model

**Schema:** `settlement` (PostgreSQL)

---

## Executive summary

Enterprise ER for settlement, batches, items, instructions, commissions, fees, tax, payouts, reports, audit.

---

## ER diagram

```mermaid
erDiagram
  SETTLEMENT ||--o{ SETTLEMENT_ITEM : has
  SETTLEMENT }o--o| SETTLEMENT_BATCH : in
  SETTLEMENT_BATCH ||--o{ PAYOUT : contains
  SETTLEMENT_ITEM ||--o{ COMMISSION : may_have
  SETTLEMENT_ITEM ||--o{ FEE : may_have
  SETTLEMENT_ITEM ||--o{ TAX : may_have
  PAYOUT ||--o{ PAYOUT_ATTEMPT : tries
  SETTLEMENT ||--|| SETTLEMENT_INSTRUCTION : instruction
  SETTLEMENT_REPORT ||--o{ SETTLEMENT_BATCH : summarizes

  SETTLEMENT {
    uuid id PK
    uuid payment_id UK
    uuid merchant_id
    enum status
    jsonb amounts
  }
  SETTLEMENT_BATCH {
    uuid id PK
    date settlement_date
    enum status
    timestamptz closed_at
  }
  SETTLEMENT_ITEM {
    uuid id PK
    uuid payee_merchant_id
    jsonb net_amount
  }
  PAYOUT {
    uuid id PK
    uuid batch_id FK
    enum rail
    enum status
  }
  PAYOUT_ATTEMPT {
    uuid id PK
    string psp_ref
  }
```

---

## Reconciliation handoff

Export `settlement_batch_id`, `payout_id`, `psp_ref` for Phase 6 matcher.

---

## API / events / security

Encrypt payee account tokens; audit all mutations.

---

## AWS

RDS Multi-AZ; S3 for reports; read replica for merchant queries.

---

## Implementation strategy

Ledger postings reference `settlement_id` per [PAYMENTS.md](../../PAYMENTS.md).

---

## Future expansion

Partition payouts by month.

---

## Cross-references

[02_SETTLEMENT_MODEL.md](02_SETTLEMENT_MODEL.md)
