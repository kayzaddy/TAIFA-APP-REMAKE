# 09 — Database Model

**Engine:** PostgreSQL 15+ · **Schema:** `payment_sources`

---

## Executive summary

Relational model for customers, payment sources, providers, tokens, consents, preferences, provider status, and audit references.

---

## Business purpose

Schema blueprint before migrations.

---

## ER diagram

```mermaid
erDiagram
  CUSTOMER ||--|| CUSTOMER_PAYMENT_PROFILE : owns
  CUSTOMER_PAYMENT_PROFILE ||--o{ PAYMENT_SOURCE : has
  CUSTOMER_PAYMENT_PROFILE ||--o| PAYMENT_PREFERENCE : configures
  PAYMENT_SOURCE }o--|| PROVIDER : via
  PAYMENT_SOURCE ||--o| TOKEN_REFERENCE : card
  PAYMENT_SOURCE ||--o{ CONSENT : requires
  PROVIDER ||--|| PROVIDER_CONFIGURATION : config
  PROVIDER ||--|| PROVIDER_STATUS : health
  LINK_SESSION ||--o| PAYMENT_SOURCE : creates
  AUDIT_LOG_REF ||--o{ PAYMENT_SOURCE : tracks

  PAYMENT_SOURCE {
    uuid id PK
    uuid customer_id FK
    string provider_id FK
    enum type
    enum status
    string display_mask
    string nickname
    int priority
    bool is_default
    string provider_instrument_ref_enc
    uuid token_ref_id FK
  }
  TOKEN_REFERENCE {
    uuid id PK
    enum token_type
    string vault_pointer
    timestamptz expires_at
  }
  CONSENT {
    uuid id PK
    uuid customer_id
    enum consent_type
    jsonb scope
    timestamptz granted_at
    timestamptz revoked_at
  }
  PROVIDER {
    string id PK
    string display_name
    enum category
    bool enabled
  }
```

---

## Indexes

| Table | Index |
| --- | --- |
| `payment_source` | `(customer_id, status)`, unique partial `(customer_id) WHERE is_default` |
| `link_session` | `(session_id)`, TTL purge |
| `consent` | `(customer_id, consent_type, revoked_at)` |

---

## Domain model mapping

[03_PAYMENT_SOURCE_MODEL.md](03_PAYMENT_SOURCE_MODEL.md)

---

## API / events / AWS

Backed by RDS in [11_AWS_ARCHITECTURE.md](11_AWS_ARCHITECTURE.md).

---

## Security considerations

Encrypt `provider_instrument_ref_enc` with KMS; hash MSISDN for dedup index optional.

---

## Implementation strategy

No FK to `merchant` schema; customer_id from Identity only.

---

## Future expansion

Sharding by customer_id hash at 50M+ users.

---

## Cross-references

[DATA_MODEL.md](../../DATA_MODEL.md)
