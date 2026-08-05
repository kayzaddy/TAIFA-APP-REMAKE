# 4. Architecture Review Guide

**Owner:** Architecture Board · Principal Enterprise Architect  
**Extends:** [`../governance/EA_GOVERNANCE.md`](../governance/EA_GOVERNANCE.md) · [`../governance/API_GOVERNANCE.md`](../governance/API_GOVERNANCE.md)

---

## Required for Gate G1

| Artifact | Standard |
| --- | --- |
| Architecture Review Board (ARB) minutes | Dated · attendees · decision |
| Threat model | STRIDE or equivalent · CISO ack |
| ERD / domain model | Boundaries clear |
| API standards | Versioned · OpenAPI · no shadow money APIs |
| Domain boundaries | Bounded contexts named |
| Service ownership | Team + on-call |
| Versioning & deprecation | Policy stated |
| Technical debt register | Entry if accepted risk |
| Reuse map | Identity, Payments, Ledger, Wallet, Notifications, AI, Governance — **no duplicates** |

## Forbidden patterns

- Second ledger or balance table as money truth  
- AI authorizing payment  
- Cross-domain writes bypassing owned APIs  

## Review cadence

Per new platform / major change · Quarterly architecture review for L5+ platforms.
