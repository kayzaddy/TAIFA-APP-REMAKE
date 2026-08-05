# 5. Marketplace Metrics Dashboard — Hotels Pilot

**Source of truth (live):** `GET /api/v1/winga/analytics/summary`  
**Companion:** Cursor canvas `winga-hotels-pilot-metrics.canvas.tsx`  
**Pilot tag:** `metadata.pilot = hotels-v1`

---

## KPI definitions

| KPI | Definition | Formula / source |
| --- | --- | --- |
| Leads | New Lead rows in period | `leads_total` delta |
| Quotes | Quotations created | Quotation count |
| Accepted | Deals ≥ `accepted` | Deal stage filter |
| Paid transactions | Deals with `payment_ref` | Deal pay events |
| GMV | Sum `amount_minor` paid deals | `gmv_by_domain` for `hotels` |
| Commission revenue | Settled commission sum | `commission_settled_minor` |
| Avg deal size | GMV / paid deals | derived |
| Conversion | Paid / leads | derived |
| Repeat customers | ≥2 paid deals same principal | query |
| Active Wingas | Wingas with ≥1 lead/week | query |
| Provider retention | Providers active week 6 / week 1 | ops sheet |
| Liquidity | (Wingas with deal) / verified Wingas | derived |

---

## Lab baseline (pre-field)

| Metric | Value | Note |
| --- | --- | --- |
| Verified hotels Wingas (seed) | 12 | `seed_winga_pilot_hotels` |
| Verified hotels providers (seed) | 1 | Harbour View |
| Active hotel offerings | 3 | King / Suite / Conference |
| Peak commission rule | 1200 bps | `hotels-pilot-peak` |
| Field GMV | 0 | Pilot not started |
| Field settled commission | 0 | Pilot not started |
| Automated money-path proofs | 7 backend + 8 mobile tests | 2026-07-18 |

---

## Field targets (exit)

| KPI | Exit bar |
| --- | --- |
| Paid transactions | ≥ 30 |
| Hotels GMV | ≥ TZS 15,000,000 (minor units per ledger convention) |
| Wingas with ≥1 settled commission | ≥ 8 of 12 |
| Customer CSAT | ≥ 4.2 / 5 |
| Critical financial defects | 0 |
| Provider retention intent | ≥ 70% “continue” |

Refresh weekly from analytics API + ops sheet. Do not fabricate mid-pilot numbers.
