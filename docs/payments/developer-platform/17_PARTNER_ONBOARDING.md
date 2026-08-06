# 17 — Partner Onboarding

---

## Executive summary

End-to-end **partner onboarding**: registration, verification, organization type, legal agreements, sandbox access, integration, certification, production approval—tailored for banks, telcos, government, and ISVs.

---

## Business purpose

Controlled national access to TNPI APIs with clear accountability.

---

## Architecture overview

```mermaid
flowchart TB
  REG[Register] --> VER[Verify identity]
  VER --> ORG[Create organization]
  ORG --> LEG[Accept agreements]
  LEG --> SB[Sandbox keys]
  SB --> INT[Integrate]
  INT --> CERT[Certification]
  CERT --> REV[Taifa review]
  REV --> PROD[Production keys]
```

---

## Partner types

| Type | Verification | Default scopes |
| --- | --- | --- |
| Bank / PSP | Enhanced due diligence | sources, webhooks |
| Telco | License verification | sources, payments |
| Government agency | MoU reference | gov, reports |
| Merchant / ISV | Business reg | payments, MAP |
| Transport operator | Phase 9 track | transport, payments |
| Fintech | BoT sandbox rules | payments |

---

## Developer journey

```mermaid
sequenceDiagram
  participant P as Partner
  participant Portal as Developer Portal
  participant Ops as Taifa Partner Ops
  P->>Portal: register + org
  Portal-->>P: sandbox credentials
  P->>Portal: complete integration
  P->>Portal: submit certification
  Portal->>Ops: review queue
  Ops-->>P: application.approved
  P->>Portal: create live key
```

---

## Legal & compliance

- API Terms of Use  
- Data processing addendum  
- PCI responsibility matrix (partner SAQ)  

---

## API flow

Production routes enabled only when `application.approval_status = approved`.

---

## Security

Enhanced verification for production; mTLS onboarding workshop for banks.

---

## AWS

Partner docs in S3; signed MoU metadata in RDS.

---

## Operational considerations

SLA: sandbox instant; production review 10 business days target.

---

## Implementation strategy

DP-1 registration; DP-5 approval workflow in portal.

---

## Future expansion

Self-service BoT regulatory filing reference field.

---

## Cross-references

[18_CERTIFICATION_PROGRAM.md](18_CERTIFICATION_PROGRAM.md) · [07_API_SECURITY.md](07_API_SECURITY.md)
