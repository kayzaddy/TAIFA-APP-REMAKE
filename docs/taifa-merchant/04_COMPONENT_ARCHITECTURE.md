# 04 — Component Architecture

---

## Executive summary

Component model: **Web + Mobile** → **Merchant BFF** → platform SDKs; optional **read cache**; no payment engine.

---

## Business purpose

Implementable service boundaries for engineering.

---

## Component diagram

```mermaid
flowchart TB
  subgraph clients [Clients]
    WA[Web Angular or React]
    FL[Flutter Merchant App]
  end
  subgraph edge [Edge]
    TIP[TIP API Gateway]
  end
  subgraph taifa_merchant [Taifa Merchant services]
    BFF[merchant-bff]
    WORKER[merchant-worker]
    RDS[(App RDS)]
  end
  subgraph platforms [Platforms]
    ID[Identity]
    TNPI[TNPI APIs]
    AI[AI Gateway]
    NOTIF[Notifications]
    MEDIA[Media]
    SEARCH[Search]
    AUDIT[Audit]
    MAPS[Maps]
  end
  WA & FL --> TIP --> BFF
  BFF --> RDS
  BFF --> ID & TNPI & AI & NOTIF & MEDIA & SEARCH & MAPS
  WORKER --> NOTIF & AUDIT
  TNPI -.events.-> WORKER
```

---

## Sequence: accept QR payment

```mermaid
sequenceDiagram
  participant C as Cashier app
  participant B as Merchant BFF
  participant M as TNPI MAP
  participant O as TNPI Orchestration
  C->>B: create QR session
  B->>M: POST acceptance/qr
  M->>O: payment intent
  O-->>B: payment_id + QR payload
  B-->>C: display QR
  O-->>B: webhook payment.completed
  B-->>C: push via Notifications
```

---

## Sequence: refund

```mermaid
sequenceDiagram
  participant M as Manager
  participant B as BFF
  participant O as TNPI
  M->>B: refund request
  B->>B: RBAC check
  B->>O: POST refunds
  O-->>B: refund_id
  B->>Audit: log action
```

---

## Module-to-component map

| Module | Primary component |
| --- | --- |
| Onboarding | BFF + TNPI Merchant client |
| Dashboard | BFF aggregation |
| Acceptance | BFF → MAP |
| Transactions | BFF → Orchestration read |
| AI Assistant | BFF → AI tools (read TNPI analytics) |

---

## Cross-references

[06_API_SPECIFICATION.md](06_API_SPECIFICATION.md) · [08_AWS_ARCHITECTURE.md](08_AWS_ARCHITECTURE.md)
