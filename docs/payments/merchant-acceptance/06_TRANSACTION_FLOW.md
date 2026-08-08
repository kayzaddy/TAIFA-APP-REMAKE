# 06 — Transaction Flows

---

## Executive summary

End-to-end **sequence diagrams** for all MAP channels—always through Orchestration.

---

## Business purpose

Shared reference for engineering and certification.

---

## SoftPOS flow

```mermaid
sequenceDiagram
  participant Cashier
  participant SoftPOS as SoftPOS App
  participant MAP as MAP API
  participant ORCH as Orchestration
  participant SRC as Payment Sources
  participant PSP as PSP
  Cashier->>SoftPOS: Enter amount
  SoftPOS->>MAP: session + softpos.transaction.created
  MAP->>ORCH: POST /payments
  ORCH->>SRC: validate source
  ORCH->>PSP: authorize
  PSP-->>ORCH: result
  ORCH-->>MAP: payment.completed
  MAP->>MAP: receipt.generated
  MAP-->>SoftPOS: softpos.transaction.completed
```

---

## QR flow

```mermaid
sequenceDiagram
  participant Customer
  participant App as Taifa App
  participant MAP as MAP QR
  participant ORCH as Orchestration
  Customer->>App: Scan QR
  App->>MAP: resolve
  App->>ORCH: pay
  ORCH-->>MAP: completed
  MAP-->>Bus: qr.payment.completed
  App-->>Customer: receipt
```

---

## Payment link flow

See [04_PAYMENT_LINKS.md](04_PAYMENT_LINKS.md).

---

## In-app / e-com checkout

```mermaid
sequenceDiagram
  participant Shop as Merchant App
  participant MAP as Checkout API
  participant ORCH as Orchestration
  Shop->>MAP: create checkout session
  MAP-->>Shop: session_id
  Shop->>ORCH: POST /payments metadata channel=api
  ORCH-->>MAP: status
  MAP-->>Shop: webhook to merchant
```

---

## Refund flow

```mermaid
sequenceDiagram
  participant Mer as Merchant
  participant MAP as MAP API
  participant ORCH as Orchestration
  Mer->>MAP: POST /refunds
  MAP->>ORCH: POST /payments/{id}/refund
  ORCH-->>MAP: refund.completed
  MAP-->>Bus: refund.completed
```

---

## Offline SoftPOS

```mermaid
sequenceDiagram
  participant D as Device
  participant Q as Offline Queue
  participant MAP as MAP Sync
  participant ORCH as Orchestration
  D->>Q: store intent signed
  Note over D: Network restored
  D->>MAP: sync batch
  MAP->>ORCH: idempotent POST /payments
  ORCH-->>MAP: results
```

---

## Security / AWS / implementation

Idempotency keys on sync; conflict resolution policy.

---

## Operational model

Stuck session sweeper.

---

## Future expansion

Customer display second screen flow.

---

## Cross-references

[orchestration/02_PAYMENT_LIFECYCLE.md](../orchestration/02_PAYMENT_LIFECYCLE.md)
