# 18 — Risk Register

---

## Executive summary

Program risks for TNPI Phase 7 Fraud & Risk Platform with mitigations and owners.

---

| ID | Risk | Impact | Likelihood | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- |
| FR-R01 | Assess latency breaks orchestration SLA | High | Med | Redis, scale-out, circuit breaker | SRE |
| FR-R02 | False positives block legitimate commerce | High | Med | Review queue, merchant tiers, tuning | Fraud Ops |
| FR-R03 | False negatives / fraud loss | High | Med | Layered rules + ML shadow | Fraud Ops |
| FR-R04 | Insider list abuse | Critical | Low | Maker-checker, audit, SoD | Security |
| FR-R05 | PII leakage in events/logs | High | Med | Redaction, ABAC, scanning | Security |
| FR-R06 | ML unavailable blocks decisions | Med | Med | Rules-only fallback ADR | Engineering |
| FR-R07 | Regulatory AML gap | High | Med | TM alerts, compliance roadmap | Compliance |
| FR-R08 | Orchestration hook bypass | Critical | Low | Mandatory gateway policy | Architecture |
| FR-R09 | Recon signal misinterpreted | Med | Low | Aggregates only, human review | Finance |
| FR-R10 | Rule sprawl / conflicts | Med | High | Priority model, simulation | Fraud Ops |

---

## Architecture decision records (proposed)

- **ADR-TNPI-FR-001** — Production assess fail-closed when FRP unhealthy  
- **ADR-TNPI-FR-002** — ML is advisory; rules + score formula can decide alone  
- **ADR-TNPI-FR-003** — FRP does not mutate payment or settlement state

---

## Operational considerations

Monthly risk review; post-incident updates to this register.

---

## Future expansion

National fraud data sharing legal review (FR-R11 placeholder).

---

## Cross-references

[PHASE7_GATE_PACKAGE.md](PHASE7_GATE_PACKAGE.md) · [reconciliation/18_RISK_REGISTER.md](../reconciliation/18_RISK_REGISTER.md)
