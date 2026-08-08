# 18 — Certification Program

---

## Executive summary

**TNPI Certified Integrator** program: technical checklist, automated sandbox tests, security questionnaire, optional live review, badge in portal, renewal annual.

---

## Business purpose

Reduce production incidents and fraud from poorly integrated partners.

---

## Architecture overview

```mermaid
flowchart LR
  CHK[Checklist]
  AUTO[Automated tests]
  MAN[Manual review]
  CHK --> AUTO --> MAN --> BADGE[Certified]
```

---

## Certification tracks

| Track | Required for |
| --- | --- |
| Payments Core | All payment integrators |
| Webhooks | Async integrations |
| SoftPOS / QR | Terminal partners |
| Government | Agency collections |
| Transport | Phase 9 operators (prerequisite) |

---

## Automated tests (sandbox)

- Create payment → succeed  
- Idempotent retry same key  
- Webhook signature verify  
- Decline simulation handling  
- Refund simulation (if scope)  

---

## Developer journey

1. Complete quick start  
2. Run certification CLI or portal “Run tests”  
3. Submit security questionnaire  
4. Taifa engineer review (if high tier)  
5. `developer.certified` + production unlock  

---

## Renewal

Annual re-run automated suite; notify on breaking API changes via changelog.

---

## Security

Questionnaire covers key storage, PCI, incident response.

---

## Events

`certification.submitted`, `developer.certified` — [09_EVENT_CATALOG.md](09_EVENT_CATALOG.md).

---

## Operational considerations

Certification SLA 5 business days; appeal process documented.

---

## Implementation strategy

DP-5 harness invoking sandbox APIs with partner app credentials.

---

## Future expansion

Third-party auditor attestation for international partners.

---

## Cross-references

[05_SANDBOX.md](05_SANDBOX.md) · [17_PARTNER_ONBOARDING.md](17_PARTNER_ONBOARDING.md)
