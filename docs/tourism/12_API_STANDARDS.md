# 12 — API Standards

> **Governance:** Platform REST law — [`../../architecture/03_API_STANDARDS.md`](../../architecture/03_API_STANDARDS.md). Below: Tourism **paths, namespaces, and examples**.

**Base path:** `/api/v1/` · **Tourism orchestration:** `/api/v1/tourism/` · **Booking:** `/api/v1/commerce/` (until facade migration)

---

## Conventions

| Rule | Detail |
| --- | --- |
| Versioning | URL prefix `v1`; breaking → `v2` parallel run |
| Auth | `Authorization: Bearer` + `X-Device-Id` |
| Idempotency | `Idempotency-Key` on all POST that move money or create reservations |
| Money | Integer minor units + ISO currency; clients never set `paid` |
| Errors | RFC 7807-style `{detail}` + `code` |
| Pagination | `cursor` + `limit` for lists |
| OpenAPI | `drf-spectacular`; CI fail on warn |

---

## Domain API namespaces (target)

| Domain | Prefix |
| --- | --- |
| Discovery | `/tourism/discovery/` |
| Orchestration | `/tourism/` (trips, cart, checkout) |
| Booking | `/commerce/` → `/tourism/booking/` |
| Mobility | `/trips/` + tourism bridge |
| Connectivity | `/tourism/connectivity/` |
| Protection | `/tourism/protection/` + commerce insurance |
| Finance | `/payments/` (platform) |
| Government | `/tourism/government/` |
| AI | `/tourism/ai/` + ecosystem invoke |

---

## Contract example (checkout pay)

```yaml
post:
  /api/v1/tourism/trips/{trip_id}/checkout/pay:
    parameters:
      - name: Idempotency-Key
        in: header
        required: true
    responses:
      200:
        schema: TourismCheckoutV2
      409:
        description: CommerceError / insufficient funds
```

---

## BFF pattern (presentation)

Mobile may use aggregated screens but **must not** merge domain invariants—call orchestration first for trip flows.

---

## Partner APIs

mTLS, scoped OAuth, webhook HMAC + replay protection (TOUR-011).

## Testing

Schemathesis / Dredd against OpenAPI; Pact between Orchestration ↔ Booking.
