# 09 — Operations

---

## Executive summary

Standard **operations**: dashboards, KPIs, logging, metrics, alerts, incidents, support, feedback.

---

## Dashboards (minimum)

| Dashboard | Audience |
| --- | --- |
| Product health | Error rate, latency, availability |
| Business KPI | From `22_SUCCESS_METRICS.md` |
| Platform deps | TNPI/TIP status overlay |

---

## Logging & metrics

- JSON structured logs; no PII  
- RED metrics (Rate, Errors, Duration) on BFF  
- Business events to Analytics per `15_ANALYTICS_PLAN.md`

---

## Alerts

| Severity | Response |
| --- | --- |
| Sev-1 | 15 min acknowledge |
| Sev-2 | 1 h |
| Sev-3 | Next business day |

---

## Support tiers

| Tier | Scope |
| --- | --- |
| L1 | User helpdesk |
| L2 | Product ops |
| L3 | Engineering on-call |

---

## Feedback collection

- In-app feedback widget  
- NPS quarterly for production products  
- Feed into `25_RETROSPECTIVE.md` and backlog

---

## Cross-references

[18_SUCCESS_METRICS.md](18_SUCCESS_METRICS.md) · [15_PLAYBOOK.md](15_PLAYBOOK.md)
