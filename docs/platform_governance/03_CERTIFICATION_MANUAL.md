# 3. Platform Certification Manual

**Owner:** Certification Board chair (CTO or delegate)  

---

## Certification categories

| Cert | Proves | Primary evidence |
| --- | --- | --- |
| Architecture | Boundaries & reuse | ARB minutes, threat model, ERD, API review |
| Engineering | Build quality | CI, coverage, contract/perf/security tests |
| Security | Controls | AuthZ review, vuln scan, pen-test (as required), audit logs |
| Operations | Runability | Handbook, runbooks, monitoring, incident drills |
| Business | Real value | Pilot KPIs, CSAT, retention, GMV (domain-specific) |
| Production | Launch-safe | Prod readiness checklist, rollback, DR |
| National | Scale-controlled | G7 + G8 + capacity + compliance |

All certifications are **evidence-based**. Software feature count is not evidence of Business or National cert.

---

## Levels

| Level | Meaning |
| --- | --- |
| L0 Draft | Vision/architecture only |
| L1 Engineering | G2 passed |
| L2 Experience | G3 passed |
| L3 Ops-Ready | G4 passed |
| L4 Pilot | G5–G6 in progress / passed |
| L5 Certified | G7 passed |
| L6 Production | G8 passed for target env |
| L7 National | Multi-region/national rollout approved |

---

## Recertification

- Major architecture change → Architecture + Security re-review  
- Sev-1 money integrity → Production cert suspended until cleared  
- Annual Platform Health Report required for L5+  

Checklist library: [`12_CERTIFICATION_CHECKLISTS.md`](12_CERTIFICATION_CHECKLISTS.md).
