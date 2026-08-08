# 02 — SoftPOS

---

## Executive summary

Enterprise **SoftPOS** for Android NFC (and future iPhone Tap to Pay): merchant login, device auth, tap-to-pay, card & wallet acceptance, receipts, refunds, offline queue, sync, analytics—**all charges via Orchestration**.

---

## Business purpose

Replace dedicated POS hardware for SMEs and field merchants (daladala, markets, tourism).

---

## Architecture overview

```mermaid
flowchart TB
  subgraph device [SoftPOS App Android]
    UI[Cashier UI]
    NFC[NFC Kernel SDK]
    OFFL[Offline Store]
    SYNC[Sync Agent]
  end
  subgraph map [MAP SoftPOS Service]
    SESS[Transaction Session]
    ORC[Orchestration Client]
  end
  UI --> SESS
  NFC --> SESS
  SESS --> ORC
  ORC -->|POST /payments| ORCH[Orchestration]
  OFFL --> SYNC --> SESS
```

---

## State diagram (session)

```mermaid
stateDiagram-v2
  [*] --> idle
  idle --> amount_entry: start_sale
  amount_entry --> tapping: present_card
  tapping --> processing: nfc_read
  processing --> completed: orch_ok
  processing --> failed: orch_fail
  processing --> queued: offline
  queued --> processing: sync
  completed --> idle
  failed --> idle
```

---

## Sequence: tap to pay

```mermaid
sequenceDiagram
  participant C as Customer
  participant D as SoftPOS Device
  participant M as MAP SoftPOS API
  participant O as Orchestration
  participant P as PSP
  C->>D: Tap card/NFC wallet
  D->>M: softpos.transaction.created
  M->>O: POST /payments channel=softpos
  O->>P: authorize/capture
  P-->>O: completed
  O-->>M: payment_id
  M-->>D: softpos.transaction.completed
  D-->>C: Digital receipt
```

---

## EMV & PCI DSS

| Topic | Design |
| --- | --- |
| PAN | Only inside certified MPoC SDK / kernel |
| PIN on Glass | Where scheme + device certified |
| Scope | MAP app + SDK in CDE; MAP API out of CDE |
| Attestation | Play Integrity on activation |
| Scheme | Visa Tap to Phone / Mastercard Tap on Phone program |

---

## API specifications

See [07_API_SPECIFICATION.md](07_API_SPECIFICATION.md) § SoftPOS.

---

## Domain events

`softpos.transaction.*` — [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md)

---

## AWS / security / implementation

Edge TLS; receipt S3; no PAN in MAP service logs.

---

## Operational model

Terminal config push; remote disable via Merchant device registry.

---

## Future expansion

iOS kernel; tipping; multi-merchant on one device (shift model).

---

## Cross-references

[tap_pay/02_NFC_INTEGRATION.md](../../tap_pay/02_NFC_INTEGRATION.md)
