# 15 — API Specification (TIP Control Plane)

**Base:** `https://api.taifa.go.tz/v1/integration` (internal + partner admin)

---

## Executive summary

REST APIs to manage integration infrastructure—not business domain APIs.

---

## API groups

### Partners & consumers
`POST /partners`, `GET /partners/{id}`, `POST /partners/{id}/certificates`

### API products & plans
`GET /products`, `POST /products`, `POST /products/{id}/plans`

### Subscriptions
`POST /subscriptions`, `GET /subscriptions/{id}`

### Credentials
`POST /credentials/api-keys`, `POST /credentials/oauth-clients`, `POST /credentials/rotate`

### Routes & policies
`GET /routes`, `POST /routes`, `PUT /policies/{id}`

### Event channels
`POST /event-channels`, `GET /event-catalog`

### Webhooks (platform)
`POST /webhooks`, `GET /webhooks/{id}/deliveries`, `POST /webhooks/{id}/replay`

### Flows
`POST /flows`, `GET /flows/{id}/executions`

### Adapters
`POST /adapters`, `GET /adapters/{id}/health`

### Analytics
`GET /analytics/usage`, `GET /analytics/errors`, `GET /analytics/latency`

### Sandbox
`POST /sandbox/mocks`, `POST /sandbox/contract-tests/run`

---

## OpenAPI

`openapi/tip-control-v1.yaml`

---

## Security

Admin roles `integration:admin`, `integration:partner:{id}`; all mutations audited.

---

## Cross-references

[09_API_SECURITY.md](09_API_SECURITY.md)
