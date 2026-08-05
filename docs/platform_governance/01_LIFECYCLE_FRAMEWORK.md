# 1. Taifa Platform Lifecycle Framework

**Owner:** Principal Enterprise Architect · CTO  
**Applies to:** Payments, Identity, Wallet, Mobility, Winga, Commerce, Government, Health, Education, Agriculture, Tourism, Housing, Employment, AI, and all future platforms  

---

## Stages

| Stage | Name | Intent |
| --- | --- | --- |
| 0 | Vision | Problem, personas, outcomes, non-goals |
| 1 | Architecture | Boundaries, reuse map, threat model, ERD, APIs |
| 2 | Engineering Foundation | Implement against architecture; CI green |
| 3 | Experience Layer | Journeys; no money/API redesign |
| 4 | Operational Readiness | SOPs, runbooks, monitoring, incidents |
| 5 | Pilot Readiness | Cohort, metrics, governance ready |
| 6 | Business Validation | Real users, real money, real KPIs |
| 7 | Certification | Evidence-based multi-domain cert |
| 8 | Production Launch | Exec approval, rollback, DR |
| 9 | Continuous Improvement | Observe→Improve forever |

---

## Stage gates (no skip)

| Gate | Name | Approvers (minimum) |
| --- | --- | --- |
| G0 | Vision Approved | CPO + CTO |
| G1 | Architecture Approved | Architecture Board + CISO (threat) |
| G2 | Engineering Complete | Eng Board + QA Architect |
| G3 | Experience Approved | CXO / Product Design + CPO |
| G4 | Operations Approved | COO + SRE + OpEx |
| G5 | Pilot Approved | COO + CPO + Risk |
| G6 | Business Validated | CPO + COO + Finance (if money) |
| G7 | Platform Certified | Certification Board (CTO, CISO, CRO, COO, CPO) |
| G8 | National Rollout Approved | Executive Steering Committee |

---

## Entry / exit criteria (summary)

### Stage 0 → G0
**Exit:** Vision one-pager; success metrics; in/out of scope; reuse list (Identity, Payments, Ledger, …).

### Stage 1 → G1
**Exit:** Architecture Review complete; threat model approved; ERD approved; API standards verified; domain ownership named; no duplicate ledger/identity.

### Stage 2 → G2
**Exit:** CI passing; unit + integration + security + performance tests at thresholds; OpenAPI validated; secrets scan clean; coverage gate met.

### Stage 3 → G3
**Exit:** UX review; accessibility; performance UX; design-system compliance; journeys (not isolated screens).

### Stage 4 → G4
**Exit:** Ops handbook/SOPs/runbooks; monitoring & alerts; incident procedures; support model.

### Stage 5 → G5
**Exit:** Pilot plan; recruitment; success metrics; weekly review cadence; freeze rules.

### Stage 6 → G6
**Exit:** Real users & transactions; GMV/retention/CSAT (or domain KPIs) with evidence; operational KPIs; no Critical unresolved money defects (if financial).

### Stage 7 → G7
**Exit:** Checklists in Certification Manual all evidenced; independent audit trail; risk & security sign-off.

### Stage 8 → G8
**Exit:** Production readiness checklist; exec approval; rollback + DR validated; support staffed.

### Stage 9
**Ongoing:** CIP loop; scorecard updates; quarterly architecture review.

---

## Platform overlays

Domain ops handbooks (Winga, Commerce, …) **inherit** this lifecycle. They add industry SOPs; they do not replace gates.
