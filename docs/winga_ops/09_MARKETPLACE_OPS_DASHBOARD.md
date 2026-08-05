# 9. Marketplace Operations Dashboard

**Owner:** Marketplace Operations  
**Refresh:** Daily morning checklist + live API  
**Canvas:** `winga-marketplace-ops.canvas.tsx`  
**Honesty:** Display measured values only. Week 0 field = zeros where no live volume.

---

## Health panels

### A. Participants
Active providers · Active Wingas · Active customers (period)

### B. Funnel
Leads · Quotes · Accepts · Payments · Completed stays · Cancellations

### C. Money
GMV · Commission settled · Settlement latency · Pending commissions · Exceptions open

### D. Liquidity / utilization
Providers with ≥1 paid deal · Wingas with ≥1 paid deal · Lead coverage ratio

### E. Trust / support
Open Critical tickets · Disputes · Fraud flags · CSAT (if n>0)

### F. Platform
Uptime / alerts (from platform observability)

---

## Daily log template

```
Date:
Operator:
Freeze active? (none / PAY / SETTLE):
New providers:
New Wingas:
Pending verifications (>48h):
New leads:
Quotes awaiting (breach count):
Accepted unpaid:
Payments captured:
Settlements done:
Pending commissions:
Failed/stuck workflows:
Support Critical/High open:
Platform alerts:
KPI notes:
Actions:
Sign-off:
```

---

## Week 0 measured baseline (2026-07-18)

| Panel metric | Value |
| --- | --- |
| Field paid bookings | 0 |
| Field GMV | 0 |
| Open settlement exceptions | 0 |
| Hotels live | 0 (onboarding incomplete) |
| Certified Wingas (checklist) | 0 |

Update this table only from ops evidence.
