# 09 — Definition of Done

**Purpose:** Mandatory checklist before any feature, epic, or production change is considered **complete**.  
**Scope:** All Taifa modules; applies to human developers and AI-generated changes.  
**Principles:** No “done” without evidence; architecture compliance is not optional.

---

## Checklist (all items required unless N/A with ARB note)

### Architecture

- [ ] **Architecture reviewed** — ARB or delegate for cross-domain; module architect for local-only  
- [ ] **Domain assigned** — Primary bounded context documented in PR description ([01_DOMAIN_GOVERNANCE.md](01_DOMAIN_GOVERNANCE.md))  
- [ ] **ADR created** if required ([08_ADR_GUIDELINES.md](08_ADR_GUIDELINES.md))  

### Contracts

- [ ] **API documented** — OpenAPI updated; follows [03_API_STANDARDS.md](03_API_STANDARDS.md)  
- [ ] **Events documented** — New/changed events in [02_EVENT_CATALOG.md](02_EVENT_CATALOG.md) + module doc  
- [ ] **Backward compatibility** — Deprecation headers if breaking path planned  

### Data

- [ ] **Database migration prepared** — Reversible where possible; owner domain only ([04_DATABASE_STANDARDS.md](04_DATABASE_STANDARDS.md))  
- [ ] **No cross-domain writes** — Verified in code review  

### Security

- [ ] **Security reviewed** — Per [05_SECURITY_STANDARDS.md](05_SECURITY_STANDARDS.md) trigger table  
- [ ] **AuthZ tests** — Owner/partner denial cases  

### Quality

- [ ] **Tests completed** — Unit + integration per [06_CODING_STANDARDS.md](06_CODING_STANDARDS.md)  
- [ ] **Contract tests** — If new port integration  

### Operations

- [ ] **Monitoring configured** — Dashboards/alarms for new critical path  
- [ ] **Metrics defined** — Business + golden signals (latency, errors)  
- [ ] **Runbook snippet** — If new failure mode for on-call  

### Documentation

- [ ] **Documentation updated** — Module `00_INDEX` or domain §8–§10 as applicable  
- [ ] **DoD linked in PR** — Copy checklist with checkmarks  

---

## Decision table — N/A handling

| Item | N/A when |
| --- | --- |
| Events | Read-only UI with no state change |
| Migration | Documentation-only PR |
| Security review | Typos in comments (still need peer review) |

N/A requires **one-line justification** in PR; ARB may reject lazy N/A.

---

## PR template snippet

```markdown
## Domain
Primary: {e.g. tourism.orchestration}

## Definition of Done
- [ ] Architecture reviewed (link)
- [ ] API/OpenAPI (link)
- [ ] Events (link or N/A)
- [ ] Migrations (link or N/A)
- [ ] Security (link or N/A)
- [ ] Tests (link)
- [ ] Monitoring (link or N/A)
- [ ] Docs (link)
- [ ] ADR (link or N/A)
```

---

## Relationship to platform certification

Module **production launch** also requires [`platform_governance/11_PRODUCTION_READINESS.md`](../platform_governance/11_PRODUCTION_READINESS.md) gates. DoD is **per change**; certification is **per platform release**.

---

## Cross-references

- [00_ARCHITECTURE_CONSTITUTION.md](00_ARCHITECTURE_CONSTITUTION.md)  
- Tourism gate: [`../tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md`](../tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md) §12  
- [`../PRODUCTION_GATE.md`](../PRODUCTION_GATE.md)

---

## Future considerations

- Automated DoD bot commenting on PRs (OpenAPI file touched, migration present, etc.)  
- Compliance score in [`governance/SCORECARD.md`](../governance/SCORECARD.md)
