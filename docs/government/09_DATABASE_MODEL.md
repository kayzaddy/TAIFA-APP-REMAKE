# 09 — Database Model

**Schema:** `government_platform`

---

## Executive summary

ER for catalog, applications, workflows, documents, appointments, inspections—**payment_id references only**.

---

## Business purpose

Case SoR for digital government journey; agency remains legal SoR via sync.

---

## ER diagram

```mermaid
erDiagram
  ORGANIZATION ||--o{ SERVICE_DEFINITION : publishes
  SERVICE_DEFINITION ||--o{ APPLICATION : generates
  APPLICATION ||--o{ APPLICATION_EVENT : audit
  APPLICATION ||--o{ DOCUMENT_REF : attaches
  APPLICATION ||--|| WORKFLOW_INSTANCE : runs
  WORKFLOW_INSTANCE ||--o{ TASK : has
  APPLICATION ||--o| PAYMENT_REF : fee
  INSPECTION ||--o| APPLICATION : related
  APPOINTMENT ||--o| APPLICATION : optional
  ISSUED_PERMIT ||--|| APPLICATION : issues
  ORGANIZATION {
    uuid id PK
    enum org_type
    text tin_optional
  }
  APPLICATION {
    uuid id PK
    enum status
    uuid subject_id
    uuid payment_id nullable
  }
```

---

## Forbidden

Password hashes, PAN, wallet balances, custom payment state machines duplicating TNPI.

---

## Context map (data)

| Data | System of record |
| --- | --- |
| Application case (digital) | GDSP |
| Legal register entry | Agency |
| Payment | TNPI |
| Identity | Taifa Identity |

---

## API / events

[07](07_API_SPECIFICATION.md), [08](08_EVENT_CATALOG.md).

---

## Security

Tenant isolation per `organization_id`; RLS.

---

## AWS

RDS PostgreSQL Multi-AZ; S3 for blobs.

---

## Implementation strategy

Partition application events; read replicas for analytics.

---

## Future expansion

Federated query to agency read replicas (controlled).

---

## Cross-references

[03_WORKFLOW_ENGINE.md](03_WORKFLOW_ENGINE.md)
