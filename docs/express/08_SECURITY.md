# Taifa Express — Security Manual

## Principles

- Device-bound API access only.  
- Server-authored `payment_ref` / status — clients cannot forge paid state.  
- Idempotent pay/checkout via `Idempotency-Key`.  
- AI never receives authorize/pay capabilities.  
- Locations and POD stay on Mobility/Identity rails with existing controls.

## Threat notes

| Threat | Mitigation |
| --- | --- |
| Replay pay | Idempotency + ledger uniqueness |
| Stock race | Atomic stock decrement after successful pay |
| Merchant spoof | Ranking uses verified active stores; settlement via platform/merchant of record |
| Fraud baskets | Amount limits inherit Payments risk policies |

## Data classes

Orders, addresses, payment refs, trip ids — treat as sensitive; no client-side ledger writes.
