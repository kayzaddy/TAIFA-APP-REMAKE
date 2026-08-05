# 14. Executive Dashboard Templates

**Owner:** Head of Platform Excellence · CPO  

---

## Dashboard set

| Audience | Panels |
| --- | --- |
| Engineering | CI health, coverage, MTTR for build, open Sev eng |
| Operations | Uptime, incidents, SLA, freeze status |
| Security | Vulns, secrets findings, IR open |
| Business | GMV/usage (domain), retention, CSAT (n) |
| Finance | Settlement exceptions, recon status |
| Executive | Gate status, cert level, top risks |
| Platform Health | Scorecard dimensions |
| Certification Status | Per-platform L0–L7 |
| Risk | Open Critical/High risks |
| Compliance | Attestations due |

## Rules

- Separate **lab** vs **field** metrics  
- Link to evidence  
- Canvas + `GET /api/v1/governance/scorecard` for live machine data  

Template weekly/monthly: [`15_REVIEW_TEMPLATES.md`](15_REVIEW_TEMPLATES.md).
