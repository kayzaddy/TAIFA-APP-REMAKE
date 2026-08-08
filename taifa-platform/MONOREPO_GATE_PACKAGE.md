# taifa-platform — Monorepo Gate Package

**Gate:** G0 — Repository structure & governance  
**PDL:** PDL-026  
**Date:** 2026-08-06

---

## Exit criteria

| # | Criterion | Evidence |
| --- | --- | --- |
| 1 | Root governance files | `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, … |
| 2 | Full directory tree | [docs/engineering/REPOSITORY_TREE.md](docs/engineering/REPOSITORY_TREE.md) |
| 3 | Engineering standards | `docs/engineering/*` |
| 4 | Repository governance & boards | `docs/governance/*` |
| 5 | DevSecOps design | [docs/governance/DEVSECOPS.md](docs/governance/DEVSECOPS.md) |
| 6 | Legacy mapping | [docs/engineering/LEGACY_REPO_MAPPING.md](docs/engineering/LEGACY_REPO_MAPPING.md) |
| 7 | ADR | [docs/decisions/ADR-0001-enterprise-monorepo.md](docs/decisions/ADR-0001-enterprise-monorepo.md) |
| 8 | No application scaffold | Structure + docs only |

---

## Not in scope (this gate)

- Moving `apps/` or `infra/` physical paths
- Flutter / service implementation
- Production CI wiring (stubs only)

---

## Next gate (G1)

- CODEOWNERS teams in GitHub org
- First path-filter CI on `packages/` or `docs/`
- ARB-approved migration slice #1
