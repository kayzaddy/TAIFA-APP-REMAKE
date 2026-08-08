# 02 — Passenger Platform

---

## Executive summary

Passenger-facing capabilities: registration (linked to Identity), wallet integration via Payment Sources, trip/journey views, digital tickets (QR/NFC), passes, refunds/lost ticket, emergency assistance—**payments always via TNPI**.

---

## Business purpose

Single app experience for buying, holding, and using transport entitlements nationwide.

---

## Architecture overview

```mermaid
flowchart TB
  APP[Taifa / TPP Passenger App]
  subgraph tpp [TPP APIs]
    PROF[Passenger profile]
    TRIP[Trips journeys]
    TKT[Tickets wallet]
    PASS[Subscriptions]
  end
  subgraph external [Platform]
    ID[Identity]
    PS[Payment Sources API]
    TNPI[Developer API payments]
  end
  APP --> tpp
  PROF --> ID
  TKT -->|purchase| TNPI
  APP --> PS
```

---

## Capabilities

| Capability | Description |
| --- | --- |
| Passenger registration | Identity subject + mobility preferences |
| Wallet integration | Tokenized sources; no float in TPP |
| Trip planning | Manual + AI planner feed |
| Digital ticketing | QR/NFC payload bound to `ticket_id` |
| Pass products | Daily / weekly / monthly / student / senior / corporate |
| Refund requests | TPP case → TNPI refund API |
| Lost ticket recovery | Identity + purchase proof → reissue token |
| Emergency assistance | Location + trip context to ops (no payment) |

---

## Sequence: buy single ticket

```mermaid
sequenceDiagram
  participant P as Passenger
  participant T as TPP
  participant D as Developer API
  participant O as Orchestration
  P->>T: select route fare
  T->>T: create fare_obligation
  T->>D: POST /v1/payments channel=transport
  D->>O: orchestrate
  O-->>D: payment_id status
  D-->>T: webhook payment.completed
  T->>T: issue ticket
  T-->>P: QR ticket
```

---

## Pass subscriptions

TPP stores pass entitlement; renewal triggers TNPI recurring payment template (orchestration contract)—not local billing engine.

---

## Fraud hooks

Pass `metadata.transport` (mode, route, device) on every payment; rely on FRP via orchestration.

---

## Security

Ticket signing keys in KMS; QR rotating barcodes optional for high-fraud routes.

---

## Operational considerations

Offline ticket cache TTL; sync validation state on reconnect.

---

## Implementation strategy

TPP-P1 passenger API + ticket wallet after TNPI sandbox E2E.

---

## Future expansion

Family accounts; accessibility fare types.

---

## Cross-references

[05_TICKETING.md](05_TICKETING.md) · [07_API_SPECIFICATION.md](07_API_SPECIFICATION.md)
