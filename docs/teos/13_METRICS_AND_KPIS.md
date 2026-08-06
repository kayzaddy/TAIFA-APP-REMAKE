# 13 — Metrics and KPIs

**Owner:** Engineering Council · **Reporting:** Monthly

---

## DORA (primary)

| Metric | Target (mature) | Source |
| --- | --- | --- |
| **Deployment frequency** | Daily+ (services); weekly (mobile) | CI/CD |
| **Lead time for changes** | &lt; 1 day (services) | Git + deploy |
| **Change failure rate** | &lt; 15% | Incidents / deploys |
| **MTTR** | &lt; 1h Sev2 | PIR |

---

## Quality

| Metric | Target |
| --- | --- |
| Code coverage (delta) | ≥ 70% on changed lines |
| Bug escape rate | &lt; 5% of stories post-release |
| Build success rate | ≥ 95% on main |

---

## Delivery

| Metric | Target |
| --- | --- |
| Sprint predictability | ≥ 80% committed done |
| Technical debt ratio | Tracked; cap 20% sprint capacity |

---

## Reliability

| Metric | Target |
| --- | --- |
| SLO attainment | ≥ target per service |
| Incident count Sev1 | 0 per quarter (goal) |

---

## Review cadence

- Squad: weekly  
- Engineering Council: monthly  
- Executive: quarterly with TPOS alignment

---

## Cross-references

[tpos metrics](../tpos/) · [14_GOVERNANCE.md](14_GOVERNANCE.md)
