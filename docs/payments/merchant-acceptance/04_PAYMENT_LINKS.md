# 04 — Payment Links

---

## Executive summary

**Payment links** for requests, invoices, SMS/WhatsApp/email share, one-time and recurring, with expiry and branding.

---

## Business purpose

Remote collection without physical presence—e-commerce and informal merchants.

---

## Architecture overview

```mermaid
flowchart LR
  MER[Merchant] --> LINK[Link Service]
  LINK --> ORCH[Orchestration]
  CUST[Customer Browser/App] --> LINK
  LINK --> PAGE[Hosted Checkout]
  PAGE --> ORCH
```

---

## Link types

| Type | Behavior |
| --- | --- |
| One-time | Single successful payment closes |
| Reusable | Multiple until cap/expiry |
| Invoice | Line items + tax hook |
| Recurring | Mandate + schedule metadata → orchestration workflow |

---

## State diagram

```mermaid
stateDiagram-v2
  [*] --> draft
  draft --> active: publish
  active --> paid: success
  active --> expired: ttl
  active --> cancelled: merchant
  paid --> [*]
```

---

## Sequence: WhatsApp share

```mermaid
sequenceDiagram
  participant M as Merchant
  participant MAP as Link API
  participant U as Customer
  participant O as Orchestration
  M->>MAP: POST /payment-links
  MAP-->>M: url
  M->>U: WhatsApp share
  U->>MAP: open checkout
  MAP->>O: create payment
  O-->>MAP: completed
  MAP-->>Bus: payment.link.paid
```

---

## API / events / security

Short URLs; rate limit resolve; bot protection on hosted page.

---

## AWS

CloudFront hosted checkout; WAF.

---

## Implementation strategy

Reuse Payment Sources picker UI component.

---

## Operational model

Link analytics funnel.

---

## Future expansion

Embedded buy buttons for social commerce.

---

## Cross-references

[06_TRANSACTION_FLOW.md](06_TRANSACTION_FLOW.md)
