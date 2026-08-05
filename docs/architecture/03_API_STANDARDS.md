# 03 — API Standards

**Purpose:** Enterprise REST and contract standards for all Taifa public and partner APIs.  
**Scope:** Backend services, BFFs, webhooks; mobile and web clients as consumers.  
**Principles:** Predictable, versioned, secure, observable, idempotent where it matters.

---

## REST conventions

| Rule | Standard |
| --- | --- |
| Base path | `/api/v{major}/` |
| Resource names | Plural nouns, kebab-case paths: `/tourism/trips`, `/payments/captures` |
| Methods | GET (read), POST (create/command), PATCH (partial update), DELETE (cancel where idempotent) |
| Status codes | 200/201 success, 204 no body, 400 validation, 401 unauthenticated, 403 forbidden, 404 not found, 409 conflict, 422 semantic error, 429 rate limit, 503 dependency down |
| Content-Type | `application/json`; `application/problem+json` for errors (RFC 7807) |

---

## Versioning

- **URL major version** required: `/api/v1/`, `/api/v2/` parallel run during migration.  
- **Minor** changes: additive fields only; no version bump.  
- **Breaking:** new major + `Sunset` / `Deprecation` headers on old routes (minimum 90 days citizen-facing).  
- **OpenAPI** `info.version` tracks contract; CI fails on breaking diff without major bump.

---

## Naming

| Element | Convention |
| --- | --- |
| Path params | `{trip_id}`, `{id}` UUID |
| Query filters | `?status=active&market=TZ` |
| Commands | POST sub-resource: `/trips/{id}/checkout/pay` |
| Domain prefix | Align with [01_DOMAIN_GOVERNANCE.md](01_DOMAIN_GOVERNANCE.md): `/tourism/`, `/payments/`, `/identity/` |

---

## Pagination

- Cursor-based default: `?cursor={opaque}&limit=50` (max 100).  
- Response: `{ "results": [], "next_cursor": "..." }`.  
- Offset allowed only for admin/low-volume endpoints (document in OpenAPI).

---

## Filtering & sorting

- Allowlist filter fields per resource in OpenAPI.  
- Sort: `?sort=-created_at` (prefix `-` desc).  
- Reject unknown filter keys with 400.

---

## Authentication

- `Authorization: Bearer {access_token}` (OAuth2 / OIDC via **Identity**).  
- Mobile: `X-Device-Id` + attestation where enabled.  
- Partner: mTLS or client credentials + scoped tokens.  
- Service-to-service: IAM-signed requests or internal JWT with audience claim.

---

## Authorization

- **RBAC** for staff/admin portals.  
- **ABAC** for citizen data: `resource.owner_id == subject.id`.  
- Domain APIs enforce authorization in application layer—not only gateway.

---

## Error responses

```json
{
  "type": "https://taifa.go.tz/errors/insufficient-funds",
  "title": "Insufficient funds",
  "status": 409,
  "detail": "Wallet balance too low for checkout.",
  "code": "FINANCE_INSUFFICIENT_FUNDS",
  "correlation_id": "uuid"
}
```

Never expose stack traces or internal IDs in production.

---

## Rate limiting

| Tier | Default |
| --- | --- |
| Anonymous | 60 req/min/IP |
| Authenticated citizen | 300 req/min/subject |
| Partner | Contractual; API key + quota |

Headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After`.

---

## Idempotency

- **Required** on POST that moves money, creates reservations, or issues permits.  
- Header: `Idempotency-Key: {uuid}` scoped to route + subject.  
- Server stores response 24h; replay returns same status/body.

---

## Correlation IDs

- Client may send `X-Correlation-Id`; server generates if absent.  
- Propagate to logs, events (`correlation_id`), and outbound port calls.

---

## Tracing

- W3C `traceparent` supported; AWS X-Ray on gateway and ECS/Lambda.  
- Sample rate: 10% default, 100% on errors and payment paths.

---

## OpenAPI requirements

- Every public route in OpenAPI 3.1 (`drf-spectacular` or equivalent).  
- Tags = **domain name** (e.g. `Tourism - Orchestration`, `Finance - Payments`).  
- Schemas for request/response; enums documented.  
- CI: spectral lint + breaking-change detector.

---

## Backward compatibility

| Change | Allowed in minor |
| --- | --- |
| Add optional response field | Yes |
| Add optional request field | Yes |
| Remove field | No |
| Change type | No |
| Rename field | No (add new, deprecate old) |

---

## Examples

**Good:** `POST /api/v1/tourism/trips/{trip_id}/checkout/pay` + `Idempotency-Key`

**Bad:** `POST /api/v1/tourism/pay` without trip scope or idempotency

---

## Cross-references

- Tourism module API: [`../tourism/12_API_STANDARDS.md`](../tourism/12_API_STANDARDS.md) (extends this doc)  
- [`../NATIONAL_API.md`](../NATIONAL_API.md)  
- [05_SECURITY_STANDARDS.md](05_SECURITY_STANDARDS.md)  
- [02_EVENT_CATALOG.md](02_EVENT_CATALOG.md)

---

## Future considerations

- GraphQL read BFF for mobile home (mutations still REST to domain owners)  
- Async command pattern: `202 Accepted` + `command_id` poll/webhook for long government steps
