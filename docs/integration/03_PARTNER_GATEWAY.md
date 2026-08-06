# 03 — Partner Gateway

---

## Executive summary

**Partner Gateway** (B2B edge): banks, MNOs, insurers, airlines, hotels, health, education, municipalities, developers—mTLS, contractual API products, stricter WAF, dedicated usage plans.

---

## Business purpose

Isolate partner blast radius from citizen-facing enterprise gateway.

---

## Architecture overview

```mermaid
flowchart TB
  PART[Partners]
  PGW[Partner API Gateway]
  POL[Policy engine]
  ADP[Adapter optional]
  DOM[Taifa domain APIs]
  PART -->|mTLS| PGW --> POL --> ADP --> DOM
```

---

## Partner onboarding

Register org → legal agreement → sandbox credentials → certification tests → production mTLS cert → API product subscription — extends [Developer Platform](../payments/developer-platform/17_PARTNER_ONBOARDING.md) with **TIP runtime enforcement**.

---

## Supported partner classes

Government agencies · Banks · Mobile money · Insurance · Airlines · Hotels · Tourism · Healthcare · Schools · Universities · Municipalities · ISVs.

---

## Sequence: onboarding

```mermaid
sequenceDiagram
  participant P as Partner
  participant T as TIP control plane
  participant S as Sandbox
  P->>T: register consumer
  T-->>P: sandbox key + mTLS CSR guide
  P->>S: contract tests pass
  T-->>P: prod cert issued
```

---

## Analytics

Per-partner latency, error rate, quota consumption — [14_OBSERVABILITY.md](14_OBSERVABILITY.md).

---

## Security

[09_API_SECURITY.md](09_API_SECURITY.md) · certificate management ACM Private CA.

---

## Implementation strategy

TIP-P1 partner GW after enterprise GW.

---

## Future expansion

API marketplace billing (TNPI for fees).

---

## Cross-references

[12_API_MARKETPLACE.md](12_API_MARKETPLACE.md)
