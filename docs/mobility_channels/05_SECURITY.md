# Taifa Mobility Hybrid Dispatch — Security

## Authentication

| Surface | Auth |
| --- | --- |
| Passenger / driver bind / verify-pin / status | Device JWT (`IsDevice`) + owner scoping |
| SMS / USSD / IVR webhooks | Unauthenticated — **must** be fronted by aggregator IP allow-list + shared secret at reverse proxy |

## Data protection

- **MSISDN:** stored on `DriverChannelBinding`; inbound logs use SHA-256 `msisdn_hash` only
- **Boarding PIN:** `make_password` hash; never returned in API after issue (sent via SMS only)
- **Audit:** `ChannelDispatchAttempt` + `InboundMessage` for forensics

## Tanzania PDPA alignment

- Minimize PII in webhook payloads persisted
- Passenger phone only in trip metadata when explicitly provided
- Right to erasure: cascade delete via driver/trip FK relationships

## OWASP considerations

- Rate-limit webhook endpoints at nginx (per-IP)
- Validate MSISDN normalization before hash lookup
- No stack traces in webhook responses
- Idempotent accept via `accept_offer` locking

## PCI / payments

Hybrid dispatch does **not** touch card data or wallet authorization. Payments remain in Taifa Payments.
