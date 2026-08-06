# 05 — Database Design

---

## Executive summary

**Schema:** `taifa_merchant` — application data only; **no** payment rows, wallet balances, or KYB legal store.

---

## Business purpose

Persist UX, CRM, preferences; cache optional with TTL.

---

## Tables (indicative)

| Table | Purpose |
| --- | --- |
| `merchant_workspace` | `merchant_id`, settings, theme |
| `onboarding_progress` | Step completion (mirror TNPI status) |
| `user_preferences` | Identity `user_id` scoped |
| `customer_profile` | Merchant CRM |
| `insight_session` | AI thread metadata |
| `report_schedule` | Scheduled export jobs |
| `dashboard_widget` | Layout |

---

## Caching strategy

Transaction lists: **do not** duplicate; Redis cache of TNPI API responses TTL 30–60s for dashboard only.

---

## ER

See [03_DOMAIN_MODEL.md](03_DOMAIN_MODEL.md).

---

## Security

RLS by `merchant_id`; encrypt PII columns; no PAN.

---

## Cross-references

[TNPI merchant 09_DATABASE_MODEL.md](../payments/merchant/09_DATABASE_MODEL.md) — authoritative merchant master.
