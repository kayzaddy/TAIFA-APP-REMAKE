# Open Platform Guide

## Surfaces

1. **REST** — `/api/v1/*` (authoritative)
2. **OpenAPI** — `/api/schema`, Swagger `/api/docs`
3. **Webhooks** — subscribe at `/api/v1/ecosystem/webhooks/`
4. **SDKs** — Python, JavaScript, Flutter under `packages/`

## Partner onboarding

```http
POST /api/v1/ecosystem/partners/apply
{
  "partner_code": "muni-dsm",
  "legal_name": "Dar Municipality",
  "domains": ["mobility", "government"],
  "contact_email": "ops@example.go.tz"
}
```

Starts `business_verification` workflow. Domain access still requires Identity device tokens and RBAC grants.

## Webhooks

```http
POST /api/v1/ecosystem/webhooks/
{
  "target_url": "https://partner.example/hooks/taifa",
  "event_types": ["*"]
}
```

Response includes a one-time `secret`. Delivery workers drain `enterprise.EventOutbox` (see `drain_outbox`).

## SDK quick start

**Python**

```python
from taifa import TaifaClient
client = TaifaClient("https://api.example", bearer_token="…")
print(client.ecosystem_blueprint())
```

**JavaScript**

```js
import { createTaifaClient } from "./taifa.js";
const client = createTaifaClient("https://api.example", token);
await client.myModules();
```

**Flutter** — use Super App `EcosystemClient` or `packages/sdk-flutter` path constants.

## GraphQL

Planned. Until then, OpenAPI + REST versioning (`/api/v1/`) is the contract. Do not build parallel GraphQL that bypasses Payments or Identity.
