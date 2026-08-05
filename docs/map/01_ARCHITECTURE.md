# 1. Merchant Acceptance Architecture

## Core flow

```
Customer → Acceptance Channel → Payment Intent (MAP)
    → Payments Platform (capture) → Risk → Ledger → Settlement
    → Merchant notification → Receipt (MAP)
```

## Bounded context

| Layer | Package | Responsibility |
| --- | --- | --- |
| Acceptance | `acceptance` | Profile, Intent, QR, Link, Invoice, Checkout, Terminal, Receipt |
| Merchant identity | `enterprise.Merchant` | Legal/financial identity (shared) |
| Commerce ops | `mos` | Catalog, stock, POS sales orders |
| Money | `payments` + `enterprise.orchestrator` | Capture, ledger, settlement |

## Channels (interfaces into one capture)

Static QR · Dynamic QR · Payment Link · Invoice · Remote Checkout · POS · SoftPOS (ready) · NFC (ready) · Wallet · Mobile Money · Card · Winga · Mobility · Commerce order

Future channels plug into `AcceptanceIntent` + `pay_intent()` — no new ledger.

## Invariants

1. Every payable channel creates or references an `AcceptanceIntent`.
2. Every successful pay calls `capture_merchant_payment`.
3. `payment_ref` stores the Payments `Transaction.id`.
4. HMAC signatures protect QR/intent tampering.
5. Idempotency-Key required on pay endpoints.
6. AI never authorizes payments.

## SoftPOS / NFC

`AcceptanceTerminal` carries `softpos_ready` / `nfc_ready` and attestation JSON. Device capture still creates an Intent and delegates to Payments — no parallel SoftPOS ledger.
