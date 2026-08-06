# 16 — Deployment Strategy

---

## Executive summary

Progressive deployment: **staging → pilot cohort → regional → national**; blue/green BFF; feature flags per module.

---

## Business purpose

Safe first production business app on national platforms.

---

## Pipeline

```mermaid
flowchart LR
  CI[CI tests] --> STG[Staging]
  STG --> PILOT[Pilot merchants]
  PILOT --> PROD[Production]
```

---

## Strategies

| Strategy | Application |
| --- | --- |
| **Blue/green** | BFF ECS services |
| **Canary** | 5% merchants new BFF version |
| **Feature flags** | SoftPOS, AI, payment links |
| **Database** | Flyway migrations; backward compatible |
| **Mobile** | Staged rollout Play/App Store |
| **Rollback** | Previous ECS task definition < 15 min |

---

## Pilot cohort

500 merchants invited; white-glove support; daily KPI review.

---

## Observability gates

Error rate < 1%, p95 latency SLO, zero Sev-1 before canary expand.

---

## DR

Multi-AZ RDS; RPO 15m; runbook quarterly.

---

## Compliance

Align with TNPI merchant terms; data residency af-south-1.

---

## Cross-references

[08_AWS_ARCHITECTURE.md](08_AWS_ARCHITECTURE.md)
