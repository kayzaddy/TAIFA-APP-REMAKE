# Taifa Enterprise Governance

Governance is platform infrastructure. New features follow these standards; they do not invent private engineering cultures.

**Do not redesign business domains.** Strengthen how we build, secure, operate, and evolve them.

## Constitutional lifecycle (authoritative)

**Taifa Enterprise Platform (EARB blueprint & gate)**  
→ [`platform/README.md`](platform/README.md)  
→ Implementation gate: [`platform/earb/07_IMPLEMENTATION_READINESS_REPORT.md`](platform/earb/07_IMPLEMENTATION_READINESS_REPORT.md)  
→ **Taifa Core execution:** [`platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md`](platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md) · [`platform/00_PLATFORM_OVERVIEW.md`](platform/00_PLATFORM_OVERVIEW.md)

**Taifa National Payment Infrastructure (TNPI)**  
→ [`payments/README.md`](payments/README.md)  
→ Program charter: [`payments/00_PAYMENT_PROGRAM.md`](payments/00_PAYMENT_PROGRAM.md)  
→ Phase 1 Merchant: [`payments/merchant/00_INDEX.md`](payments/merchant/00_INDEX.md)  
→ Phase 2 Payment Sources: [`payments/payment-sources/00_INDEX.md`](payments/payment-sources/00_INDEX.md)  
→ Phase 3 Orchestration: [`payments/orchestration/00_INDEX.md`](payments/orchestration/00_INDEX.md)  
→ Phase 4 Merchant Acceptance: [`payments/merchant-acceptance/00_INDEX.md`](payments/merchant-acceptance/00_INDEX.md)  
→ Phase 5 Settlement: [`payments/settlement/00_INDEX.md`](payments/settlement/00_INDEX.md)  
→ Phase 6 Reconciliation: [`payments/reconciliation/00_INDEX.md`](payments/reconciliation/00_INDEX.md)  
→ Phase 7 Fraud & Risk: [`payments/fraud-risk/00_INDEX.md`](payments/fraud-risk/00_INDEX.md)  
→ Phase 8 Developer Platform: [`payments/developer-platform/00_INDEX.md`](payments/developer-platform/00_INDEX.md)  
→ Transport Payments Platform: [`transport/00_PLATFORM_OVERVIEW.md`](transport/00_PLATFORM_OVERVIEW.md)  
→ National Mobility Platform (TNMP): [`mobility/00_PLATFORM_OVERVIEW.md`](mobility/00_PLATFORM_OVERVIEW.md)  
→ Government Digital Services (GDSP): [`government/00_PLATFORM_OVERVIEW.md`](government/00_PLATFORM_OVERVIEW.md)  
→ Taifa Integration Platform (TIP): [`integration/00_PLATFORM_OVERVIEW.md`](integration/00_PLATFORM_OVERVIEW.md)  
→ **Taifa Merchant** (flagship business app): [`taifa-merchant/00_INDEX.md`](taifa-merchant/00_INDEX.md)  
→ Implementation: [`payments/12_IMPLEMENTATION_PLAN.md`](payments/12_IMPLEMENTATION_PLAN.md)

**Taifa Architecture Constitution (technical law)**  
→ [`architecture/README.md`](architecture/README.md)  
→ [`architecture/00_ARCHITECTURE_CONSTITUTION.md`](architecture/00_ARCHITECTURE_CONSTITUTION.md)

**Master execution plan (portfolio & delivery)**  
→ [`TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md`](TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md) · [`portfolio/00_INDEX.md`](portfolio/00_INDEX.md)

**Product Engineering (mandatory operating framework)**  
→ [`tpos/00_TPOS_CHARTER.md`](tpos/00_TPOS_CHARTER.md) — **TPOS** (architecture phase complete; all products follow TPOS from idea → production)

**Engineering Operating System (mandatory delivery framework)**  
→ [`teos/00_TEOS_CHARTER.md`](teos/00_TEOS_CHARTER.md) — **TEOS** (how all teams design, build, test, secure, release, and operate software; complements TPOS)

**Enterprise monorepository (`taifa-platform`)**  
→ [`../taifa-platform/README.md`](../taifa-platform/README.md)  
→ Gate G0: [`../taifa-platform/MONOREPO_GATE_PACKAGE.md`](../taifa-platform/MONOREPO_GATE_PACKAGE.md)  
→ Tree & standards: [`../taifa-platform/docs/engineering/REPOSITORY_TREE.md`](../taifa-platform/docs/engineering/REPOSITORY_TREE.md)

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

**Product Engineering phase:** All products follow **[TPOS](tpos/00_TPOS_CHARTER.md)** (Taifa Product Operating System).

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
| — | **TNPI (Payments)** | [`payments/README.md`](payments/README.md) |
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
