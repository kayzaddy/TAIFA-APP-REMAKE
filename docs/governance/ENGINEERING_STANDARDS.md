# Engineering Standards

## Repository layout

```text
apps/backend/<app>/     # Django bounded context
apps/mobile/lib/features/<feature>/{domain,application,presentation,data}/
docs/                   # version-controlled truth
packages/sdk-*/         # thin SDKs
templates/golden-*/     # new service starters
docs/adr/               # decisions
```

## Naming

- Django apps: short nouns (`payments`, `trips`, `ai_os`, `continental`)
- API paths: kebab-case plural resources
- Events: `domain.action` (e.g. `workflow.completed`)
- Feature flags / env: `TAIFA_*` prefix

## Code review & PRs

- Use [`.github/PULL_REQUEST_TEMPLATE.md`](../../.github/PULL_REQUEST_TEMPLATE.md)
- Require: tests for behavior change, docs for public API, no secrets
- Money/identity PRs: Security Owner review
- Prefer small PRs; no force-push to `main`

## Configuration & secrets

- 12-factor env; never commit secrets
- Production gates refuse demo mint / weak webhook auth (see `PRODUCTION_GATE.md`)
- Adapter class paths via JSON env (`TAIFA_*_ADAPTERS_JSON`)

## Logging / metrics / tracing

- Structured logs with `X-Request-ID`
- Prometheus `/metrics`; OTEL when configured
- No PII to error trackers by default

## Feature flags

Use settings/env or ecosystem module enablement — not scattered `if DEBUG` product forks in production paths.

## Health

Every deployable exposes `/healthz`, `/readyz` (and startup/deps where applicable).

## Background jobs

Celery task names namespaced (`mobility.*`, `mobility.build_*`); idempotent where possible.

## Documentation

Public behavior change without docs update is incomplete. See [`DOCUMENTATION.md`](DOCUMENTATION.md).

## Golden templates

Start new services from [`templates/golden-django-service/`](../../templates/golden-django-service/README.md).
