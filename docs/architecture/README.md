# Taifa Platform — Architecture Governance (Canonical)

**Status:** Authoritative technical constitution for the entire Taifa ecosystem.  
**Audience:** Developers, architects, AI agents, reviewers, partners.

| # | Document | Topic |
| --- | --- | --- |
| 00 | [00_ARCHITECTURE_CONSTITUTION.md](00_ARCHITECTURE_CONSTITUTION.md) | Mission, principles, lifecycle — **the law** |
| 01 | [01_DOMAIN_GOVERNANCE.md](01_DOMAIN_GOVERNANCE.md) | Ownership, bounded contexts, dependencies, ACL |
| 02 | [02_EVENT_CATALOG.md](02_EVENT_CATALOG.md) | Canonical events, envelope, DLQ, retention |
| 03 | [03_API_STANDARDS.md](03_API_STANDARDS.md) | REST, versioning, auth, OpenAPI, idempotency |
| 04 | [04_DATABASE_STANDARDS.md](04_DATABASE_STANDARDS.md) | Schema ownership, migrations, UUID, audit |
| 05 | [05_SECURITY_STANDARDS.md](05_SECURITY_STANDARDS.md) | Zero trust, OAuth/OIDC, KMS, compliance |
| 06 | [06_CODING_STANDARDS.md](06_CODING_STANDARDS.md) | Structure, boundaries, testing, review checklists |
| 07 | [07_DEPLOYMENT_STANDARDS.md](07_DEPLOYMENT_STANDARDS.md) | Environments, CI/CD, IaC, rollback |
| 08 | [08_ADR_GUIDELINES.md](08_ADR_GUIDELINES.md) | ADR process, template, approval |
| 09 | [09_DEFINITION_OF_DONE.md](09_DEFINITION_OF_DONE.md) | Mandatory ship checklist |

**Compliance:** [GOVERNANCE_COMPLIANCE_REPORT.md](GOVERNANCE_COMPLIANCE_REPORT.md) — Tourism vs constitution.

**Taifa Core (Phase 1 implementation):** [platform/README.md](../platform/README.md)

**Related (non-duplicative):**

- **Enterprise blueprint & EARB:** [`../platform/README.md`](../platform/README.md)
- Product lifecycle & certification: [`../platform_governance/00_INDEX.md`](../platform_governance/00_INDEX.md)
- Enterprise program governance: [`../GOVERNANCE.md`](../GOVERNANCE.md)
- Tourism domain pack: [`../tourism/00_INDEX.md`](../tourism/00_INDEX.md)
