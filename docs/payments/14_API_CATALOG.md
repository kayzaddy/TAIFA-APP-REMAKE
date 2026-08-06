# 14 — TNPI API Catalog

**Base URL:** `https://api.taifa.go.tz` (production TBD)  
**Version:** `/api/v1`  
**Authority (Phase 8):** Public edge and partner lifecycle — [developer-platform/00_INDEX.md](developer-platform/00_INDEX.md) · [PHASE8_GATE_PACKAGE](developer-platform/PHASE8_GATE_PACKAGE.md)

---

## Executive summary

Canonical REST catalog for TNPI: merchants, wallets, payments, settlements, SoftPOS, QR, webhooks, and partner B2B APIs—all OpenAPI-first with Spectral CI (Taifa Core).

---

## Authentication

| Method | Use |
| --- | --- |
| OAuth 2.0 / OIDC | Merchant & user apps |
| Client credentials | Server-to-server partners |
| mTLS | Tier-1 banks / government |

Headers: `Authorization: Bearer`, `Idempotency-Key`, `X-Correlation-Id`, `X-Merchant-Id` (where applicable).

---

## Merchant & foundation

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/v1/merchants` | Register merchant |
| GET | `/api/v1/merchants/{id}` | Get merchant |
| PATCH | `/api/v1/merchants/{id}` | Update profile |
| POST | `/api/v1/merchants/{id}/verification` | Submit KYC |
| GET | `/api/v1/merchants/{id}/terminals` | List terminals |
| POST | `/api/v1/merchants/{id}/terminals` | Enroll SoftPOS/QR terminal |

---

## Wallet aggregation

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/v1/wallets/link` | Start instrument link |
| GET | `/api/v1/wallets` | List linked instruments |
| DELETE | `/api/v1/wallets/{id}` | Revoke |
| PATCH | `/api/v1/wallets/{id}/default` | Set default |

---

## Payments (orchestration)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/v1/payments` | Create payment intent |
| GET | `/api/v1/payments/{id}` | Get status |
| POST | `/api/v1/payments/{id}/capture` | Capture authorization |
| POST | `/api/v1/payments/{id}/cancel` | Cancel |
| POST | `/api/v1/payments/{id}/refund` | Refund (full/partial) |
| GET | `/api/v1/payments` | List (merchant-scoped) |

**Request body (create) — illustrative:**

```json
{
  "amount": { "currency": "TZS", "minor_units": 500000 },
  "merchant_id": "uuid",
  "instrument_id": "uuid",
  "channel": "ecommerce|softpos|qr|transport",
  "metadata": { "order_id": "string" },
  "idempotency_key": "string"
}
```

---

## Settlement & reconciliation

| Method | Path | Description |
| --- | --- | --- |
| GET | `/api/v1/settlements` | List batches |
| GET | `/api/v1/settlements/{id}` | Batch detail |
| GET | `/api/v1/merchants/{id}/balance` | Pending settlement position |
| GET | `/api/v1/reconciliation/exceptions` | Ops — exceptions |

---

## SoftPOS

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/v1/softpos/sessions` | Open cashier session |
| DELETE | `/api/v1/softpos/sessions/{id}` | Close session |
| POST | `/api/v1/softpos/transactions` | Submit tap |
| POST | `/api/v1/softpos/sync` | Offline batch upload |
| POST | `/api/v1/softpos/refunds` | Refund |

---

## QR

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/v1/qr/static` | Register static QR |
| POST | `/api/v1/qr/dynamic` | Create dynamic QR |
| GET | `/api/v1/qr/{id}` | Resolve payload |
| POST | `/api/v1/qr/{id}/pay` | Payer confirm |

---

## Receipts & reporting

| Method | Path | Description |
| --- | --- | --- |
| GET | `/api/v1/receipts/{id}` | Digital receipt |
| GET | `/api/v1/reports/transactions` | Merchant report (async) |

---

## Webhooks (merchant)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/v1/webhooks/endpoints` | Register URL |
| GET | `/api/v1/webhooks/endpoints` | List |

**Delivery events:** `payment.completed`, `payment.failed`, `refund.completed`, `settlement.completed`.

Signature: `HMAC-SHA256` header `Taifa-Signature`.

---

## Partner B2B

| Method | Path | Description |
| --- | --- | --- |
| POST | `/api/v1/partner/payments` | Partner-initiated pay |
| GET | `/api/v1/partner/health` | PSP health probe |

See [16_PARTNER_INTEGRATION_GUIDE.md](16_PARTNER_INTEGRATION_GUIDE.md).

---

## Legacy compatibility

| Legacy | TNPI mapping |
| --- | --- |
| `/api/v1/map/tap/*` | Routes to acceptance → orchestrator |
| `capture_merchant_payment` | `POST /api/v1/payments` |

---

## Security model

Rate limits per merchant tier; scope claims on JWT; PCI fields only on SoftPOS endpoints.

---

## AWS deployment

API Gateway route maps; VPC Link to ECS services.

---

## Implementation roadmap

OpenAPI bundle in `packages/openapi/tnpi-v1.yaml` (future); Spectral rules in CI.

---

## Acceptance criteria

Contract tests for top 20 endpoints; breaking changes require `/api/v2`.

---

## Definition of done

OpenAPI published; developer portal renders catalog.

---

## Cross-references

[03_PAYMENT_ORCHESTRATION.md](03_PAYMENT_ORCHESTRATION.md) · [16_PARTNER_INTEGRATION_GUIDE.md](16_PARTNER_INTEGRATION_GUIDE.md)
