# Taifa Enterprise Governance

Governance is platform infrastructure. New features follow these standards; they do not invent private engineering cultures.

**Do not redesign business domains.** Strengthen how we build, secure, operate, and evolve them.

## Constitutional lifecycle (authoritative)

**Taifa Enterprise Platform (EARB blueprint & gate)**  
→ [`platform/README.md`](platform/README.md)  
→ Implementation gate: [`platform/earb/07_IMPLEMENTATION_READINESS_REPORT.md`](platform/earb/07_IMPLEMENTATION_READINESS_REPORT.md)  
→ **Taifa Core execution:** [`platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md`](platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md) · [`platform/00_PLATFORM_OVERVIEW.md`](platform/00_PLATFORM_OVERVIEW.md)

**Taifa Architecture Constitution (technical law)**  
→ [`architecture/README.md`](architecture/README.md)  
→ [`architecture/00_ARCHITECTURE_CONSTITUTION.md`](architecture/00_ARCHITECTURE_CONSTITUTION.md)

**Taifa Platform Launch, Certification & Lifecycle Governance Framework**  
→ [`platform_governance/00_INDEX.md`](platform_governance/00_INDEX.md)  
→ Constitution: [`platform_governance/20_PLATFORM_CONSTITUTION.md`](platform_governance/20_PLATFORM_CONSTITUTION.md)

Every platform follows Stages 0–9 and Gates G0–G8. Domain ops handbooks (Winga, Commerce, …) inherit this system.

## Program closure (design → execution)

**Status:** Design & Governance Program **COMPLETE** (2026-07-19)  
**Baseline:** `TAIFA-BASELINE-2026-07-19`  
→ [`program_closure/00_INDEX.md`](program_closure/00_INDEX.md)  
→ Executive summary: [`program_closure/14_EXECUTIVE_SUMMARY.md`](program_closure/14_EXECUTIVE_SUMMARY.md)

Design is closed. Execution (pilots, validation, certification, controlled launch) is open. No ad hoc redesign.

## Index

| # | Area | Document |
| --- | --- | --- |
| 1 | Enterprise Architecture | [`architecture/README.md`](architecture/README.md) · [`governance/EA_GOVERNANCE.md`](governance/EA_GOVERNANCE.md) |
| 2 | API Governance | [`governance/API_GOVERNANCE.md`](governance/API_GOVERNANCE.md) |
| 3 | Engineering Standards | [`governance/ENGINEERING_STANDARDS.md`](governance/ENGINEERING_STANDARDS.md) |
| 4 | Platform Engineering | [`governance/PLATFORM_ENGINEERING.md`](governance/PLATFORM_ENGINEERING.md) |
| 5 | Security Governance | [`governance/SECURITY_GOVERNANCE.md`](governance/SECURITY_GOVERNANCE.md) |
| 6 | Data Governance | [`governance/DATA_GOVERNANCE.md`](governance/DATA_GOVERNANCE.md) |
| 7 | Privacy & Compliance | [`governance/PRIVACY_COMPLIANCE.md`](governance/PRIVACY_COMPLIANCE.md) |
| 8 | AI Governance | [`governance/AI_GOVERNANCE.md`](governance/AI_GOVERNANCE.md) |
| 9 | DevSecOps | [`governance/DEVSECOPS.md`](governance/DEVSECOPS.md) |
| 10 | Quality Engineering | [`governance/QUALITY_ENGINEERING.md`](governance/QUALITY_ENGINEERING.md) |
| 11 | Observability | [`governance/OBSERVABILITY_GOVERNANCE.md`](governance/OBSERVABILITY_GOVERNANCE.md) |
| 12 | Lifecycle | [`governance/LIFECYCLE.md`](governance/LIFECYCLE.md) |
| 13 | Documentation | [`governance/DOCUMENTATION.md`](governance/DOCUMENTATION.md) |
| 14 | Operations | [`governance/OPERATIONAL_GOVERNANCE.md`](governance/OPERATIONAL_GOVERNANCE.md) |
| 15 | Product Ownership | [`governance/OWNERSHIP.md`](governance/OWNERSHIP.md) |
| 16 | Scorecard | [`governance/SCORECARD.md`](governance/SCORECARD.md) |
| 17 | Engineering Culture | [`governance/ENGINEERING_CULTURE.md`](governance/ENGINEERING_CULTURE.md) |
| — | ADRs | [`adr/README.md`](adr/README.md) |
| — | Technical Debt | [`governance/TECHNICAL_DEBT.md`](governance/TECHNICAL_DEBT.md) |

## Live scorecard API

`GET /api/v1/governance/scorecard` — machine-readable compliance snapshot for executives and ARB.

## Related platform docs (authoritative implementations)

- [`SECURITY.md`](SECURITY.md) · [`OBSERVABILITY.md`](OBSERVABILITY.md) · [`DEPLOYMENT.md`](DEPLOYMENT.md)
- [`INCIDENT_RESPONSE.md`](INCIDENT_RESPONSE.md) · [`DISASTER_RECOVERY.md`](DISASTER_RECOVERY.md) · [`ONCALL.md`](ONCALL.md)
- [`AI_OS_RESPONSIBLE.md`](AI_OS_RESPONSIBLE.md) · [`CONTINENTAL_COMPLIANCE.md`](CONTINENTAL_COMPLIANCE.md)
- [`OPEN_PLATFORM.md`](OPEN_PLATFORM.md) · [`PRODUCTION_GATE.md`](PRODUCTION_GATE.md)

## Boards

| Board | Mandate |
| --- | --- |
| **Architecture Review Board (ARB)** | Major designs, new services, anti-duplication, ADRs |
| **API Review Board** | Public API contracts, versioning, deprecation |
| **Security Review** | Threat model, Secure SDLC gates, production clearance |
| **Change Advisory** | High-risk production changes (payments, identity, ledger) |
