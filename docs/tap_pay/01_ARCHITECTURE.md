# 1. Tap & Pay Architecture

```
Phone unlocked → NFC detect → TapSession
  → Funding resolve (priority)
  → Auth (biometric / PIN / risk-based)
  → AcceptanceIntent (channel=nfc|softpos)
  → pay_intent → capture_merchant_payment
  → Receipt → Success UX
```

| Layer | Owns |
| --- | --- |
| Tap & Pay UX | Detection, auth UX, funding priority, animations |
| MAP | Intent, terminal registry, receipts |
| Payments / Enterprise | Capture, ledger, settlement |

**Never** duplicate ledger, settlement, or merchant balances.
