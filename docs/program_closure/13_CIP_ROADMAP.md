# 13. Continuous Improvement Roadmap (CIP)

**Owner:** Head of Platform Excellence · Engineering Board  
**Constraint:** CIP ≠ redesign. Changes go through ARB when architecture-impacting.

---

## CIP themes (post-design)

| Theme | Examples | Priority |
| --- | --- | --- |
| Reliability | DR drill evidence, alert tuning, SLOs | P0 |
| Observability | MOS metrics completeness, pilot dashboards | P0 |
| DX | Seed scripts, env docs, API clarity | P1 |
| Debt | Demo commerce catch-all reduction (incremental) | P2 |
| Security | Pen-test cadence, dependency scanning | P0 |
| Ops excellence | Playbook drills, support macros | P0 |
| Pilot learnings | Convert field friction into backlog | P0 |

## Cadence

| Ritual | Output |
| --- | --- |
| Weekly eng CIP triage | Ranked backlog ≤ 5 active items |
| Monthly platform CIP review | Debt burn-down + SLO trends |
| Quarterly architecture CIP | Only ARB-approved evolutions |

## Anti-patterns (banned)

- New platform greenfields before pilot G6  
- Parallel payment/ledger paths  
- AI “payment authority” features  
- Silent schema forks without migration governance  

Success of CIP = fewer incidents, faster recovery, clearer ops — not more modules.
