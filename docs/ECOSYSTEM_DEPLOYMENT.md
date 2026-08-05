# Ecosystem Deployment

Extends [`DEPLOYMENT.md`](DEPLOYMENT.md). Payments, Identity, Mobility, and Registry stay as deployed today.

## Add ecosystem app

1. Ensure `ecosystem.apps.EcosystemConfig` is in `INSTALLED_APPS`.
2. Migrate: `manage.py migrate taifa_ecosystem`
3. Seed: `manage.py seed_ecosystem`
4. Route mount: `/api/v1/ecosystem/`

## Kubernetes / containers

Same image as the API service. Scale web + Celery horizontally. No separate payment microservice is required for ecosystem routes.

Blue/green: deploy new API revision behind the existing ingress; run migrations in the release job before traffic switch.

## Multi-region

- Sticky identity/payments in the primary region (or global DB with regional replicas)
- Mobility/GIS and commerce data already carry `region` attributes for partitioning
- Ecosystem catalog is global reference data (small)

## Disaster recovery

Follow [`DISASTER_RECOVERY.md`](DISASTER_RECOVERY.md). Ecosystem tables are catalog + enablement + AI logs — rebuildable from seed + principal preferences backups.

## Environment

| Variable | Purpose |
| --- | --- |
| `TAIFA_AI_ADAPTERS_JSON` | Override AI adapter class paths |
| `MOBILITY_GOVERNMENT_ADAPTERS_JSON` | Authority adapters (mobility) |
