# 2. Platform Governance Handbook

**Owner:** Head of Platform Excellence · CTO  

---

## Unified governance (one system)

| Domain | Governing artifact |
| --- | --- |
| Lifecycle & gates | Lifecycle Framework |
| Architecture | Architecture Review Guide + Board |
| Engineering | Engineering Quality Standards |
| Security | Security Governance Manual |
| Data | Data Governance Framework |
| AI | AI Governance Policy |
| Operations | Operations Readiness Guide + domain ops handbooks |
| Pilot | Pilot Execution Handbook |
| Certification | Certification Manual + Checklists |
| Risk | Risk Management Framework |
| Improvement | Continuous Improvement Playbook |

Do **not** create a second certification or gate system per product.

---

## Decision rights (summary)

| Decision | Body |
| --- | --- |
| Architecture patterns / reuse | Architecture Board |
| Merge quality / CI gates | Engineering Board |
| Security exceptions | CISO + Risk |
| AI money-path exceptions | **Never granted** — AI cannot authorize payment |
| Pilot start | COO + CPO + Risk |
| Platform Certified | Certification Board |
| National rollout | Executive Steering |
| Emergency freeze (pay/settle/platform) | COO + Finance/CISO as applicable |

---

## Change control

Changes that redesign payments, ledger, inventory engines, or identity require Architecture Board + affected domain owners — even mid-pilot.

Experience/ops playbook updates: OpEx + product owner; no gate skip.

---

## Evidence

Every gate approval requires dated artifacts: reviews, test reports, recon logs, interview n, risk register IDs.  
**No fabrication. n=0 is valid.**
