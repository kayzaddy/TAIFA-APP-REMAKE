# Repository governance

---

## Boards (enterprise)

Aligns with [TPOS governance](../../../docs/tpos/10_PRODUCT_GOVERNANCE.md).

| Board | Scope in monorepo |
| --- | --- |
| **ARB** | `platforms/`, `services/` boundaries, `apis/`, cross-cutting `packages/` |
| **Engineering Review Board** | Code quality, DoD, testing strategy |
| **PRB** | `products/`, roadmaps |
| **Security Board** | `infrastructure/security`, auth, TNPI paths |
| **Release Board** | `automation/cd`, production tags |

---

## CODEOWNERS

- File: `.github/CODEOWNERS`  
- Each top-level path has `@taifa/{team}` (configure in GitHub org)

---

## Change categories

| Category | Approval |
| --- | --- |
| Docs only | 1 owner |
| Product feature | Product CODEOWNER + QA |
| Platform API break | ARB + TIP |
| IaC prod | DevSecOps + ARB |

---

## Repository roles

| Role | Responsibility |
| --- | --- |
| **Repo admin** | Branch protection, org settings |
| **Maintainer** | Merge rights per CODEOWNERS |
| **Contributor** | PRs |

---

## Audits

- Quarterly: dependency + secret scan review  
- Annual: access review IAM + GitHub

---

## Cross-references

[../engineering/ENGINEERING_GUIDELINES.md](../engineering/ENGINEERING_GUIDELINES.md)
