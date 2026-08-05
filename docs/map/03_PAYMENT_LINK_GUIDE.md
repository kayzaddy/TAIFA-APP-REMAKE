# 3. Payment Link Guide

Create secure links for invoices, orders, bookings, deposits, subscriptions, donations, campaigns.

## Properties

- Expiration (`ttl_minutes`)
- Usage limits (`max_uses`)
- Signature (intent HMAC)
- Branding JSON from acceptance profile

## Paths

- API create: `POST /api/v1/map/merchants/{id}/links`
- Resolve: `GET /api/v1/map/links/{path_token}`
- App: `/map/pay/{path_token}`

Customer resolves token → sees intent → `POST .../intents/{code}/pay` with Idempotency-Key.
