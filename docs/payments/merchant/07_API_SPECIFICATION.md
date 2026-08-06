# 07 — API Specification (Merchant Platform)

**Base path:** `/api/v1`  
**OpenAPI:** `tnpi-merchant-v1` (target bundle)  
**Standards:** [architecture/03_API_STANDARDS.md](../../architecture/03_API_STANDARDS.md)

---

## Executive summary

REST API surface for Merchant Platform Phase 1—registration, verification, branches, devices, employees, roles, settlement accounts, API keys, webhooks, search, status, and analytics.

---

## Business purpose

Contract-first development; Spectral CI on Taifa Core pipeline.

---

## Authentication

| Audience | Method |
| --- | --- |
| Merchant users | OAuth 2.0 / OIDC Bearer JWT |
| Server automation | Client credentials + `merchant_id` claim |
| Internal ops | SSO + internal role |

**Headers:** `Authorization`, `X-Correlation-Id`, `X-Idempotency-Key` (mutations), `X-Merchant-Id` (when acting in context).

---

## Merchant lifecycle

| Method | Path | Description |
| --- | --- | --- |
| POST | `/merchants` | Register (draft) |
| GET | `/merchants/{merchant_id}` | Profile |
| PATCH | `/merchants/{merchant_id}` | Update profile, branding, preferences |
| POST | `/merchants/{merchant_id}/submit` | Submit KYB |
| GET | `/merchants/{merchant_id}/status` | Status + gates |
| POST | `/merchants/{merchant_id}/activate` | Activate after approval |
| GET | `/merchants/search` | Ops / partner search (scoped) |

---

## Verification & documents

| Method | Path |
| --- | --- |
| POST | `/merchants/{merchant_id}/documents` |
| GET | `/merchants/{merchant_id}/documents` |
| POST | `/merchants/{merchant_id}/verification` |
| GET | `/merchants/{merchant_id}/verification` |

---

## Branches & org units

| Method | Path |
| --- | --- |
| POST | `/merchants/{merchant_id}/branches` |
| GET | `/merchants/{merchant_id}/branches` |
| GET | `/branches/{branch_id}` |
| PATCH | `/branches/{branch_id}` |
| POST | `/branches/{branch_id}/departments` |

---

## Devices

| Method | Path |
| --- | --- |
| POST | `/merchants/{merchant_id}/devices` |
| GET | `/merchants/{merchant_id}/devices` |
| POST | `/devices/{device_id}/activate` |
| POST | `/devices/{device_id}/revoke` |
| POST | `/devices/{device_id}/heartbeat` |

---

## Employees & roles

| Method | Path |
| --- | --- |
| POST | `/merchants/{merchant_id}/employees/invite` |
| GET | `/merchants/{merchant_id}/employees` |
| PATCH | `/merchants/{merchant_id}/employees/{employee_id}` |
| DELETE | `/merchants/{merchant_id}/employees/{employee_id}` |
| GET | `/merchants/{merchant_id}/roles` |
| POST | `/merchants/{merchant_id}/roles` (custom) |
| PUT | `/merchants/{merchant_id}/employees/{employee_id}/roles` |

---

## Settlement accounts (metadata)

| Method | Path |
| --- | --- |
| POST | `/merchants/{merchant_id}/settlement-accounts` |
| GET | `/merchants/{merchant_id}/settlement-accounts` |
| POST | `/settlement-accounts/{id}/verify` |

---

## Developer

| Method | Path |
| --- | --- |
| POST | `/merchants/{merchant_id}/api-keys` |
| GET | `/merchants/{merchant_id}/api-keys` |
| DELETE | `/api-keys/{key_id}` |
| POST | `/merchants/{merchant_id}/webhooks` |
| GET | `/merchants/{merchant_id}/webhooks` |
| PATCH | `/webhooks/{webhook_id}` |

---

## Analytics & reports (Phase 1 — merchant master data)

| Method | Path |
| --- | --- |
| GET | `/merchants/{merchant_id}/analytics/onboarding` |
| GET | `/merchants/{merchant_id}/reports/summary` |

*Payment/settlement analytics added Phase 2+ as read models.*

---

## Error model

```json
{
  "error": {
    "code": "merchant.invalid_state",
    "message": "Cannot activate merchant in status pending_kyb",
    "correlation_id": "uuid"
  }
}
```

---

## Architecture

API Gateway → ECS **merchant-service**; authZ middleware validates JWT + merchant RBAC.

---

## Events

Emit after successful commits — [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md).

---

## AWS architecture

[11_AWS_ARCHITECTURE.md](11_AWS_ARCHITECTURE.md)

---

## Security considerations

Rate limits per merchant tier; field-level auth on PII; no secrets in responses (API key shown once).

---

## Implementation strategy

Publish OpenAPI before coding; contract tests per endpoint group.

---

## Future expansion

GraphQL merchant portal BFF; bulk branch import.

---

## Cross-references

[14_API_CATALOG.md](../14_API_CATALOG.md) (TNPI program)
