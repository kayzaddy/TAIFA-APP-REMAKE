# 1. Winga Operations Handbook

**Version:** 1.0  
**Audience:** All Winga ops roles  
**Owner:** COO / Head of Marketplace Operations  

---

## 1. Operating model

Winga is run as a **brokerage marketplace operations organization**. Software executes deals; humans ensure trust, quality, and recovery.

```
Customers  ↔  Wingas  ↔  Providers
                 ↕
         Taifa Platform (ledger, workflow)
                 ↕
     Marketplace Ops · Success · Support · Settlement · Risk
```

### Principles

1. **No live provider/Winga without checklist completion.**  
2. **Money truth = ledger.** Ops never “fix” balances outside settlement SOPs.  
3. **AI never authorizes payment.**  
4. **Observe → Measure → Root cause → Improve → Validate → Standardize → Document.**  
5. **Never fabricate metrics or research.**  

---

## 2. Function responsibilities & RACI

| Responsibility | Marketplace Ops | Provider Success | Winga Success | Customer Success | Support | Settlement | Risk & Trust | Finance | QA / OpEx | Eng Support |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Daily marketplace checklist | **A/R** | C | C | C | C | C | I | I | C | I |
| Hotel onboarding | C | **A/R** | I | I | I | C | C | C | C | I |
| Winga certification | C | I | **A/R** | I | I | I | C | I | C | I |
| Customer retention | I | I | C | **A/R** | C | I | I | I | C | I |
| Tickets L1/L2 | C | C | C | C | **A/R** | C | C | I | C | C |
| Pay/settle reconciliation | C | I | I | I | I | **A/R** | C | **A** | C | C |
| Fraud / abuse | C | C | C | C | C | C | **A/R** | C | C | C |
| Ledger exceptions | C | I | I | I | I | R | C | **A** | C | C |
| Mystery shops / audits | C | C | C | C | C | C | C | I | **A/R** | I |
| Platform incidents (P1) | C | I | I | I | C | C | C | I | C | **A/R** |
| Weekly marketplace review | **A** | R | R | R | R | R | R | C | R | C |
| Monthly EBR | **A** (COO chair) | R | R | R | C | R | C | R | R | C |

**R** = Responsible · **A** = Accountable · **C** = Consulted · **I** = Informed

Every row has one **A**. Vacancies: name an interim owner within 24h.

---

## 3. Cadence

| Ritual | When | Owner | Output |
| --- | --- | --- | --- |
| Daily ops standup | Every morning | Marketplace Ops | Checklist done · blockers |
| Settlement reconciliation | Daily EOD | Settlement Ops | Zero unresolved discrepancies |
| Weekly marketplace review | Monday | Marketplace Ops | Weekly report |
| Weekly research sync | Friday | Field Ops / UX Research | Verified notes only |
| Monthly provider MBRs | Monthly | Provider Success | MBR notes |
| Monthly Winga coaching pulse | Monthly | Winga Success | At-risk list |
| Monthly EBR | Monthly | COO | EBR pack |
| Quarterly growth review | Quarterly | CPO + COO | Scaling decisions |
| Blueprint certification review | When exit bars hit | Pilot Director + COO | Certified / not |

---

## 4. Daily Marketplace Operations Checklist

**Owner:** Marketplace Operations · **Start of every business day**

- [ ] New provider applications / pending KYB  
- [ ] New Winga applications / pending KYC & certification  
- [ ] Pending verifications aging >48h  
- [ ] New leads (last 24h)  
- [ ] Quotes awaiting response (SLA breach?)  
- [ ] Accepted offers not yet paid  
- [ ] Payments captured (match ledger)  
- [ ] Settlements due / completed  
- [ ] Pending commissions  
- [ ] Failed workflows / stuck stages  
- [ ] Support tickets (Critical/High)  
- [ ] Platform alerts / uptime  
- [ ] Operational KPIs vs prior day  
- [ ] Freeze status (any money freeze active?)  

Template log: [`09_MARKETPLACE_OPS_DASHBOARD.md`](09_MARKETPLACE_OPS_DASHBOARD.md)

---

## 5. Continuous improvement loop

```
Observe → Measure → Root Cause → Improve → Validate → Standardize → Document
```

Allowed improvements without engineering redesign: playbooks, training, macros, checklists, SLA tweaks, copy/guidance in experience layer (low-risk UX only via product request).

Forbidden without exec change-control: new modules, payment redesign, commission engine redesign, API redesign.

---

## 6. Scaling framework (post-certification)

After an industry is **Certified**:

1. Clone this handbook + industry overlays.  
2. Adapt: workflow aliases, commission defaults, onboarding docs, training, KPIs, support macros.  
3. Reuse: settlement, incident, governance, RACI, improvement loop.  

Hotels is the first candidate; **not certified** as of Week 0 field status.

---

## 7. Success definition (operational maturity)

- Hotels (or any provider) onboarded consistently via playbook  
- Wingas trained & certified consistently  
- Customers complete bookings successfully  
- Providers continue participating  
- Settlements accurate (zero unresolved discrepancies)  
- Support scales with measurable SLAs  
- Marketplace health improves over time  
- Every process documented, repeatable, measurable, improved  

---

## 8. Related SOPs

See [`13_SOPS.md`](13_SOPS.md) for numbered procedures (SOP-WINGA-001…).
