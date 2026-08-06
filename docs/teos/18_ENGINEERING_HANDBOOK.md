# 18 — Engineering handbook

**One-page index for practitioners**

---

## What is TEOS?

The **Taifa Engineering Operating System** — mandatory *how* we build. TPOS defines *what* products deliver. EA defines *where* platforms sit.

---

## Daily workflow

1. Pick ticket → branch `feature/{id}-{slug}`  
2. Design note or ADR if needed  
3. Code + tests per [04_CODING_STANDARDS.md](04_CODING_STANDARDS.md)  
4. PR with [16_CHECKLISTS.md](16_CHECKLISTS.md) template  
5. Merge when CI + reviews pass

---

## When to escalate

| Situation | Contact |
| --- | --- |
| New microservice / API version break | ARB |
| Payment, PII, auth design | Security Council |
| Prod deploy / train | Release Board |
| Outage | SRE on-call |

---

## Document map

| I need… | Read |
| --- | --- |
| Lifecycle & gates | [01](01_ENGINEERING_LIFECYCLE.md) |
| Repo, git, APIs | [02](02_ENGINEERING_STANDARDS.md), [05](05_GIT_STANDARDS.md) |
| CI/CD | [06](06_DEVSECOPS.md) |
| Testing | [07](07_QA_FRAMEWORK.md) |
| Security | [08](08_SECURITY_ENGINEERING.md) |
| On-call / SLOs | [09](09_SRE_GUIDE.md), [11](11_INCIDENT_MANAGEMENT.md) |
| Metrics | [13](13_METRICS_AND_KPIS.md) |
| Step-by-step | [15](15_PLAYBOOK.md) |

---

## Monorepo

Primary implementation standards: [taifa-platform/docs/engineering](../../taifa-platform/docs/engineering/README.md).

---

## Implementation guide (TEOS rollout)

| Phase | Actions |
| --- | --- |
| **0 — Adopt** | All squads acknowledge TEOS; EM training |
| **1 — CI** | PR template, lint, test, secret scan on all repos |
| **2 — Gates** | EGR/PAR templates for pilot products (e.g. Merchant) |
| **3 — SRE** | SLOs + dashboards for prod services |
| **4 — Mature** | DORA metrics, game days, radar refresh |

Track progress in [20_ROADMAP.md](20_ROADMAP.md).

---

## Cross-references

[00_TEOS_CHARTER.md](00_TEOS_CHARTER.md) · [tpos/00_TPOS_CHARTER.md](../tpos/00_TPOS_CHARTER.md)
