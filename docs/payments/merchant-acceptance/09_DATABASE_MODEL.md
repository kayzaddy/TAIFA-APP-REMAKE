# 09 — Database Model

**Schema:** `acceptance` (MAP-owned presentation + session state)

---

## Executive summary

MAP SoR for channels; **payment SoR remains Orchestration** (`payment_id` FK reference only).

---

## ER diagram

```mermaid
erDiagram
  TERMINAL ||--o{ MERCHANT_DEVICE : maps
  MERCHANT_DEVICE ||--o{ TRANSACTION_SESSION : runs
  TRANSACTION_SESSION ||--o| PAYMENT_REF : payment_id
  QR ||--o{ QR_SCAN : logs
  PAYMENT_LINK ||--o| PAYMENT_REF : optional
  TRANSACTION_SESSION ||--o| RECEIPT : generates
  MERCHANT_DEVICE ||--o{ DEVICE_HEALTH : samples
  MERCHANT_DEVICE ||--o{ OFFLINE_QUEUE : stores
  CUSTOMER_RECEIPT ||--|| RECEIPT : share

  TERMINAL {
    uuid id PK
    uuid merchant_id
    uuid branch_id
    enum terminal_type
  }
  MERCHANT_DEVICE {
    uuid id PK
    uuid terminal_id FK
    uuid merchant_device_ref
    enum status
  }
  TRANSACTION_SESSION {
    uuid id PK
    uuid device_id FK
    enum channel
    enum state
    uuid payment_id nullable
  }
  QR {
    uuid id PK
    enum qr_type
    string payload_sig
    timestamptz expires_at
  }
  PAYMENT_LINK {
    uuid id PK
    string token UK
    enum link_type
    jsonb amount
  }
  RECEIPT {
    uuid id PK
    uuid payment_id
    string s3_key
  }
  OFFLINE_QUEUE {
    uuid id PK
    jsonb signed_intent
    enum sync_status
  }
```

---

## Design rules

- No amount finalization without `payment_id` from orchestration (except offline queue pre-sync).  
- `merchant_device_ref` → Merchant Platform `device_id`.

---

## API / events / security

PII minimal on receipts.

---

## AWS

RDS + S3 receipts; Redis session TTL.

---

## Implementation strategy

Read models for history from orchestration replica optional.

---

## Operational model

Archive sessions > 24 months.

---

## Future expansion

Partition offline_queue by device.

---

## Cross-references

[merchant/09_DATABASE_MODEL.md](../merchant/09_DATABASE_MODEL.md)
