# 09 — Database Model

**Engine:** PostgreSQL 15+ (RDS Multi-AZ)  
**Schema:** `merchant` (dedicated schema or DB per service)

---

## Executive summary

Enterprise relational model for Merchant Platform entities with hierarchy, RBAC, devices, settlement metadata, documents, webhooks, API keys, notifications references, and audit linkage.

---

## Business purpose

Single SoR schema design before migrations; supports thousands of branches per merchant via indexing strategy.

---

## ER diagram (core)

```mermaid
erDiagram
  MERCHANT ||--o{ BRANCH : has
  MERCHANT ||--o{ EMPLOYEE : employs
  MERCHANT ||--o{ SETTLEMENT_ACCOUNT : pays_to
  MERCHANT ||--o{ VERIFICATION_CASE : kyb
  MERCHANT ||--o{ DOCUMENT : stores
  MERCHANT ||--o{ API_KEY : issues
  MERCHANT ||--o{ WEBHOOK_ENDPOINT : registers
  MERCHANT ||--o{ BUSINESS_LICENSE : holds
  BRANCH ||--o{ ORG_UNIT : contains
  BRANCH ||--o{ DEVICE : hosts
  EMPLOYEE ||--o{ ROLE_ASSIGNMENT : has
  ROLE ||--o{ ROLE_ASSIGNMENT : granted
  ROLE ||--o{ ROLE_PERMISSION : includes
  PERMISSION ||--o{ ROLE_PERMISSION : maps
  MERCHANT ||--o{ MERCHANT_CONTRACT : signs
  MERCHANT ||--o{ MERCHANT_PREFERENCE : configures
  MERCHANT ||--o{ AUDIT_LOG_REF : audited

  MERCHANT {
    uuid id PK
    string legal_name
    string trade_name
    string tin UK
    string mcc
    enum status
    timestamptz created_at
  }
  BRANCH {
    uuid id PK
    uuid merchant_id FK
    uuid parent_branch_id FK
    enum branch_type
    string name
    jsonb address
  }
  EMPLOYEE {
    uuid id PK
    uuid merchant_id FK
    uuid user_id FK
    enum status
  }
  DEVICE {
    uuid id PK
    uuid branch_id FK
    enum device_type
    enum status
    string certificate_ref
  }
  SETTLEMENT_ACCOUNT {
    uuid id PK
    uuid merchant_id FK
    enum rail
    string account_ref_token
    bool verified
  }
  API_KEY {
    uuid id PK
    uuid merchant_id FK
    string key_prefix
    string secret_hash
    jsonb scopes
  }
  WEBHOOK_ENDPOINT {
    uuid id PK
    uuid merchant_id FK
    string url
    string secret_hash
  }
  DOCUMENT {
    uuid id PK
    uuid merchant_id FK
    enum doc_type
    string s3_key
  }
  VERIFICATION_CASE {
    uuid id PK
    uuid merchant_id FK
    enum outcome
  }
```

---

## Key indexes

| Table | Index |
| --- | --- |
| `merchant` | `(tin)`, `(status)`, `(mcc)` |
| `branch` | `(merchant_id, parent_branch_id)` |
| `employee` | `(merchant_id, user_id)` unique |
| `device` | `(branch_id, status)` |
| `api_key` | `(key_prefix)` |

---

## Hierarchy query pattern

Closure table or `ltree` for `branch` ancestry (choose in implementation ADR).

---

## Domain model mapping

[03_DOMAIN_MODEL.md](03_DOMAIN_MODEL.md)

---

## API specifications

Persistence behind [07_API_SPECIFICATION.md](07_API_SPECIFICATION.md).

---

## Events

State changes → [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md).

---

## AWS architecture

RDS Multi-AZ; read replica for search/reporting; S3 for documents; no PAN storage.

---

## Security considerations

Encrypt `account_ref_token` with KMS; row-level security optional per merchant_id for multi-tenant queries.

---

## Implementation strategy

Alembic/Django migrations isolated in merchant service; no FK to payment tables in Phase 1.

---

## Future expansion

Partition `audit_log_ref` by month; read models for dashboard search (OpenSearch).

---

## Cross-references

[DATA_MODEL.md](../../DATA_MODEL.md) — legacy alignment notes in implementation guide
