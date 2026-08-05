# 06 — Protection Domain

**Bounded context:** `tourism.protection`  
**Strategic classification:** Core (trust & regulatory).

---

## 1. Business purpose

Traveler safety and risk transfer: insurance, emergency assistance, SOS, facilities directory, claims, advisories.

## 2. Responsibilities

Embed insurance at checkout, assistance cases, SOS workflow → national safety graph, FNOL, travel advisories—not trip orchestration logic.

## 2a. SafetyIncident RACI (Mobility vs Protection)

| Artifact | System of record | Protection role |
| --- | --- | --- |
| `trips.SafetyIncident` | **04 Mobility** (national `trips` platform) | Opens/links via SOS API; reads for ops |
| `tourism_assistance_case` | **06 Protection** | Owns workflow, contacts, resolution |
| `protection.sos.opened` event | Published by **06** | Subscribers: Orchestration, Mobility, Notifications |

SOS handlers **create** a Mobility incident record and a Protection assistance case in one user action; do not duplicate incident geometry or AVL state in Protection tables.

## 3. Submodules

`travel-insurance` · `emergency` · `sos` · `facilities` · `claims` · `advisories` · `medical`

## 4. Microservices

`protection-policy` · `protection-assist` · `protection-claims` · `protection-advisory-feed`

**Phase-1:** `commerce/insurance-policies`, `tourism/assist/*`, `trips.SafetyIncident`

## 5–7. Domain model

**Entities:** `Policy`, `AssistanceCase`, `Claim`, `Advisory`  
**Aggregates:** `Policy` (active/cancelled), `AssistanceCase` (open → resolved)  
**Value objects:** `CoverageLimit`, `Premium`, `IncidentLocation`, `PolicyRef`

## 8. Domain events

`protection.policy.issued` · `protection.sos.opened` · `protection.claim.submitted` · `protection.advisory.published`

## 9. APIs

`POST assist/sos` · `GET assist/nearby` · commerce insurance policies · future `protection/claims`

## 10. Database tables

`commerce_insurance_policy`, `tourism_assistance_case`, mobility `safety_incident` (linked)

## 11. Event flows

See [TRAVEL_INSURANCE_BLUEPRINT.md](TRAVEL_INSURANCE_BLUEPRINT.md); SOS links Orchestration `trip_id`.

## 12–15.

TIRA-aligned disclosures; KMS; Finance for premiums; multi-underwriter portal.

**Detail doc:** [TRAVEL_INSURANCE_BLUEPRINT.md](TRAVEL_INSURANCE_BLUEPRINT.md)
