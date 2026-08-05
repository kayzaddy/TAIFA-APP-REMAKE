# 08 — Government Domain

**Bounded context:** `tourism.government`  
**Strategic classification:** Supporting (adapter-heavy).

---

## 1. Business purpose

Integrate immigration, parks authority, tourism board, tax, permits, licensing—via **adapters**, not hardcoded authority logic.

## 2. Responsibilities

Visa checklist & apply handoff, park permits, TTB campaigns, government fee payments, license verification for operators.

## 3. Submodules

`visa` · `immigration` · `tanapa` · `ttb` · `tax` · `permits` · `licensing`

## 4. Microservices

`gov-visa-adapter` · `gov-parks-adapter` · `gov-payment-adapter` (see platform `government_adapter`)

## 5–7. Domain model

**Entities:** `VisaApplicationRef`, `Permit`, `GovernmentFee`  
**Aggregates:** `PermitApplication`  
**Value objects:** `PassportRef` (vault pointer), `PermitQuota`, `AuthorityCode`

## 8. Domain events

`government.permit.issued` · `government.visa.status.changed`

## 9. APIs

Future `/api/v1/tourism/government/visa/checklist` · attach permit refs to Orchestration trip

## 10. Database tables

PII-minimal refs; documents in S3 vault; permits in `gov_permit_ref`

## 11–15.

e-Government mTLS; Step Functions for long-running permits; Orchestration coordinates; EAC visa harmonization.

**Risks:** Adapter drift — versioned contracts per authority.
