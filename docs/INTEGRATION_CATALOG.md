# Taifa Integration Catalog

**Owner:** Platform Engineering / Integration Architecture  
**Audience:** SRE, DevSecOps, Identity, Payments, Government liaison  
**Related:** [INTEGRATION_CERTIFICATION_REPORT.md](./INTEGRATION_CERTIFICATION_REPORT.md), [P0_REMEDIATION_REPORT.md](./P0_REMEDIATION_REPORT.md)

---

## Principle

Every external dependency is reached through a **configurable production adapter**.  
Stubs and simulated rails are allowed only when `TAIFA_ALLOW_STUB_ADAPTERS=true` (DEBUG/tests).  
Production refuses stubs (`platform.E005`) and requires at least one live payment rail (`platform.E006`).

Runtime inventory: `GET /api/v1/integrations/catalog`  
Certification matrix: `GET /api/v1/integrations/certification`  
Health: `GET /api/v1/integrations/health`

---

## Inventory

| ID | Category | Adapter | Config | Owner |
| --- | --- | --- | --- | --- |
| payments.mpesa | payments | `payments.gateways.mpesa.MpesaGateway` | `MPESA_*` | payments-platform |
| payments.airtel | payments | `payments.gateways.airtel.AirtelMoneyGateway` | `AIRTEL_*` | payments-platform |
| payments.selcom | payments | `payments.gateways.selcom.SelcomGateway` | `SELCOM_*` | payments-platform |
| payments.card | payments | `payments.gateways.card_acquirer.CardGateway` | `CARD_ACQUIRER_*` | payments-platform |
| identity.federation | identity | `integrations.identity.HttpIdentityAdapter` | `TAIFA_IDENTITY_PROVIDERS_JSON` | identity-platform |
| ai.inference | ai | `integrations.ai.OpenAICompatibleInferenceAdapter` | `TAIFA_AI_PROVIDER_JSON` | ai-platform |
| government.authorities | government | `integrations.government.HttpGovernmentAdapter` | `TAIFA_GOVERNMENT_PROVIDERS_JSON` | gov-integrations |
| notify.sms | notifications | `integrations.notifications.HttpSmsAdapter` | `TAIFA_SMS_PROVIDER_JSON` | notifications |
| notify.email | notifications | `integrations.notifications.DjangoEmailAdapter` | `EMAIL_HOST` / SMTP | notifications |
| notify.push | notifications | `integrations.notifications.HttpPushAdapter` | `TAIFA_PUSH_PROVIDER_JSON` | notifications |
| docs.object_storage | documents | `integrations.storage.S3CompatibleStorage` | `TAIFA_OBJECT_STORAGE_JSON` | platform-storage |
| docs.malware_scan | documents | `integrations.scanner.HttpDocumentScanner` | `TAIFA_DOCUMENT_SCANNER_JSON` + `MOBILITY_DOCUMENT_SCANNER` | platform-security |
| maps.gis | gis | `integrations.maps.HttpMapsAdapter` | `TAIFA_MAPS_PROVIDER_JSON` | mobility-platform |
| events.outbox_webhooks | webhooks | `enterprise.event_bus` | `TAIFA_OUTBOX_WEBHOOK_URLS_JSON` | enterprise-events |

---

## Configuration guide

### Identity

```bash
TAIFA_IDENTITY_PROVIDERS_JSON='{"TZ.nida":{"base_url":"https://id.example.gov/api","api_key":"…","lookup_path":"/v1/citizens/lookup"}}'
```

### AI

```bash
TAIFA_AI_PROVIDER_JSON='{"base_url":"https://api.openai.com/v1","api_key":"…","model":"gpt-4o-mini","path":"/chat/completions"}'
```

### Government

```bash
TAIFA_GOVERNMENT_PROVIDERS_JSON='{"LATRA":{"base_url":"https://api.latra.example","api_key":"…","submit_path":"/v1/mobility/statistics"}}'
```

### Airtel / Selcom / Card

```bash
AIRTEL_CLIENT_ID=… AIRTEL_CLIENT_SECRET=… AIRTEL_BASE_URL=https://openapiuat.airtel.africa
SELCOM_API_KEY=… SELCOM_API_SECRET=… SELCOM_VENDOR=… SELCOM_BASE_URL=https://apigw.selcommobile.com
CARD_ACQUIRER_BASE_URL=… CARD_ACQUIRER_API_KEY=… CARD_ACQUIRER_MERCHANT_ID=…
```

### Notifications / Maps / Storage

```bash
TAIFA_SMS_PROVIDER_JSON='{"base_url":"https://sms.example","api_key":"…","send_path":"/v1/sms/send"}'
TAIFA_PUSH_PROVIDER_JSON='{"base_url":"https://push.example","api_key":"…"}'
TAIFA_MAPS_PROVIDER_JSON='{"base_url":"https://api.mapbox.com","api_key":"…","provider":"mapbox","geocode_path":"/geocoding/v5/mapbox.places/{query}.json","route_path":"/directions/v5/mapbox/driving/{coords}"}'
TAIFA_OBJECT_STORAGE_JSON='{"endpoint":"https://s3.example","region":"af-south-1","bucket":"taifa-docs","access_key":"…","secret_key":"…","path_style":true}'
```

---

## Reliability & security (all HTTP adapters)

| Control | Implementation |
| --- | --- |
| Timeout | `TAIFA_INTEGRATION_TIMEOUT_SECONDS` (default 15s) |
| Retries | Exponential backoff, `TAIFA_INTEGRATION_MAX_RETRIES` |
| Circuit breaker | `integrations.circuit.CircuitBreaker` per integration |
| TLS | Default `verify_tls=true` |
| Secrets | Env / JSON settings — never hardcoded provider secrets |
| Metrics | `taifa_integration_*` Prometheus series |
| Fail-closed | Missing config raises / omits rail; never silent stub in prod |

---

## Mobile note

Flutter mock maps/AI/payment gateways remain for **offline demo**. Production money and identity authority is the **backend**. Set `TAIFA_USE_REMOTE=true` for REST-backed domains. Client-side simulated rails must not be treated as production settlement.

---

## Runbooks (short)

| Failure | Recovery |
| --- | --- |
| Circuit open | Wait recovery window; check upstream health; drain backlog |
| Payment NOT_CONFIGURED | Supply rail credentials; restart workers; confirm `platform.E006` clear |
| Identity/Gov RuntimeError | Populate provider JSON; verify TLS + credentials with sandbox first |
| Outbox not publishing | Set `TAIFA_OUTBOX_WEBHOOK_URLS_JSON`; ensure Celery not eager |
| Document scan refused | Configure `MOBILITY_DOCUMENT_SCANNER=integrations.scanner.HttpDocumentScanner` |
