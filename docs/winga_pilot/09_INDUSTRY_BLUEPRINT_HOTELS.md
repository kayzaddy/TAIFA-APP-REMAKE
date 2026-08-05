# 9. Industry Blueprint — Hotels

Reusable template after a successful Hotels field pilot.  
Configure existing Winga engine — do not fork architecture.

---

## 1. Industry configuration

| Setting | Hotels value |
| --- | --- |
| Domain code | `hotels` |
| Default commission | 1000 bps (10%) |
| Peak / campaign | Provider rule e.g. 1200 bps (`hotels-pilot-peak`) |
| Offering kinds | Service / booking packages |
| Currency | TZS (pilot) |
| Geography | Start one city (Dar es Salaam) |

Seed: `python manage.py seed_winga` + `seed_winga_pilot_hotels`

---

## 2. Workflow

Use `winga.default_brokerage` stages:

Lead → Inquiry → Quotation → Offer → Accepted → Payment → Fulfillment → Settlement → Commission Payout → Review → Closed

Hotels aliases (UX only): Fulfillment = Stay · Settlement = Hotel payout · Commission Payout = Winga earn.

---

## 3. Commission rules

1. Provider campaign rule (priority low number wins)  
2. Domain default percentage  
3. Multi-level only if agency managers in cohort  

Settlement: `POST /api/v1/winga/deals/{id}/settle-commission` after pay.

---

## 4. Provider requirements

KYB · verified profile · rate integrity · response SLA · settlement terms · named ops contact.

---

## 5. Customer journey

Discover hotels → compare Winga/provider → request quote → accept → pay securely → stay → review → repeat.

App: `/winga/customer` (+ onboarding).

---

## 6. Winga journey

Onboard → opportunities → capture lead → negotiate → customer pays → settle commission → coach.

App: `/winga/broker` · `/winga/opportunities`.

---

## 7. Documents

| Document | Source |
| --- | --- |
| Quote | Quotation line_items |
| Payment receipt | `payment_ref` + ledger |
| Stay confirmation | Provider confirmation (ops/email in pilot) |
| Commission statement | CommissionEvent breakdown UI |

---

## 8. Reports

Weekly: GMV by hotels · commissions settled · open deals · disputes · CSAT.  
API: `/api/v1/winga/analytics/summary`.

---

## 9. KPIs

See Marketplace Metrics exit bars (paid ≥30, Wingas earning ≥8/12, CSAT ≥4.2, Critical defects = 0).

---

## 10. Training

| Audience | Material |
| --- | --- |
| Wingas | Desk walkthrough + commission quiz |
| Providers | Lead SLA + catalog honesty |
| Customers | “How payment works” one-pager |
| Ops | Support playbook + severity matrix |

---

## 11. Operational procedures

1. Verify cohort KYC/KYB before first deal.  
2. Freeze new pays on Critical money defect.  
3. Settle commissions daily for paid+fulfilled deals.  
4. Interview drop-offs within 48h.  
5. No AI financial authorization — ever.

---

## Packaging for next industry

Clone this blueprint → change domain code, commission bps, offering templates, SLA, city. Keep workflow and settlement engine unchanged.
