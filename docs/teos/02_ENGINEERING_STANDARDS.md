# 02 — Engineering standards

**Owner:** VP Engineering · **Status:** Mandatory

---

## Repository structure

Canonical layout: [taifa-platform REPOSITORY_TREE](../../taifa-platform/docs/engineering/REPOSITORY_TREE.md).

| Area | Rule |
| --- | --- |
| Monorepo | `taifa-platform/` is SSOT target; legacy paths migrate per LEGACY_REPO_MAPPING |
| Platforms | `platforms/{name}/` |
| Products | `products/{slug}/` |
| Services | `services/` runtime deployables |
| APIs | `apis/openapi/` contracts |
| IaC | `infrastructure/terraform/` |

---

## Branching & Git

See [05_GIT_STANDARDS.md](05_GIT_STANDARDS.md). Summary: trunk-based `main`, short-lived `feature/*`, protected `main`.

---

## Commits & PRs

- Conventional Commits ([taifa-platform COMMIT_STANDARDS](../../taifa-platform/docs/engineering/COMMIT_STANDARDS.md))  
- PR template required; CODEOWNERS review  
- No force-push to `main`

---

## ADRs

Format: [19_DECISION_RECORDS.md](19_DECISION_RECORDS.md). Store under `docs/decisions/` or `docs/adr/`.

---

## Code style

[04_CODING_STANDARDS.md](04_CODING_STANDARDS.md) — language-specific; enforced in CI.

---

## Error handling & logging

- User errors: stable codes + safe messages (no stack traces)  
- Structured JSON logs; `request_id` / `trace_id` propagation ([12_OBSERVABILITY.md](12_OBSERVABILITY.md))

---

## Configuration & secrets

- 12-factor env config; no secrets in git  
- AWS Secrets Manager + GitHub OIDC ([08_SECURITY_ENGINEERING.md](08_SECURITY_ENGINEERING.md))

---

## Dependencies

- Lockfiles committed; weekly Dependabot/Renovate  
- License allow-list in CI  
- No vendored SDK copies without ARB exception

---

## Versioning

| Artifact | Scheme |
| --- | --- |
| Services | Semver + git SHA image tag |
| APIs | URL or header per [API governance](../governance/API_GOVERNANCE.md) |
| Mobile | Semver + build number |
| Terraform modules | Semver tags |

---

## API standards

OpenAPI 3.1 in `apis/`; TIP registration before external exposure; breaking = 12-month deprecation.

---

## Database standards

- Migrations forward-only in prod  
- No payment ledger in product DBs (TNPI)  
- Indexes on tenant keys; RLS where multi-tenant app data

---

## Flutter & backend

[04_CODING_STANDARDS.md](04_CODING_STANDARDS.md) § Mobile / § Server.

---

## IaC

Terraform modules; tag `taifa_{env}_{resource}`; plan in PR ([06_DEVSECOPS.md](06_DEVSECOPS.md)).

---

## Documentation

[taifa-platform DOCUMENTATION_STANDARDS](../../taifa-platform/docs/engineering/DOCUMENTATION_STANDARDS.md) + runbooks for on-call paths.

---

## Cross-references

[governance/ENGINEERING_STANDARDS.md](../governance/ENGINEERING_STANDARDS.md)
