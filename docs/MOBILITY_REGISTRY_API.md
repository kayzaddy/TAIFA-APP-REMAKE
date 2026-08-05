# National Mobility Registry API

Base path: `/api/v1/mobility-registry`

All endpoints require the existing device-bound bearer token and matching
`X-Device-Id`. Staff endpoints additionally require enterprise permissions and
apply the principal's `attributes.regions` ABAC restriction.

## Registration

- `POST /applications/drivers`
- `POST /applications/vehicles`
- `POST /applications/stations`
- `POST /applications/fleets`
- `GET /applications`
- `GET /applications/{application_id}`
- `POST /applications/{application_id}/submit`

Create requests require a client-generated `client_reference`. Replaying the
same reference for the same principal returns the existing application, which
makes offline synchronization idempotent. Sensitive request fields are
write-only. Wallet references are derived from the authenticated principal and
are never accepted as authority over another wallet.

## Documents

- `GET /applications/{application_id}/documents`
- `POST /applications/{application_id}/documents/upload` (multipart)
- `GET /documents/{document_id}/download`
- `POST /documents/{document_id}/review`

Multipart fields are `kind`, `document`, optional `document_number`,
`issue_date`, and `expiry_date`. A replacement supersedes the previous version;
history remains immutable.

## Verification and compliance

- `GET /verification/dashboard`
- `GET /compliance/dashboard`
- `POST /compliance/blacklist`
- `GET /verification/queue?status=&type=&region=&page=&page_size=`
- `POST /applications/{application_id}/workflow/advance`
- `POST /applications/{application_id}/workflow/approve`
- `POST /applications/{application_id}/workflow/reject`
- `POST /applications/{application_id}/workflow/suspend`
- `POST /applications/{application_id}/external-verification`
- `GET /applications/{application_id}/audit`

Workflow actions use `reason` and `comments`. Rejection and suspension require a
reason. Approval requires the application to have reached the approval stage.

## Search

`GET /search?q=&field=`

Supported fields are `name`, `phone`, `national_id`, `vehicle`, `engine`,
`chassis`, `fleet`, and `station`. Sensitive identifiers use exact blind-index
matching; names and public registration numbers support partial matching.
Responses contain only masked phone values and public identifiers.

## Permissions

- `mobility_registry.application.read`
- `mobility_registry.application.review`
- `mobility_registry.application.approve`
- `mobility_registry.application.reject`
- `mobility_registry.application.suspend`
- `mobility_registry.document.read`
- `mobility_registry.document.review`
- `mobility_registry.compliance.read`
- `mobility_registry.search`
- `mobility_registry.external.verify`
- `mobility_registry.station.manage`
- `mobility_registry.fleet.manage`

The generated OpenAPI contract is available at `/api/schema`; Swagger and ReDoc
are available at `/api/docs` and `/api/redoc`.
