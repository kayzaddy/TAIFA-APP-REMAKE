# 09 — Database Model

**Schema:** `fraud_risk`

---

## Executive summary

ER for assessments, scores, rules, profiles, lists, cases, alerts, investigations, audit.

---

## Business purpose

Durable SoR for risk decisions and investigations—not payment or ledger SoR.

---

## ER diagram

```mermaid
erDiagram
  RISK_ASSESSMENT ||--|| RISK_SCORE : has
  RISK_ASSESSMENT ||--o{ RULE_HIT : triggers
  FRAUD_RULE ||--o{ FRAUD_RULE_VERSION : versions
  MERCHANT_RISK_PROFILE ||--o{ RISK_ASSESSMENT : contextualizes
  CUSTOMER_RISK_PROFILE ||--o{ RISK_ASSESSMENT : contextualizes
  DEVICE_PROFILE ||--o{ RISK_ASSESSMENT : contextualizes
  WATCHLIST ||--o{ LIST_ENTRY : contains
  BLACKLIST ||--o{ LIST_ENTRY : contains
  WHITELIST ||--o{ LIST_ENTRY : contains
  FRAUD_CASE ||--o{ ALERT : links
  FRAUD_CASE ||--o{ INVESTIGATION : contains
  INVESTIGATION ||--o{ AUDIT_LOG : records
  RISK_ASSESSMENT {
    uuid id PK
    uuid payment_intent_id
    enum decision
    timestamptz created_at
  }
  RISK_SCORE {
    uuid id PK
    int score
    jsonb components
  }
  FRAUD_RULE {
    uuid id PK
    text rule_key UK
    enum status
  }
  FRAUD_CASE {
    uuid id PK
    enum status
    enum disposition
  }
```

---

## Entity summary

| Entity | Role |
| --- | --- |
| `RiskAssessment` | One assess request/response |
| `RiskScore` | Score breakdown |
| `FraudRule` / version | Rule definitions |
| `MerchantRiskProfile` | Rolling trust metrics |
| `CustomerRiskProfile` | Velocity, labels |
| `DeviceProfile` | Enrollment, reputation |
| `Watchlist` / `Blacklist` / `Whitelist` | List containers |
| `ListEntry` | Typed entry + expiry |
| `Alert` | Operational alert |
| `FraudCase` | Investigation container |
| `Investigation` | Activity thread |
| `AuditLog` | Immutable append |

---

## Cross-context references

Store `payment_id`, `merchant_id` as UUIDs **without FK** to orchestration DB.

---

## Redis (ephemeral)

Velocity counters, session device cache, assess idempotency keys (TTL).

---

## API / events

Written on `risk.assessment.completed`; cases on `case.*`.

---

## Security

Column-level encryption for national ID hashes; KMS for S3 evidence.

---

## AWS

RDS PostgreSQL Multi-AZ; read replica for reporting; Redis ElastiCache.

---

## Implementation strategy

Partition `risk_assessment` by month; archive &gt; 24 months to S3 parquet.

---

## Future expansion

Feature store tables for ML.

---

## Cross-references

[04_RISK_SCORING.md](04_RISK_SCORING.md) · [05_CASE_MANAGEMENT.md](05_CASE_MANAGEMENT.md)
