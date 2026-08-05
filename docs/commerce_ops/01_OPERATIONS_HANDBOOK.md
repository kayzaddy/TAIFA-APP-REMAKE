# 1. Commerce Operations Handbook

**Version:** 1.0  
**Audience:** All Commerce ops roles  
**Owner:** COO / Head of Operations  

---

## 1. Operating model

Taifa Commerce is run as a **Merchant Operating System operations organization**. Software executes catalog, inventory, orders, and POS; humans ensure trust, accuracy, and recovery.

```
Customers  ↔  Stores / POS  ↔  Warehouses  ↔  Suppliers
                      ↕
              Taifa Commerce (MOS)
                      ↕
    Payments · Ledger · Winga · Mobility · Identity · Analytics · AI
                      ↕
  Merchant Success · Store · Warehouse · Procurement · Finance · Support · Risk · OpEx
```

### Principles

1. **No live merchant without onboarding checklist completion.**  
2. **Money truth = payments ledger** via enterprise capture/settlement.  
3. **AI never authorizes payment.**  
4. **Observe → Measure → Root cause → Improve → Validate → Document → Standardize.**  
5. **Never fabricate metrics or research.**  

---

## 2. RACI matrix

| Responsibility | Merchant Success | Customer Success | Warehouse | Procurement | Store Ops | Finance | Settlement | Inventory Control | Support | Risk | OpEx / QA | Eng Support |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Merchant onboarding | **A/R** | I | C | C | C | C | C | C | I | C | C | I |
| Daily store open/close | C | I | I | I | **A/R** | C | I | C | I | I | C | I |
| POS shift integrity | C | I | I | I | **A/R** | C | I | I | C | C | C | C |
| Receiving / put-away | C | I | **A/R** | C | I | I | I | C | I | I | C | I |
| Pick / pack / dispatch | C | C | **A/R** | I | C | I | I | C | C | I | C | I |
| Purchase orders | C | I | C | **A/R** | I | C | I | C | I | I | C | I |
| Order lifecycle SLAs | C | C | C | I | **A** | I | I | C | C | I | R | I |
| Customer tickets | C | **A/R** | C | I | C | C | C | I | **R** | C | C | C |
| Daily ledger recon | I | I | I | I | C | **A** | **R** | I | I | C | C | C |
| Settlement execute | I | I | I | I | I | **A** | **R** | I | I | C | C | C |
| Inventory accuracy | C | I | R | C | C | I | I | **A/R** | I | I | C | I |
| Winga campaigns | **A** | I | I | I | C | C | C | I | I | C | C | I |
| Mobility delivery | C | C | **A** | I | C | I | I | I | C | I | C | C |
| Fraud / abuse | C | C | C | C | C | C | C | C | C | **A/R** | C | C |
| Sev-1 platform | C | C | C | I | C | C | C | I | C | C | C | **A/R** |
| Weekly ops review | C | C | R | R | **A** | R | R | R | R | C | R | C |
| Monthly EBR | **A** (COO chair) | R | R | R | R | R | R | R | C | C | R | C |
| Merchant certification | **A** | C | C | C | R | R | R | R | C | C | **R** | I |

**R** = Responsible · **A** = Accountable · **C** = Consulted · **I** = Informed  

Every row has one **A**. Name an interim owner within 24h if vacant.

---

## 3. Cadence

| Ritual | When | Owner | Output |
| --- | --- | --- | --- |
| Daily ops standup | Morning | Store Ops / Marketplace Ops | Checklist · freezes · Sev triage |
| Settlement reconciliation | EOD | Settlement | Zero unresolved discrepancies |
| Inventory health pulse | Daily | Inventory Control | Low stock / shrinkage flags |
| Weekly store review | Monday | Store Ops | Weekly dashboard |
| Weekly warehouse review | Tuesday | Warehouse | Accuracy · backlog |
| Merchant Success coaching | Continuous | Merchant Success | At-risk list |
| Monthly MBR | Monthly | Merchant Success | Per-merchant scorecard |
| Monthly EBR | Monthly | COO | Exec pack |
| Quarterly growth | Quarterly | CCO + COO | Scaling decisions |
| Certification board | Ad hoc | COO + Merchant Success | Certified / not |

---

## 4. Continuous improvement

```
Observe → Measure → Root Cause → Improve → Validate → Document → Standardize
```

Allowed without engineering redesign: playbooks, training, macros, SLAs, checklists, low-risk UX copy requests.  

Forbidden without Change Control: new modules, payment redesign, inventory engine redesign, API redesign, merchant identity redesign.

---

## 5. Operational maturity definition

- Merchants run daily ops consistently via playbooks  
- Inventory accuracy meets targets  
- Orders fulfill within SLA  
- Payments settle correctly; daily recon clean  
- Customers receive reliable service  
- Staff follow documented procedures  
- Onboarding is repeatable  
- Metrics improve over time  

---

## 6. Document map

SOPs live inside each playbook. KPI definitions: [`14_KPI_DICTIONARY.md`](14_KPI_DICTIONARY.md). Incidents: [`13_INCIDENT_RESPONSE.md`](13_INCIDENT_RESPONSE.md).
