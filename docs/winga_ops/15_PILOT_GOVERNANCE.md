# 15. Pilot Governance Framework

**Owner:** Pilot Director · **Accountable:** COO  
**Purpose:** Govern live pilots (e.g., Hotels Dar) without software redesign.

---

## Governance bodies

| Body | Cadence | Chair | Mandate |
| --- | --- | --- | --- |
| Daily Ops Standup | Daily | Marketplace Ops | Checklist · freezes · Sev triage |
| Weekly Marketplace Review | Weekly | Marketplace Ops | Scorecard · actions |
| Pilot Steering | Biweekly during pilot | Pilot Director | Exit criteria · scope freeze |
| Monthly EBR | Monthly | COO | Exec decisions |
| Certification Board | Ad hoc | COO + Pilot Director | Blueprint Certified / not |
| Change Control | Ad hoc | COO + CPO | Any payment/commission/API change request |

---

## Scope freeze (pilot)

**In scope:** Playbooks, training, support, settlement ops, low-risk UX copy, recruiting.  
**Out of scope:** New backend modules, payment redesign, commission engine redesign, API redesign.

Exceptions require Change Control written approval.

---

## Decision rights

| Decision | Authority |
| --- | --- |
| Hotel go-live | Provider Success + Marketplace Ops |
| Winga certify | Winga Success |
| PAY_FREEZE | Marketplace Ops + Finance |
| Pilot start Phase 4 (paid public) | Pilot Director + COO |
| Blueprint Certified | Certification Board |
| National expansion | COO + CPO after Certified |

---

## Evidence standards

- Metrics from KPI dictionary sources  
- Interviews: recorded n; quotes attributed; **n=0 allowed**  
- Financial claims: ledger-linked  
- No fabricated bookings, GMV, CSAT, commissions, interviews  

---

## Escalation path

Support → Success pods → Marketplace Ops → Pilot Director → COO → (money) Finance/Risk → (platform) Eng Support

---

## Document control

| Doc set | Path | Review |
| --- | --- | --- |
| Ops handbook set | `docs/winga_ops/` | Quarterly or post-Sev-1 |
| Field pilot pack | `docs/winga_pilot/field/` | Weekly during pilot |
| Lab validation | `docs/winga_pilot/` | As needed |

Version bumps require OpEx review for SOP impact.
