# 2. Platform Baseline Certification

**Baseline ID:** `TAIFA-BASELINE-2026-07-19`  
**Status:** **APPROVED** as official enterprise baseline  
**Change control:** Architecture Board + Executive Steering — immutable except via formal governance  

---

## Certified baseline artifacts

| Area | Approved reference |
| --- | --- |
| Architecture | `docs/SYSTEM_ARCHITECTURE.md` · ADRs · domain apps (payments, enterprise, winga, mos, trips, …) |
| Engineering standards | `docs/governance/ENGINEERING_STANDARDS.md` · platform_governance/05 |
| Governance | `docs/platform_governance/` · `docs/GOVERNANCE.md` |
| Platform lifecycle | Stages 0–9 · Gates G0–G8 |
| Certification model | Certification Manual + Checklist Library |
| Operational framework | Ops readiness + winga_ops + commerce_ops |
| Quality standards | QUALITY_ENGINEERING · CI gates |
| Security standards | SECURITY.md · Security Governance Manual |
| Integration model | INTEGRATION_CATALOG · integrations certification API |
| Observability | OBSERVABILITY.md · Prometheus/Grafana |
| Documentation standards | governance/DOCUMENTATION.md |
| AI policy | AI never authorizes payments |
| Money truth | Single payments ledger (ADR-0001) |

---

## Baseline rules

1. Do not redesign architecture to start new work.  
2. Do not invent parallel governance.  
3. Domain platforms inherit this baseline.  
4. Exceptions require written ARB / Steering approval.  
5. Recertify after material security or money-path change.  

**Signature block (record in exec minutes):** CEO · CTO · COO · CISO · CPO
