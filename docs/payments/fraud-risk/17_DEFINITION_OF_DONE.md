# 17 — Definition of Done

---

## Executive summary

Phase 7 feature and release DoD for FRP services and operations.

---

## Feature DoD

- [ ] OpenAPI updated and contract-tested with orchestration  
- [ ] Events registered in schema registry  
- [ ] RDS migrations reviewed  
- [ ] RBAC enforced on admin APIs  
- [ ] Unit + integration tests in CI  
- [ ] Runbook for on-call  
- [ ] Dashboards and alarms linked  
- [ ] Security review for new list/rule surfaces  
- [ ] No payment/settlement/recon logic in FRP codebase (boundary check)

---

## Sprint DoD

- [ ] Deployed to staging  
- [ ] Demo recorded for product  
- [ ] Backlog item closed with trace to FRB-*

---

## Release DoD (production)

- [ ] [16_ACCEPTANCE_CRITERIA.md](16_ACCEPTANCE_CRITERIA.md) passed  
- [ ] Pen test remediation or accepted risk  
- [ ] DR restore tested  
- [ ] Fraud ops trained on cases + rules  
- [ ] ADR-TNPI-FR-001 fail-closed policy signed  
- [ ] Phase 7 gate sign-off

---

## Cross-references

[18_RISK_REGISTER.md](18_RISK_REGISTER.md)
