# Platform Engineering

Internal developer platform goals: **golden paths**, less toil, consistent delivery.

## Surfaces

| Surface | Location / plan |
| --- | --- |
| Developer docs | `docs/`, OpenAPI `/api/docs` |
| Service catalog | Ecosystem blueprint + Ownership matrix |
| API catalog | Spectacular `/api/schema` |
| SDKs | `packages/sdk-python`, `sdk-javascript`, `sdk-flutter` |
| CI | `.github/workflows/ci.yml` |
| Golden service | `templates/golden-django-service/` |
| Local backend | `apps/backend` venv + `manage.py runserver` |
| Compose | `docker-compose.yml` / `docker-compose.prod.yml` |

## Templates to evolve

- Kubernetes Deployment/Service/HPA (infra module — TBD under `infra/` when clusterized)
- Terraform modules for Postgres/Redis/object storage (same)
- Container base image standards: non-root, read-only FS where possible, SBOM in CI

## Onboarding checklist

1. Read [`GOVERNANCE.md`](../GOVERNANCE.md) + [`ENGINEERING_CULTURE.md`](ENGINEERING_CULTURE.md)  
2. Clone monorepo; backend venv; Flutter SDK  
3. Run `manage.py test` + `flutter analyze`  
4. Seed ecosystem / AI OS / continental as needed  
5. Pair on first PR using PR template  

## CLI / automation

Prefer `manage.py` commands (`seed_*`) and documented curl probes over one-off scripts. Platform CLIs may wrap these later without changing APIs.
