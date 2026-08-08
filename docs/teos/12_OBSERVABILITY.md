# 12 — Observability

**Owner:** Platform Engineering + SRE

---

## Three pillars

| Pillar | Standard |
| --- | --- |
| **Metrics** | RED/USE per service; business KPIs (TPS, success rate) |
| **Logs** | Structured JSON; retention 90d hot, 1y archive (compliance) |
| **Traces** | W3C trace context; sample 10% prod, 100% errors |

---

## Required instrumentation

- HTTP server: status, duration, route  
- Outbound calls: dependency name, status  
- DB: slow query log threshold  
- Queues: depth, age, DLQ count

---

## Dashboards

Minimum per production service:

1. Golden signals  
2. SLO burn rate  
3. Deploy markers  
4. Dependency health

---

## Alerting rules

- Page on SLO burn &gt; 2x budget in 1h  
- No paging on non-actionable alerts (lint quarterly)

---

## Cross-references

[09_SRE_GUIDE.md](09_SRE_GUIDE.md) · [02_ENGINEERING_STANDARDS.md](02_ENGINEERING_STANDARDS.md#observability)
