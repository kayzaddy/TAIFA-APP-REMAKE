# 5. Engineering Quality Standards

**Owner:** Engineering Board · Principal QA Architect  
**Extends:** [`../governance/ENGINEERING_STANDARDS.md`](../governance/ENGINEERING_STANDARDS.md) · [`../governance/DEVSECOPS.md`](../governance/DEVSECOPS.md) · [`../governance/QUALITY_ENGINEERING.md`](../governance/QUALITY_ENGINEERING.md)

---

## Gate G2 mandatory

| Control | Requirement |
| --- | --- |
| Code review | Required on default branch |
| Static analysis | CI gate |
| Dependency scanning | CI gate |
| Secrets scanning | CI gate · zero high secrets |
| Contract / OpenAPI tests | Pass where APIs published |
| Unit + integration tests | Suite green |
| Security tests | AuthZ / money-path as applicable |
| Performance tests | Critical paths meet budget or waiver |
| Coverage thresholds | Per ENGINEERING_STANDARDS |
| CI/CD quality gates | No `--no-verify` in production path |

## Definition of Engineering Complete

All G2 rows evidenced in CI artifacts or signed waiver (Risk + Eng Board).
