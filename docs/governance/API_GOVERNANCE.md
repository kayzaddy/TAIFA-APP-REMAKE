# API Governance

## Supported styles

| Style | Status | Use |
| --- | --- | --- |
| REST + OpenAPI | **Authoritative** | All public HTTP APIs under `/api/v1/` |
| WebSockets | Supported | Mobility live channels |
| Webhooks | Supported | Ecosystem + partner outbox |
| GraphQL | Planned | Must not bypass REST authz/ledger rules |
| gRPC | Future internal | Only behind gateway with contracts |

## Mandatory standards

- **Versioning:** URL major version (`/api/v1/`); additive changes preferred; breaking → `/v2/` + ADR.
- **Semantic versioning:** OpenAPI `VERSION` and SDK packages follow SemVer.
- **Deprecation:** Announce ≥90 days; mark `Deprecated` in OpenAPI; remove only after sunset date in ADR.
- **Pagination:** Prefer cursor or limit/offset with max page size; document defaults.
- **Filtering/sorting:** Explicit allow-listed query params; never raw SQL from clients.
- **Errors:** JSON `{ "detail": "..." }` (+ field errors when validation); stable codes where money is involved.
- **Idempotency:** Required on money writes (`Idempotency-Key`).
- **AuthN/Z:** Device bearer + enterprise RBAC/ABAC as applicable; never trust client-supplied owner.
- **Rate limiting:** DRF throttle scopes; public partner keys rate-limited.
- **OpenAPI:** Spectacular schema must stay green in CI (`spectacular --fail-on-warn`).
- **SDKs:** Thin clients only; never reimplement ledger/auth (`packages/sdk-*`).

## API Review Board

Public or partner-facing endpoints require:

1. OpenAPI tag + description  
2. Auth model documented  
3. Error & idempotency notes  
4. Owner in [`OWNERSHIP.md`](OWNERSHIP.md)  
5. Contract tests for money/identity paths  

## Webhooks

Signed secrets (hashed at rest), event type allow-lists, retry via outbox, no PII in URLs.
