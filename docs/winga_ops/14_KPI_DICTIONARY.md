# 14. Operational KPI Dictionary

**Owner:** Principal Business Operations Architect / OpEx  
**Rule:** Every KPI has definition, source, owner, cadence. No vanity metrics without owner.

---

| KPI | Definition | Source | Owner | Cadence |
| --- | --- | --- | --- | --- |
| Bookings completed | Paid stays with fulfillment confirmed | Deals + hotel confirm log | Marketplace Ops | Daily/Weekly |
| GMV | Sum amount_minor of paid deals (period) | analytics / deals | Marketplace Ops | Daily/Weekly |
| Revenue (platform) | Platform take if configured; else 0 + note | Finance | Finance | Monthly |
| Commission volume | Sum settled commission_minor | CommissionEvent | Settlement | Daily/Weekly |
| Lead → quote conversion | Quotes / leads | Leads, Quotations | Marketplace Ops | Weekly |
| Quote → pay conversion | Paid deals / quotes | Deals | Marketplace Ops | Weekly |
| Booking conversion | Completed stays / leads | Ops | Marketplace Ops | Weekly |
| Cancellation rate | Cancelled / accepted | Deals | Marketplace Ops | Weekly |
| CSAT | Mean 1–5 (n reported) | Surveys | Customer Success | Weekly |
| NPS | Promoters−Detractors | Surveys | Customer Success | Monthly |
| Repeat booking rate | Customers with ≥2 paid / customers with ≥1 | Deals | Customer Success | Monthly |
| Time to first booking | Recruit/signup → first paid | Ops cohort | Customer Success | Monthly |
| Time to first commission | Winga certify → first settled | CommissionEvent | Winga Success | Monthly |
| Settlement latency | Pay time → commission settled time (median) | Events | Settlement | Daily/Weekly |
| Commission latency | Same as settlement latency unless split | Events | Settlement | Weekly |
| Support first response | Median time to first human reply | Tickets | Support | Daily/Weekly |
| Support SLA hit % | Tickets meeting severity SLA / total | Tickets | Support | Weekly |
| Provider retention | Live providers still live end/start period | Roster | Provider Success | Monthly |
| Winga retention | Certified active end/start | Roster | Winga Success | Monthly |
| Active providers | Providers with activity or live flag | Roster + deals | Marketplace Ops | Daily |
| Active Wingas | Certified with session or lead | Roster + leads | Marketplace Ops | Daily |
| Active customers | Principals with session or deal | Product/ops | Customer Success | Weekly |
| Marketplace liquidity | Wingas with ≥1 paid / certified Wingas | Derived | Marketplace Ops | Weekly |
| Provider utilization | Providers with ≥1 paid / live providers | Derived | Provider Success | Weekly |
| Winga utilization | Same as liquidity or leads/Winga | Derived | Winga Success | Weekly |
| Operational efficiency | Support tickets / completed booking | Derived | OpEx | Monthly |
| Open settlement exceptions | Unresolved recon items | Recon log | Settlement | Daily |
| Platform availability | Uptime % | Observability | Eng Support | Daily |

**Null handling:** If n=0, report `n/a` or `0` with note — never invent.
