# 07 — API Specification (MAP)

**Base:** `/api/v1/acceptance` (and channel aliases) · **Auth:** Merchant JWT + device cert

---

## Executive summary

Unified **Merchant Acceptance APIs** for SoftPOS, QR, links, receipts, terminals, refunds, devices, checkout.

---

## Business architecture

All payment mutations **delegate** to Orchestration `POST /api/v1/payments` etc.

---

## SoftPOS

| Method | Path |
| --- | --- |
| POST | `/acceptance/softpos/sessions` |
| POST | `/acceptance/softpos/transactions` |
| POST | `/acceptance/softpos/sync` |
| POST | `/acceptance/softpos/refunds` |
| GET | `/acceptance/softpos/transactions` |

---

## QR

| Method | Path |
| --- | --- |
| POST | `/acceptance/qr/static` |
| POST | `/acceptance/qr/dynamic` |
| GET | `/acceptance/qr/{id}` |
| POST | `/acceptance/qr/{id}/revoke` |

---

## Payment links

| Method | Path |
| --- | --- |
| POST | `/acceptance/payment-links` |
| GET | `/acceptance/payment-links/{id}` |
| POST | `/acceptance/payment-links/{id}/cancel` |

---

## Checkout (in-app / e-com)

| Method | Path |
| --- | --- |
| POST | `/acceptance/checkout/sessions` |
| GET | `/acceptance/checkout/sessions/{id}` |

---

## Receipts

| Method | Path |
| --- | --- |
| GET | `/acceptance/receipts/{id}` |
| POST | `/acceptance/receipts/{id}/share` |

---

## Terminals & devices

| Method | Path |
| --- | --- |
| POST | `/acceptance/devices/{id}/heartbeat` |
| GET | `/acceptance/devices/{id}/health` |
| POST | `/acceptance/devices/{id}/disable` |

---

## Refunds & voids

| Method | Path |
| --- | --- |
| POST | `/acceptance/refunds` → orchestration |
| POST | `/acceptance/voids` → orchestration cancel |

---

## Merchant acceptance aggregate

| Method | Path |
| --- | --- |
| GET | `/acceptance/transactions` | History (from orchestration read model) |
| GET | `/acceptance/analytics/summary` | Acceptance KPIs |

---

## Security

Device JWT + merchant RBAC; request signing for e-com partners.

---

## AWS

API Gateway routes to MAP ECS services.

---

## Implementation strategy

OpenAPI `tnpi-map-v1`.

---

## Operational model

Version deprecation policy 12 months.

---

## Future expansion

GraphQL BFF for merchant portal.

---

## Cross-references

[orchestration/07_API_SPECIFICATION.md](../orchestration/07_API_SPECIFICATION.md)
