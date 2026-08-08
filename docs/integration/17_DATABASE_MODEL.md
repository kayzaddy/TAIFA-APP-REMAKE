# 17 — Database Model

**Schema:** `integration_platform`

---

## Executive summary

SoR for partners, products, subscriptions, routes metadata, webhook configs, flow definitions—not domain business data.

---

## ER diagram

```mermaid
erDiagram
  PARTNER ||--o{ SUBSCRIPTION : has
  API_PRODUCT ||--o{ SUBSCRIPTION : sold
  API_PRODUCT ||--o{ API_PLAN : tiers
  PARTNER ||--o{ CREDENTIAL : owns
  PARTNER ||--o{ CERTIFICATE : mTLS
  WEBHOOK_ENDPOINT ||--o{ DELIVERY_LOG : logs
  FLOW_DEFINITION ||--o{ FLOW_EXECUTION : runs
  ADAPTER ||--o{ ADAPTER_RUN : instances
```

---

## Cross-references

[15_API_SPECIFICATION.md](15_API_SPECIFICATION.md)
