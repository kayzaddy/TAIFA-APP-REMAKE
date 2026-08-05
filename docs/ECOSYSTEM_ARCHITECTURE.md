# Ecosystem Architecture

## Design for decades

Taifa is a **reusable national digital platform**, not a collection of apps. Domains are modular; foundations are shared and versioned.

## Shared service ownership

| Service | Authoritative owner | Consumers |
| --- | --- | --- |
| Identity / device auth | `payments.auth` | All APIs |
| Payments / Wallet | `payments` | All money movement |
| Financial ops / RBAC / Workflow | `enterprise` | Merchants, treasury, ecosystem bindings |
| Mobility / GIS analytics | `trips` | Ride, logistics, emergency, national ops |
| Registry / Documents | `mobility_registry` | Driver/vehicle/station eligibility |
| Ecosystem catalog / Super App / AI contracts | `ecosystem` | All domains + partners |
| Commerce verticals | `commerce` | Food, health, edu, gov, tourism, … |

## Integration rule

A new industry must:

1. Register in `ecosystem.catalog` (domain + modules + required_services).
2. Call Identity for auth and Payments for money.
3. Bind approvals to `enterprise.workflow` via `EcosystemWorkflowBinding`.
4. Emit side effects through the event outbox / webhooks — never fork ledgers.
5. Expose domain APIs under `/api/v1/<domain>/` or extend an existing bounded context.

## Security (Zero Trust posture)

- Device-bound bearer tokens
- Enterprise RBAC + rules (ABAC-style)
- Payments risk engine remains authoritative for money risk
- Webhook secrets hashed; raw shown once
- AI outputs advisory only

## Observability

Probes: `/healthz`, `/readyz`, `/startupz`, `/depsz`, `/metrics`  
Ecosystem snapshot: `GET /api/v1/ecosystem/observability`

## Deployment

Containers + horizontal API/Celery workers; blue/green via existing compose/K8s path documented in [`DEPLOYMENT.md`](DEPLOYMENT.md) and [`ECOSYSTEM_DEPLOYMENT.md`](ECOSYSTEM_DEPLOYMENT.md). Multi-region: partition by region attributes already present on mobility/commerce entities; shared identity/payments remain global.
