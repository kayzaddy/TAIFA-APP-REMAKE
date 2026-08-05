# Integration Production Certification Report

**Date:** 2026-07-18  
**Role:** Independent Production Certification Team  
**Scope:** Replace stub/simulated/placeholder integrations with production-grade adapters  
**Constraint:** No business-domain redesign

---

## Verdict

**Question:** Can every external dependency of Taifa operate safely, reliably, securely, and observably in production?

**Answer: No** — national certification remains **NO-GO** until operator credentials are installed for identity, government, AI, notifications, maps, and secondary payment rails.

**Controlled payments pilot:** **CONDITIONAL GO** when all of the following hold:

1. `DEBUG=false`, Postgres, Redis cache, non-eager Celery  
2. `TAIFA_ALLOW_STUB_ADAPTERS=false`  
3. At least one live payment rail configured (`MPESA_*` recommended)  
4. Outbox webhook consumers configured for partner delivery  

Evidence API: `GET /api/v1/integrations/certification`

---

## What was delivered (evidence)

| Workstream | Evidence |
| --- | --- |
| Shared adapter kit | `apps/backend/integrations/http_client.py`, `circuit.py`, `metrics.py` |
| Identity HTTP adapter | `integrations/identity.py` + continental resolver fail-closed |
| AI OpenAI-compatible adapter | `integrations/ai.py` + AI OS / ecosystem stub ban |
| Government HTTP adapters | `integrations/government.py` + stub ban in `trips.adapters.government` |
| Notifications | `integrations/notifications.py` + mobility fan-out hook |
| Object storage + AV scanner | `integrations/storage.py`, `scanner.py` |
| Maps / GIS | `integrations/maps.py` |
| Live Airtel / Selcom / Card | `payments/gateways/airtel.py`, `selcom.py`, `card_acquirer.py` |
| Simulated rails banned in prod | `payments/gateways/factory.py` + `platform.E006` |
| Catalog + certification | `integrations/catalog.py`, `certification.py`, API routes |
| Docs | `docs/INTEGRATION_CATALOG.md` (this report) |
| Tests | `integrations/tests/test_integrations.py` |

---

## Certification matrix (runtime)

Statuses are **evidence-based** from configuration at process start — not aspirational.

| Integration | Production | Security | Reliability | Observability | Docs | Risk | Certification |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Stub policy | PASS only if stubs denied | PASS | N/A | PASS | PASS | low/critical | CERTIFIED iff deny |
| M-Pesa | PASS iff credentials | PASS iff live | PASS iff live | PASS | PASS | med | CERTIFIED iff configured |
| Airtel / Selcom / Card | FAIL until credentials | FAIL | FAIL | PASS | PASS | high | NOT_CERTIFIED until configured |
| Identity / AI / Government | FAIL until provider JSON | FAIL | FAIL | PASS | PASS | high | NOT_CERTIFIED until configured |
| SMS / Push / Maps / Storage | FAIL until provider JSON | FAIL | FAIL | PASS | PASS | medium | NOT_CERTIFIED until configured |
| Outbox webhooks | FAIL until URL list | PASS path exists | PASS path exists | PASS | PASS | medium | NOT_CERTIFIED until consumers |

Exact live matrix: call the certification endpoint in the target environment.

---

## Remaining uncertified — actionable remediation

| Gap | Remediation |
| --- | --- |
| Identity stub / disabled | Obtain NIDA (or federation) API access; set `TAIFA_IDENTITY_PROVIDERS_JSON`; smoke-test `lookup` |
| Government stubs | Obtain LATRA/TRA/… endpoints; set `TAIFA_GOVERNMENT_PROVIDERS_JSON` per authority |
| AI stub | Provision OpenAI-compatible or on-prem LLM; set `TAIFA_AI_PROVIDER_JSON`; map models in `TAIFA_AI_OS_ADAPTERS_JSON` |
| Airtel / Selcom / Card | Complete merchant onboarding; set env credentials; sandbox charge + webhook |
| SMS / Push | Contract aggregator / FCM; set provider JSON |
| Maps | Mapbox/Google/OSRM keys; set `TAIFA_MAPS_PROVIDER_JSON`; replace Flutter mock gateways for prod builds |
| Object storage + AV | MinIO/S3 + scanner; set storage + `MOBILITY_DOCUMENT_SCANNER` |
| Outbox consumers | Publish partner webhook URLs + shared secret |
| Mobile mocks | Prod flavor: remote repositories only; no client-side settlement |

---

## Security / reliability / observability checklist

- [x] TLS + certificate validation on HTTP adapters  
- [x] Secrets via environment (no hardcoded provider secrets)  
- [x] Retries + circuit breaker + timeouts  
- [x] Prometheus metrics (`taifa_integration_*`)  
- [x] Production stub ban (identity, AI, government, simulated payments)  
- [x] Fail-closed when unconfigured in production  
- [ ] Operator-run sandbox contract tests against live providers (per environment)  
- [ ] Chaos / load evidence for each rail (SRE drill)  

---

## Independent certification statement

No integration is marked **CERTIFIED** without configuration evidence.  
Adapter *code* is production-grade and fail-closed; **operator credentials** are still required for national GO.

Until those credentials land, the honest answer remains **No**.
