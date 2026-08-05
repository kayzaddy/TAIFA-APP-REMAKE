# AI OS Deployment

Extends [`DEPLOYMENT.md`](DEPLOYMENT.md) and [`ECOSYSTEM_DEPLOYMENT.md`](ECOSYSTEM_DEPLOYMENT.md).

## Install

1. `INSTALLED_APPS` includes `ai_os.apps.AiOsConfig`
2. `manage.py migrate taifa_ai_os`
3. `manage.py seed_ai_os`
4. Mount: `/api/v1/ai-os/`

## Hybrid inference

| Mode | Config |
| --- | --- |
| Stub (default) | `ai_os.adapters.StubInferenceAdapter` |
| Cloud / on-prem | `TAIFA_AI_OS_ADAPTERS_JSON={"taifa-nlp-stub":"myapp.adapters.CloudNlp"}` |

Model registry `deployment` field documents intended topology (`cloud|onprem|hybrid`). Rollback uses `rollback_to` version labels when promoting canaries.

## Scaling

- Stateless API workers for `/infer` and `/agents/*/run`
- Async: push heavy jobs to Celery (same pattern as national metrics)
- GPU schedulers attach behind adapter classes — gateway contract unchanged
- HA: multiple API replicas; Postgres for decisions/metrics; Redis optional for future rate limits

## Security

- Device auth on all endpoints
- Webhook/API keys for partners remain outside model weights
- Embeddings and knowledge bodies inherit existing DB encryption/at-rest posture
- Never log raw secrets in prompts — PII redaction runs pre-inference

## Observability

- Command center: `/api/v1/ai-os/command-center`
- Platform probes: `/healthz`, `/readyz`, `/metrics`
- Daily rollups: `InferenceMetricDaily`
