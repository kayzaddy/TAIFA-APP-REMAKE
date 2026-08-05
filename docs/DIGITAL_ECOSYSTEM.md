# Digital Ecosystem Platform

Taifa as Tanzania’s modular digital operating system: independent industry domains on shared platform services.

## Non-negotiables

Do **not** duplicate:

Identity · Wallet · Payments · Notifications · Registry · GIS · Reporting · Audit · AI · Documents · RBAC / ABAC · Workflow · Observability

New industries **consume** these services. Context map: [`platform/earb/02_ENTERPRISE_CONTEXT_MAP.md`](platform/earb/02_ENTERPRISE_CONTEXT_MAP.md) · Core build: [`platform/00_PLATFORM_OVERVIEW.md`](platform/00_PLATFORM_OVERVIEW.md).

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│  Super App (Flutter) — one account, enable modules          │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  Ecosystem control plane  /api/v1/ecosystem/                │
│  catalog · modules · workflows · AI · webhooks · open API   │
└───────────────────────────┬─────────────────────────────────┘
        ┌───────────────────┼───────────────────┐
        ▼                   ▼                   ▼
   Domain APIs         Shared services      Open platform
 Mobility trips      Identity/Payments     Partners/SDKs
 Commerce            Registry/GIS/AI       Webhooks
 Healthcare*         Enterprise RBAC       OpenAPI
 Agriculture         Workflow/Audit
 Education*          Notifications
 Government*
 Tourism*
 Logistics*
 Enterprise
```

\* Healthcare, education, government, tourism consumer surfaces currently live under `commerce` and/or dedicated Flutter routes; ecosystem catalog maps them as first-class domains.

## Domains (9)

| Domain | Code | Primary APIs |
| --- | --- | --- |
| Mobility | `mobility` | `/api/v1/trips/`, registry |
| Commerce | `commerce` | `/api/v1/commerce/` |
| Healthcare | `healthcare` | commerce health + emergency mobility |
| Agriculture | `agriculture` | `/api/v1/ecosystem/agriculture/` |
| Education | `education` | commerce education |
| Government | `government` | commerce gov + gov adapters |
| Tourism | `tourism` | commerce tourism |
| Logistics | `logistics` | trips logistics shipments |
| Enterprise | `enterprise` | `/api/v1/enterprise/` |

## Super App modules

`GET/POST /api/v1/ecosystem/modules` — per-principal enablement. Core modules (home, wallet, notifications, settings) stay on; industry modules are optional.

Flutter: **My Services** (`/my-services`), Home **Enable** tile, **Agriculture** (`/agriculture`).

## Workflow engine

Reusable engine remains `enterprise.workflow`. Ecosystem binds business processes:

- ride_approval · merchant_approval · hospital_registration  
- government_permit · driver_verification · business_verification  

`POST /api/v1/ecosystem/workflows/start` → advances via enterprise workflow instances.

## AI platform

`POST /api/v1/ecosystem/ai/{capability}/invoke`  
Capabilities: recommendations, fraud_detection, demand_prediction, voice_assistant, ocr, route_optimization, risk_analysis, smart_search.

Adapters via `TAIFA_AI_ADAPTERS_JSON`. Stub adapter is default; **never** mutates payment ledgers (fraud/risk are advisory).

## Open platform

| Surface | Path |
| --- | --- |
| Blueprint | `/api/v1/ecosystem/blueprint` |
| Open catalog | `/api/v1/ecosystem/open/catalog` |
| Webhooks | `/api/v1/ecosystem/webhooks/` |
| Partner apply | `/api/v1/ecosystem/partners/apply` |
| OpenAPI | `/api/schema` |
| SDKs | `packages/sdk-python`, `sdk-javascript`, `sdk-flutter` |

GraphQL is documented as planned; REST `/api/v1/` is authoritative.

## Seed

```bash
cd apps/backend
.\.venv\Scripts\python.exe manage.py seed_ecosystem
```

## Docs

- [`ECOSYSTEM_ARCHITECTURE.md`](ECOSYSTEM_ARCHITECTURE.md)
- [`ECOSYSTEM_DEPLOYMENT.md`](ECOSYSTEM_DEPLOYMENT.md)
- [`OPEN_PLATFORM.md`](OPEN_PLATFORM.md)
- [`PAN_AFRICAN_PLATFORM.md`](PAN_AFRICAN_PLATFORM.md) — multi-country expansion
