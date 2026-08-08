# 09 — Database Model

**Schema:** `reconciliation`

---

## Executive summary

ER for jobs, batches, matches, exceptions, adjustments, statements, summaries, audit, closing.

---

## ER diagram

```mermaid
erDiagram
  RECONCILIATION_JOB ||--o{ RECONCILIATION_BATCH : contains
  RECONCILIATION_BATCH ||--o{ MATCH_RESULT : produces
  RECONCILIATION_BATCH ||--o{ EXCEPTION : may_have
  EXCEPTION ||--o| ADJUSTMENT : resolves_with
  PROVIDER_STATEMENT ||--o{ EXTERNAL_LINE : contains
  MERCHANT_STATEMENT ||--o{ MERCHANT_LINE : contains
  RECONCILIATION_JOB ||--o| FINANCIAL_SUMMARY : summary
  CLOSING_PERIOD ||--o{ AUDIT_RECORD : locks
  MATCH_RESULT {
    uuid id PK
    enum match_type
    uuid internal_ref
    uuid external_ref
    numeric confidence
  }
  EXCEPTION {
    uuid id PK
    enum type
    enum status
    jsonb delta
  }
```

---

## Read models

Replica or API read from orchestration/settlement—**no FK** across bounded contexts; store `payment_id`, `settlement_id`, `payout_id` UUIDs only.

---

## API / events / security

Immutable `audit_record` append-only.

---

## AWS

RDS; S3 for statement files; lifecycle to Glacier.

---

## Implementation strategy

Partition `external_line` by statement date.

---

## Future expansion

Data warehouse star schema export.

---

## Cross-references

[02_RECONCILIATION_MODEL.md](02_RECONCILIATION_MODEL.md)
