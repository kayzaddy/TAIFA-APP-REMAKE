# 03 — Domain Model

---

## Executive summary

Application domain model for Taifa Merchant—**thin** where TNPI/Identity already own aggregates.

---

## Business purpose

Clear aggregates for BFF and UI; avoid competing SoR.

---

## Aggregates (application-owned)

| Aggregate | Responsibility |
| --- | --- |
| `MerchantWorkspace` | Links `merchant_id`, preferences, onboarding UI state |
| `DashboardLayout` | Widgets, pinned reports |
| `CustomerProfile` | Merchant-local CRM (TNPI `customer_ref` optional) |
| `AIInsightSession` | Prompt history, dismissed insights |
| `NotificationPreference` | Channel toggles per user |
| `ReportSchedule` | Email report cron refs |

---

## References (external SoR)

| Ref | Source |
| --- | --- |
| `merchant_id` | TNPI Merchant |
| `branch_id`, `employee_id`, `device_id` | TNPI Merchant (synced) |
| `payment_id`, `refund_id` | TNPI Orchestration |
| `user_id` | Identity |

---

## ER diagram (application schema)

```mermaid
erDiagram
  MERCHANT_WORKSPACE ||--o{ USER_PREFERENCE : has
  MERCHANT_WORKSPACE ||--o{ CUSTOMER_PROFILE : crm
  MERCHANT_WORKSPACE ||--o{ AI_INSIGHT_SESSION : has
  MERCHANT_WORKSPACE {
    uuid id PK
    uuid merchant_id UK
    jsonb onboarding_state
  }
  CUSTOMER_PROFILE {
    uuid id PK
    text display_name
    uuid tnpi_customer_ref nullable
  }
```

---

## Domain events (application)

`merchant.app.onboarding.completed` (UX) · `merchant.insight.viewed` — do not duplicate TNPI `merchant.approved`.

---

## Cross-references

[05_DATABASE_DESIGN.md](05_DATABASE_DESIGN.md)
