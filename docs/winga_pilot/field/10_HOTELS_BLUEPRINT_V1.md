# 10. Hotels Industry Blueprint v1 — DRAFT (Not Certified)

**Certification status:** **NOT CERTIFIED**  
**Reason:** Field exit criteria unmet (0 completed bookings).  
**Promote to Certified** only when [`11_NATIONAL_EXPANSION_GO_NO_GO.md`](11_NATIONAL_EXPANSION_GO_NO_GO.md) Gate C passes.

This draft packages the **intended** Hotels operating model on the existing Winga engine.

---

## 1. Industry configuration

| Setting | Value |
| --- | --- |
| Domain | `hotels` |
| Default commission | 1000 bps |
| Peak campaign example | 1200 bps (`hotels-pilot-peak`) |
| Geography (v1) | Dar es Salaam · Harbour View / CBD |
| Currency | TZS |

## 2. Workflow

Lead → Inquiry → Quotation → Offer → Accepted → Payment → Fulfillment (Stay) → Settlement → Commission Payout → Review → Closed

## 3. Commission rules

Provider/campaign override → domain default → optional multi-level for agencies.

## 4. Provider requirements

KYB · inventory · pricing · availability · cancellation policy · media · settlement contact · ≤4h lead SLA · training.

## 5. Customer journey

Discover → Winga → Quote → Negotiate → Pay → Stay → Review → Repeat.

## 6. Winga journey

Onboard → Opportunities → Lead → Negotiate → Customer pays → Settle → Coach.

## 7. Documents

Quote · payment receipt (`payment_ref`) · hotel confirmation · commission statement.

## 8. Reports

Daily ops · weekly pilot · analytics summary · financial reconciliation.

## 9. KPIs / exit bars

≥30 bookings · ≥8 earning Wingas · ≥8 hotels continue · CSAT ≥4.2 · zero money defects · repeat interest.

## 10. Training

Hotel, Winga, customer, ops playbooks (see FIELD_PROGRAM + support macros).

## 11. Operational procedures

Onboarding gates · daily monitor · freeze rules · weekly improvement without scope expansion.

---

## Field overlays (to fill during pilot)

| Overlay | Status |
| --- | --- |
| Actual winning commission rates | TBD |
| Actual response SLAs hotels keep | TBD |
| Winning acquisition channels | TBD |
| Support macros that reduce tickets | TBD |

Do **not** ship this blueprint as “proven” until overlays are evidence-backed.
