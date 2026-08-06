# Taifa Merchant — Sprint 1 Product Acceptance Review (PAR)

| Field | Value |
| --- | --- |
| **Product** | Taifa Merchant |
| **Sprint** | TM-S1 — Merchant Foundation |
| **Review type** | Product Acceptance Review (PAR) — post Engineering Gate |
| **Date** | 2026-08-06 |
| **Panel** | CPO, VP Product, PM, UX Research, CX, Business Analysis, Merchant Ops, Merchant Success |
| **Authority** | [00_PRODUCT_REQUIREMENTS_DOCUMENT.md](../00_PRODUCT_REQUIREMENTS_DOCUMENT.md) (PRD v1.0) |
| **Sprint scope** | [SPRINT1_IMPLEMENTATION.md](../SPRINT1_IMPLEMENTATION.md) · Sprint goal (foundation; **no payments**) |
| **Engineering gate** | [SPRINT_1_ENGINEERING_GATE_REVIEW.md](../../../reviews/merchant/SPRINT_1_ENGINEERING_GATE_REVIEW.md) — PASS WITH CONDITIONS |
| **Backlog release** | **R-Alpha** (internal / foundation), **not** PRD **R-MVP** pilot |

---

## Executive summary

Sprint 1 is a **foundation increment**, not the PRD **MVP**. It advances **Access** and **Operate** mission pillars (account, business registration, branches, staff, devices, operational dashboard shell) and correctly **defers Accept** (QR, money, receipts) to later sprints. That sequencing matches the approved backlog (R-Alpha before R-MVP) and avoids shipping “half a payment product.”

From a **product outcome** lens, Sprint 1 **delivers meaningful internal and partner-demo value**: stakeholders can walk the “become a Taifa merchant” setup path and see how the OS will organize people, places, and devices before go-live payments. It does **not** yet deliver the PRD MVP outcome (*KYB-approved merchant accepts QR, sees sales, refunds, receipts, payment alerts*) or measurable business KPIs (TPV, activation, NPS).

**PAR decision: PASS WITH CONDITIONS** — accept Sprint 1 as **complete for its committed sprint goal** and as **progress toward MVP**, with explicit conditions before **merchant pilot**, **field sales**, or **MVP PAR**.

**Product readiness score (Sprint 1 goal):** **4.0 / 5**  
**Product readiness score (PRD MVP / Dar pilot):** **2.2 / 5**  
**Market readiness:** **Not ready**

---

## 1. Product vision alignment

### Vision & mission (PRD §2–3)

| Element | Alignment | Commentary |
| --- | --- | --- |
| **Vision** — “Digital OS for Businesses” | **Partial** | OS **structure** (business, branches, team, devices) is visible; **“paid”** and **“intelligent”** not yet in product hands. |
| **Mission pillar: Access** | **Partial** | Account + business registration exist; **national KYB trust** (TNPI-led status, documents, agent journey) not yet credible to merchants. |
| **Mission pillar: Accept** | **Deferred** | Correctly out of Sprint 1 scope. |
| **Mission pillar: Operate** | **Strong** | Branches, employees (invite), devices (register/activate), roles in API — core ops narrative started. |
| **Mission pillar: Understand** | **Weak** | Dashboard exists but **without sales/transactions** — PRD F-02 “today sales” not meaningful yet; placeholders communicate roadmap honestly. |
| **Mission pillar: Trust** | **Partial** | Verification status field shown; end-to-end trust UX (TNPI + Identity) not product-complete. |

### Business goals (PRD §8)

| ID | Goal | Sprint 1 contribution |
| --- | --- | --- |
| BO-1 | Zero TNPI boundary violations | **Supported** (no pay features) — business enabler for later TPV. |
| BO-2 | 10k active merchants | **No** — no acquisition channel or live pay reason to join. |
| BO-3 | Onboarding → first payment &lt; 48h | **Cannot measure** — no payment path. |
| BO-4 | NPS ≥ 40 | **Cannot measure** — not pilot-ready UX. |
| BO-5 | Reference TPOS product | **Yes** — first vertical app pattern for setup + platform consumption story. |
| BO-6 | 500 live merchants (portfolio) | **No** — depends on MVP+R-MVP. |

### Merchant value proposition

| Promised value | Sprint 1 delivers? |
| --- | --- |
| “Get paid digitally” | **No** (by design) |
| “Run your business in one place” | **Early signal** — setup modules present |
| “Control staff and devices” | **Yes** (basic; invite not full Identity journey) |
| “See how your business is doing” | **No** (counts only; no money metrics) |
| “Official / compliant” | **Partial** — status labels without real KYB workflow |

**Business review summary:** Sprint 1 is **on-strategy as R-Alpha** but must **not** be marketed or sold as Taifa Merchant MVP.

---

## 2. User persona validation

PRD primary personas: **Amina (owner)**, **Joseph (manager)**, **Neema (cashier)**. PAR also reviews requested roles **Administrator**, **Finance Officer** (finance often maps to **owner** or future **auditor** in PRD RBAC).

| Persona / role | Sprint 1 support | PRD stories | Gap |
| --- | --- | --- | --- |
| **Business owner (Amina)** | **Strong** | TM-US-01, 02 (partial), 20, 21 | No QR/sales (US-30, 40); KYB wizard/checklist incomplete (US-03–05) |
| **Store manager (Joseph)** | **Moderate** | TM-US-10–12 (partial), 21 | Cannot refund or see shift totals; invite works in API not full login for staff |
| **Cashier (Neema)** | **Weak** | TM-US-12 (partial) | No QR flow; cashier cannot “do job” yet |
| **Administrator** | **Moderate** | Role exists in backend | No differentiated admin UX; same app as owner |
| **Finance officer** | **Not addressed** | — | No settlement view, exports, or reports (PRD P2+); acceptable for Sprint 1 if not in sprint commitment |
| **Field agent (David)** | **Weak** | Resume/status | No agent tooling or TNPI status transparency |
| **Auditor (PRD RBAC)** | **Latent** | — | Role defined; no auditor-specific screens |

**Persona verdict:** **Owner-led setup** is the only persona fully served for Sprint 1 intent; **cashier and manager value** await payment + staff Identity onboarding sprints.

---

## 3. User journey validation

| Journey | Steps PRD expects | Sprint 1 product experience | Status |
| --- | --- | --- | --- |
| **Merchant registration (account)** | National Identity signup | Email/password signup in app | **Partial** — not “national identity” narrative |
| **Merchant login** | Identity SSO, MFA-ready | Login + session | **Partial** — MFA/forgot password not in UI |
| **Business registration** | KYB wizard, TNPI status | Single form; `pending_verification` | **Partial** |
| **Branch creation** | Branch + hours/address | Create/list branch | **Pass** (basic) |
| **Employee invitation** | Identity invite, scoped access | Invite record created | **Partial** — invitee cannot complete accept/login journey |
| **Device registration** | TNPI device before accept | Register + activate | **Pass** (registration only) |
| **Dashboard access** | Today sales + ops summary | Profile, counts, placeholders | **Partial** |
| **Go-live → first payment** | Checklist → QR | Not possible | **Fail** (deferred — correct for sprint scope) |

```mermaid
flowchart LR
  subgraph S1 [Sprint 1 delivered]
    A[Account] --> B[Business]
    B --> C[Branch]
    C --> D[Team]
    D --> E[Device]
    E --> F[Dashboard shell]
  end
  subgraph MVP [PRD MVP - not S1]
    F -.-> G[QR Pay]
    G --> H[Money UX]
  end
```

---

## 4. Feature validation

Mapped to PRD §20 features and Sprint 1 epics.

| Feature | PRD MVP? | Sprint 1 | Product assessment |
| --- | --- | --- | --- |
| **Authentication** | Yes | Sign up, login, logout, session; forgot API; MFA stub | **Partial** — missing PRD Identity story & UX completeness |
| **Merchant / business profile** | Yes | Register + PATCH profile fields | **Partial** — no logo, limited KYB |
| **Branches** | Yes | CRUD/deactivate | **Pass** (MVP scope: 1 branch not enforced in UX) |
| **Employees** | Yes | Invite, role change, deactivate | **Partial** |
| **Devices** | Yes | Register, activate, deactivate | **Pass** (no payment use) |
| **Dashboard** | Yes | Ops dashboard, not sales dashboard | **Partial** |
| **Notifications** | Yes (payment, KYB) | Empty list on dashboard | **Fail** for MVP; **N/A** for S1 if not committed |
| **QR / SoftPOS / Links** | Mixed | Placeholders only | **Deferred** ✓ |
| **Transactions / refunds / receipts** | Yes | Not built | **Deferred** ✓ |
| **Go-live checklist** | Yes (US-05) | Not in product UI | **Missing** |

---

## 5. MVP validation

**Important:** PAR for **Sprint 1** must not be confused with **MVP PAR**. Below is PRD MVP (§21) status after Sprint 1.

### Completed toward MVP (foundation)

- Identity login **pattern** (dev)  
- Business registration **entry**  
- Branch, employee, device **management** (core)  
- Role model (owner, administrator, manager, cashier, auditor, support)  
- Dashboard **entry point** and honest **coming soon** for payments  

### Missing MVP features (expected post–Sprint 1)

| MVP item | Target sprint (backlog) |
| --- | --- |
| TNPI KYB wizard + real-time status (TM-US-02, 03) | TM-S2–S3 |
| Go-live checklist (TM-US-05) | TM-S3 / S9 |
| Dynamic QR (TM-US-30, 31) | TM-S5 |
| Transaction list 7d (TM-US-41) | TM-S4 |
| Refunds, receipts (TM-US-42, 43) | TM-S8 |
| Dashboard today sales (TM-US-40) | TM-S4 |
| Payment notifications (TM-US-50) | TM-S6 |
| en/sw | Cross-cutting |
| Identity staff invite E2E (AC-TM-7) | TM-S9 |

### Correctly deferred (non-MVP or later)

SoftPOS, payment links, advanced analytics, AI, CRM, multi-branch rollup.

### MVP acceptance criterion (PRD §39)

| AC | Met after S1? |
| --- | --- |
| AC-TM-1 – 7 | **No** |
| AC-N1 – N4 | **Partial** (product cannot validate full AC set) |

**MVP validation verdict:** Sprint 1 contributes **~35–40%** of MVP **capability areas** (setup/operate), **~0%** of MVP **revenue-critical** journeys (pay, money, notify).

---

## 6. UX validation

| Dimension | Assessment | Notes |
| --- | --- | --- |
| **Navigation** | Adequate for alpha | Linear paths; no merchant shell/tabs per PRD IA |
| **Usability** | Basic | Forms functional; branch create UX rough |
| **Accessibility** | **Below PRD** | No WCAG evidence; no semantics audit |
| **Simplicity** | Good for internal demo | Few steps to register business |
| **Learnability** | Moderate | Placeholders help; no onboarding coach marks |
| **First-time user (FTUE)** | **Weak for real merchants** | English only; no Swahili; no trust copy for KYB |
| **Design consistency** | **Below PRD** | Not TDS-aligned; generic Material |
| **CX principles (PRD §14)** | **Partial** | Clarity OK; “trust through TNPI status” not felt |

**UX verdict:** Acceptable for **internal PAR of Sprint 1**; **not acceptable** for Dar pilot merchants without design + i18n + KYB UX sprint.

---

## 7. Business value

| Dimension | Rating (1–5) | Rationale |
| --- | ---: | --- |
| **Merchant adoption potential** | 2 | No compelling “why switch” without pay + lipa namba |
| **Business impact (TPV/revenue)** | 1 | No payments |
| **Operational efficiency** | 3 | Ops teams can demo org setup; field ops runbook immature |
| **Customer (merchant) satisfaction** | N/A | No pilot users |
| **Market readiness** | 2 | Foundation only; compliance narrative incomplete |
| **Investor / stakeholder demo value** | 4 | Strong “OS for business” story before rails light up |
| **Platform ecosystem** | 4 | Proves TPOS path for TNPI/Identity consumption |

---

## 8. Product risks

| ID | Risk | Type | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- | --- | --- |
| PR-01 | Sprint 1 **sold or piloted as MVP** | Business | Medium | Critical | PAR messaging; release naming R-Alpha |
| PR-02 | Merchants **abandon** before payment launch | Adoption | High | High | Shorten S2–S5; go-live checklist |
| PR-03 | **KYB distrust** (fake pending state) | Compliance/UX | Medium | High | TNPI-backed status in UI |
| PR-04 | **Staff invite** without Identity harms manager persona | Ops | High | Medium | Sprint 2 Identity + AC-TM-7 |
| PR-05 | **No Swahili** blocks mass market | Adoption | High | High | MVP gate requirement |
| PR-06 | Cashier persona **ignored** until QR | UX | Medium | Medium | Prioritize QR in backlog order |
| PR-07 | Finance/audit needs **unmet** at pilot | Business | Low | Medium | Auditor role + reports in V1.1+ |
| PR-08 | Competitor “M-Pesa till only” wins micro-merchants | Market | Medium | Medium | Accelerate QR + value story |

---

## 9. Recommendations

### Recommendation to leadership: **Proceed with conditions**

| Option | PAR recommendation |
| --- | --- |
| **Proceed** (unconditional) | **No** — MVP and pilot criteria not met |
| **Proceed with conditions** | **Yes** — accept Sprint 1; govern pilot separately |
| **Rework** | **No** — sprint goal achieved; rework would duplicate S2–S3 |

### Conditions (product — before pilot / MVP PAR)

| ID | Condition | Owner |
| --- | --- | --- |
| **PC-1** | Publish **release label**: “Taifa Merchant Alpha (Foundation)” — not MVP | PM |
| **PC-2** | Commit **Sprint 2–5 plan** to close MVP money path (QR, tx, dashboard sales, notify) | PMO |
| **PC-3** | **Design + UX** sign-off on KYB, login, dashboard before external users | UX |
| **PC-4** | **en/sw** on all merchant-facing strings before Dar pilot | PM |
| **PC-5** | **Go-live checklist** (TM-US-05) in product before field agents use app | PM |
| **PC-6** | **Merchant Success** playbook: what agents say when pay is “coming soon” | Ops |
| **PC-7** | Do not run **paid acquisition** or **NPS** until **MVP PAR** passes | CPO |

### What product should celebrate

- First end-to-end **“business OS setup”** demo on Taifa stack.  
- Clear **placeholder** communication for payments (reduces false expectations if labeled Alpha).  
- Role model matches **Joseph / Neema** future state.

---

## Product readiness score

| Lens | Score | Meaning |
| --- | ---: | --- |
| **Sprint 1 committed goal** | **4.0 / 5** | Foundation journeys largely present |
| **PRD MVP completeness** | **2.2 / 5** | Pay and money UX missing |
| **Dar es Salaam pilot readiness** | **1.8 / 5** | Language, KYB, pay, support |
| **Vision long-term alignment** | **4.2 / 5** | Right build order |

---

## Sprint acceptance (product)

| Epic (Sprint 1) | Product acceptance |
| --- | --- |
| E1 Authentication | **Accepted with conditions** (Identity narrative) |
| E2 Merchant registration | **Accepted with conditions** (KYB depth) |
| E3 Branch management | **Accepted** |
| E4 Employee management | **Accepted with conditions** (invite E2E) |
| E5 Device management | **Accepted** |
| E6 Dashboard | **Accepted with conditions** (sales metrics deferred) |

---

## Definition of Done (product lens)

| Criterion | Met? |
| --- | --- |
| Sprint goal demoable to PRB | **Yes** |
| PRD MVP achieved | **No** |
| TPOS Beta gate | **No** |
| Merchant can complete sprint goal list (engineering mission) | **Mostly yes** (verify identity = weak) |
| Analytics events (PRD §31) | **No** |
| Pilot geography/language | **No** |

---

## Go / No-Go decision (PAR)

### **PASS WITH CONDITIONS**

### Justification

**Pass** because Sprint 1 delivers the **intended product increment** for **R-Alpha**: merchants (in staging) can **create an account**, **register a business**, **organize branches, staff, and devices**, and **land on a dashboard** that sets expectations for payments — matching the sprint mission and backlog release **before** R-MVP.

**Conditions** because the **PRD MVP** and **merchant-facing value proposition** (“get paid, see sales”) are **not** satisfied; personas **Neema** and partially **Joseph** cannot achieve success outcomes; **notifications**, **KYB trust**, **go-live checklist**, and **bilingual** experience are product gaps for any external pilot.

**Fail** would apply if Sprint 1 had claimed MVP completion, shipped payment features incorrectly, or failed the foundation sprint goal — none are true.

### Not approved for

- PRD **MVP sign-off**  
- Dar es Salaam **merchant pilot** (paid or organic)  
- Marketing as “Taifa Merchant is live”  
- Portfolio KPIs BO-2, BO-3, BO-4, BO-6  

### Approved for

- **Sprint 1 product closure** and velocity credit  
- Internal / partner **Alpha demos** (labeled Foundation)  
- Continuation to **Sprint 2+** on critical path to MVP  
- PRB acknowledgment that **~40% of setup MVP** and **~0% of pay MVP** are done  

---

## Sign-off (record)

| Role | Name | Decision | Date |
| --- | --- | --- | --- |
| CPO | | PASS WITH CONDITIONS | |
| VP Product | | | |
| Merchant Success | | | |
| UX / CX Lead | | | |

---

## Cross-references

- [00_PRODUCT_REQUIREMENTS_DOCUMENT.md](../00_PRODUCT_REQUIREMENTS_DOCUMENT.md)  
- [26_PRODUCT_BACKLOG.md](../26_PRODUCT_BACKLOG.md)  
- [SPRINT1_IMPLEMENTATION.md](../SPRINT1_IMPLEMENTATION.md)  
- [SPRINT_1_ENGINEERING_GATE_REVIEW.md](../../../reviews/merchant/SPRINT_1_ENGINEERING_GATE_REVIEW.md)

---

*Next PAR: **MVP / R-MVP** when PRD §21 and §39 acceptance criteria are targeted for release.*
