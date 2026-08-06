# Engineering guidelines

---

## Scope

All engineers contributing to `taifa-platform`.

---

## Principles

1. **Platform-first** — [TPOS engineering standards](../../docs/tpos/05_ENGINEERING_STANDARDS.md).  
2. **Monorepo clarity** — one change, one PR, scoped paths.  
3. **Test before pilot** — E2E against staging platforms.  
4. **Observability by default** — logs, metrics, traces on new services.  
5. **Security shift-left** — threat model before pilot.

---

## Languages (indicative)

| Area | Stack |
| --- | --- |
| Mobile | Flutter (Dart) |
| Web | TypeScript / React or aligned stack |
| BFF / services | Python (Django/FastAPI) or Go per ADR |
| IaC | Terraform |
| Contracts | OpenAPI 3.1, CloudEvents |

---

## Code review

- Minimum **2** approvals for `main`; **1** must be CODEOWNER.  
- Security-sensitive paths require security reviewer.  
- No merge if CI red.

---

## Architecture & documentation reviews

Per [REPOSITORY_GOVERNANCE.md](../governance/REPOSITORY_GOVERNANCE.md).

---

## Dependency management

- Pin versions in lockfiles; Dependabot/Renovate weekly.  
- No copy-paste vendor SDKs—use `packages/` wrappers.  
- License allow-list in CI.

---

## Cross-references

[ARCHITECTURE_GUIDELINES.md](ARCHITECTURE_GUIDELINES.md) · [CODING_STANDARDS.md](CODING_STANDARDS.md) · [DOCUMENTATION_STANDARDS.md](DOCUMENTATION_STANDARDS.md)
