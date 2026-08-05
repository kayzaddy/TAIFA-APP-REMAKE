# 06 — Enterprise Architecture Review Report (EARB)

**Review date:** 2026-08-05  
**Board:** Chief EA, Chief Software Architect, DDD Expert, AWS SA, Security, FinTech, AI, API, Data, DevSecOps, Platform Engineering  
**Scope:** Full platform per mission; Tourism integration emphasis  
**Method:** Documentation review—no production code changes  
**Governance preserved:** [`architecture/`](../architecture/README.md), [`platform_governance/`](../platform_governance/00_INDEX.md)

---

## Executive summary

Taifa possesses a **credible national-scale architecture foundation**: payment spine, ecosystem control plane, mobility APIs, commerce verticals, and a **mature Tourism DDD pack**. The **Architecture Constitution** provides enforceable law.

**EARB verdict:** Architecture is **internally consistent at the documentation level** for platform spine and Tourism. **Enterprise-wide production certification** is **not yet justified** due to commerce concentration, incomplete event bus adoption, thin Identity/Trade/Health/Education packs, and unverified code-level boundary enforcement.

**Overall platform rating:** **Amber** (proceed with governed, incremental implementation—not national blast-radius expansion).

---

## Category ratings

| # | Category | Rating | Summary |
| --- | --- | --- | --- |
| 1 | Domain boundaries | **Amber** | Tourism clear; Commerce hosts multiple logical domains |
| 2 | Platform capability map | **Green** | Documented in `01_PLATFORM_CAPABILITY_MAP` |
| 3 | Enterprise context map | **Green** | Relationships + ACL identified |
| 4 | Canonical data model | **Amber** | New enterprise glossary; `DATA_MODEL.md` partial alignment |
| 5 | Event governance | **Amber** | Catalog strong; runtime EventBridge/outbox immature |
| 6 | API governance | **Green** | Constitution + OpenAPI CI; tourism/commerce path drift |
| 7 | Security | **Amber** | Standards set; pen-test, full OIDC pack pending |
| 8 | Cloud architecture | **Amber** | Well-Architected target; prod AWS not fully wired in repo |
| 9 | Tourism ↔ platform integration | **Green** | Ports, events, charter align with Pay/Mobility/Commerce |
| 10 | Implementation readiness | **Amber** | See `07_IMPLEMENTATION_READINESS_REPORT` |

---

## 1. Domain boundaries

### Findings

- **Green:** Tourism nine-domain model; orchestration does not own reservations or ledger ([`tourism/CANONICAL`](../tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md)).
- **Green:** Pay/ledger single spine; MAP/Tap explicitly interaction layers.
- **Amber:** Health, Education, Government, Insurance **logical** domains persist in **Commerce** APIs/tables ([`DIGITAL_ECOSYSTEM.md`](../DIGITAL_ECOSYSTEM.md)).
- **Red:** **Taifa Trade** has no domain pack—risk of duplicating Commerce unless ARB defines Trade scope.
- **Amber:** Circular **documentation** risk between Winga, Commerce housing, Tourism stays—all need Booking facade clarity.

### Risks

| Risk | Impact | Priority |
| --- | --- | --- |
| Commerce god-module | High coupling, slow extraction | P1 |
| Trade undefined | Duplicate B2B capabilities | P2 |

### Recommendations

| # | Action | Priority | Impact |
| --- | --- | --- | --- |
| R1 | ADR: Commerce vertical extraction order (Health, Edu, Gov, Tourism booking facade) | P1 | High maintainability |
| R2 | ADR or 00_INDEX for **Trade** (scope vs Commerce) | P2 | Prevents duplication |
| R3 | Maintain Tourism ADR-0001; no new non-02/05/06 tables in `tourism` | P0 | Boundary integrity |

---

## 2. Platform capability map

**Rating: Green** — See [01_PLATFORM_CAPABILITY_MAP.md](01_PLATFORM_CAPABILITY_MAP.md).

No redesign required; use as ARB checklist for new PRDs.

---

## 3. Enterprise context map

**Rating: Green** — See [02_ENTERPRISE_CONTEXT_MAP.md](02_ENTERPRISE_CONTEXT_MAP.md).

Tourism correctly positioned as **orchestrator** consuming Identity, Finance, Commerce, Mobility, AI.

---

## 4. Canonical data model

**Rating: Amber**

### Findings

- Enterprise concepts defined in [03_CANONICAL_DATA_MODEL.md](03_CANONICAL_DATA_MODEL.md).
- [`DATA_MODEL.md`](../DATA_MODEL.md) emphasizes payments; vertical entities scattered.

### Recommendations

| # | Action | Priority | Impact |
| --- | --- | --- | --- |
| R4 | Add cross-links from `DATA_MODEL.md` to canonical concepts | P1 | Single language |
| R5 | Map `commerce_*` tables to logical owners in commerce ops doc | P2 | Governance |

---

## 5. Event governance

**Rating: Amber**

### Findings

- **Green:** [`architecture/02_EVENT_CATALOG.md`](../architecture/02_EVENT_CATALOG.md) naming, envelope, DLQ defaults.
- **Green:** Tourism events harmonized with `tourism.*`, `booking.reservation.*`, `finance.*`.
- **Amber:** `enterprise.EventOutbox` exists; **EventBridge not mandatory** in all paths ([`DIGITAL_ECOSYSTEM`](../DIGITAL_ECOSYSTEM.md)).
- **Amber:** Mobility ticket events less formalized than tourism/finance.

### Recommendations

| # | Action | Priority | Impact |
| --- | --- | --- | --- |
| R6 | ADR-0002: `booking.*` vs `commerce.booking.*` prefix policy | P1 | Catalog consistency |
| R7 | Platform mandate: outbox → EventBridge for cross-domain publishes | P1 | Loose coupling |
| R8 | Register mobility ticket lifecycle events in catalog | P2 | Integration clarity |

---

## 6. API governance

**Rating: Green**

### Findings

- Constitution covers REST, idempotency, OpenAPI, correlation ([`architecture/03`](../architecture/03_API_STANDARDS.md)).
- CI validates OpenAPI ([`ROADMAP.md`](../ROADMAP.md)).
- **Amber:** Tourism `assist/*` vs `protection/*`; commerce vs `tourism/booking` facade migration.

### Recommendations

| # | Action | Priority | Impact |
| --- | --- | --- | --- |
| R9 | OpenAPI tag taxonomy (Orchestration / Protection / Connectivity) | P1 | Developer clarity |
| R10 | Publish deprecation timeline for path aliases | P2 | Client stability |

---

## 7. Security review

**Rating: Amber**

### Findings

- **Green:** Device-bound auth, owner scoping, ledger integrity, prod TLS ([`SECURITY.md`](../SECURITY.md)).
- **Green:** [`architecture/05_SECURITY_STANDARDS.md`](../architecture/05_SECURITY_STANDARDS.md) OAuth/OIDC/JWT/RBAC/ABAC/KMS.
- **Amber:** Full **OIDC** citizen identity doc thin vs device tokens.
- **Amber:** External **pen-test** not completed ([`ROADMAP.md`](../ROADMAP.md)).
- **Green:** AI **must not** mutate ledger ([`DIGITAL_ECOSYSTEM`](../DIGITAL_ECOSYSTEM.md)).

### Recommendations

| # | Action | Priority | Impact |
| --- | --- | --- | --- |
| R11 | Identity architecture pack (OIDC, step-up, NIDA) | P1 | National trust |
| R12 | Schedule pen-test before public funds scale | P1 | Risk reduction |
| R13 | Threat model per Tourism checkout saga (doc-only ok) | P2 | Security sign-off |

---

## 8. Cloud architecture

**Rating: Amber**

### Findings

- **Green:** Target services listed (API GW, EventBridge, ECS, RDS, Redis, CloudFront, GuardDuty, etc.) in constitution and Tourism AWS doc.
- **Amber:** Live deploy gated on customer AWS account; compose-first in repo.
- **Green:** Observability foundation (health, Prometheus, Sentry).

### Recommendations

| # | Action | Priority | Impact |
| --- | --- | --- | --- |
| R14 | Reference architecture diagram in `DEPLOYMENT.md` linked to platform 04 | P2 | Ops alignment |
| R15 | DR game day checklist (RDS restore, EventBridge replay) | P2 | Resilience |

---

## 9. Tourism integration (special focus)

**Rating: Green (architecture)**

| Integration | EARB assessment |
| --- | --- |
| Identity | Correct—device session at API edge |
| Taifa Pay | Correct—single capture; splits to Finance |
| Commerce / Booking | Correct—delegation + refs; facade path planned |
| Mobility | Correct—SafetyIncident SoR; SOS link |
| Protection / Connectivity | Correct logical split; physical ADR-0001 |
| Government | Correct—adapters; thin implementation |
| AI | Correct—proposals only; orchestration commits |
| Notifications / Analytics | Correct—async via events (target) |

**No Tourism domain boundary redesign required.**

---

## 10. Duplication & coupling summary

| Issue | Status |
| --- | --- |
| Payment split in Tourism vs Finance | **Resolved in docs** |
| AI assist vs Protection SOS | **Resolved in docs** |
| Multiple wallets | **None by design** |
| Commerce vertical sprawl | **Open—needs ADR** |
| Tourism direct commerce ORM | **Risk—code audit required** |

---

## Priority roadmap (architecture only)

| Priority | Items |
| --- | --- |
| **P0** | R3, platform DoD on all PRs, Tourism compliance report P0 |
| **P1** | R1, R6, R7, R9, R11, R12, R4 |
| **P2** | R2, R5, R8, R10, R13–R15 |

---

## Cross-references

- [07_IMPLEMENTATION_READINESS_REPORT.md](07_IMPLEMENTATION_READINESS_REPORT.md)  
- [08_PLATFORM_RISKS.md](08_PLATFORM_RISKS.md)  
- [`architecture/GOVERNANCE_COMPLIANCE_REPORT.md`](../architecture/GOVERNANCE_COMPLIANCE_REPORT.md)

---

## Future considerations

- Quarterly EARB re-certification  
- Automated architecture scorecard API extended with domain boundary checks
