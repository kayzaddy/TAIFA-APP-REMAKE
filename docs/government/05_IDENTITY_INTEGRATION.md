# 05 — Identity Integration

---

## Executive summary

**All authentication via Taifa Identity**—citizen, business, government staff SSO, MFA, RBAC/ABAC; GDSP never stores passwords or issues tokens independently.

---

## Business purpose

One national digital identity layer for government services.

---

## Architecture overview

```mermaid
flowchart LR
  APP[GDSP apps]
  ID[Taifa Identity OIDC]
  NIDA[NIDA claims adapter]
  APP -->|OAuth2 PKCE| ID
  ID -->|verified claims| APP
  ID -.-> NIDA
```

---

## Personas

| Persona | Identity profile |
| --- | --- |
| Citizen / resident | NIN-linked subject |
| Business | BRELA TIN + authorized reps |
| Visitor | Limited visitor identity |
| Government staff | IdP federation + PIV policy |
| Agent | Delegated access citizen |

---

## Authorization model

- **RBAC:** `gov_officer`, `gov_supervisor`, `agency_admin`, `citizen`  
- **ABAC:** `agency_id`, `jurisdiction`, `service_id`, `clearance_level`  

---

## Sequence: SSO to service

```mermaid
sequenceDiagram
  participant U as User
  participant G as GDSP portal
  participant ID as Identity
  U->>G: access service
  G->>ID: authorize redirect
  ID-->>G: id_token + claims
  G->>G: create session ABAC
```

---

## NIDA integration

Verification and attribute release through Identity adapters—not direct NIDA API from GDSP except via Identity broker.

---

## Security

Session binding; step-up MFA for high-risk transactions; staff conditional access.

---

## Operational considerations

Identity outage runbook: read-only catalog, queue submissions.

---

## Implementation strategy

GDSP-I0 OIDC client registration per environment.

---

## Future expansion

eIDAS-style cross-border visitor access.

---

## Cross-references

[platform identity docs](../platform/00_PLATFORM_OVERVIEW.md)
