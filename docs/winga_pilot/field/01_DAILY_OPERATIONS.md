# 1. Daily Operations Dashboard — Hotels Field Pilot

**Date:** _YYYY-MM-DD_  
**Pilot day:** Week 0 / Day —  
**Filled by:** Operations  
**Source rule:** API + ops log only. Empty cells = not measured. Never estimate.

---

## Snapshot (Week 0 baseline — 2026-07-18)

| Metric | Value | Source |
| --- | --- | --- |
| Active Wingas (used app today) | 0 | ops / analytics |
| Active hotels (inbound today) | 0 | ops |
| New leads | 0 | `/api/v1/winga/leads` |
| Quotes created | 0 | quotations |
| Offers accepted | 0 | deals ≥ accepted |
| Bookings completed (stays) | **0** | fulfillment + hotel confirm |
| Payments | **0** | deals with payment_ref |
| Settlements | 0 | commission settle |
| Commissions settled (minor) | 0 | analytics summary |
| Support requests opened | 0 | ticket log |
| Refunds | 0 | payments ops |
| Disputes | 0 | deal stage disputed |
| CSAT responses today | 0 | survey |
| Hotel satisfaction notes | 0 | interview log |

---

## Roster readiness (not bookings)

| Item | Count |
| --- | --- |
| Hotel roster slots | 10 |
| Hotels field-verified | 1 |
| Winga roster slots | 20 |
| Wingas field-verified (scaffold flag) | 5 |
| Customers recruited | 0 |

---

## Daily template (copy per day)

```
Date:
Active Wingas:
Active hotels:
New leads:
Quotes:
Accepted:
Paid bookings:
Completed stays:
Settlements:
Commission minor:
Support open / closed:
Refunds:
Disputes:
Blockers:
Actions tomorrow:
```

Live visual: Cursor canvas `winga-hotels-daily-ops.canvas.tsx`
