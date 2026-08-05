# Continental Deployment

## Install

1. `continental.apps.ContinentalConfig` in `INSTALLED_APPS`
2. `manage.py migrate taifa_continental`
3. `manage.py seed_continental`
4. Mount `/api/v1/continental/`

## Topology

| Pattern | Use |
| --- | --- |
| Regional Kubernetes clusters | Map to `data_region` (eastafrica-tz, …) |
| Multi-cloud / hybrid | API stateless; DB residency per policy |
| On-prem / edge | Government or bank private instances consuming same APIs |
| Offline-first mobile | Existing device session + sync; country pack cached |

## Global ops

Flutter **Continental Ops** (`/continental-ops`) and `GET /api/v1/continental/ops-center` for country dashboards and SLO targets.

## DR

Follow [`DISASTER_RECOVERY.md`](DISASTER_RECOVERY.md). Country backups use `DataResidencyPolicy.backup_region`. Cross-border processing remains off by default.
