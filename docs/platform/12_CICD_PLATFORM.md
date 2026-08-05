# 12 — CI/CD Platform

**Bounded context:** `platform.devops`  
**Phase 1:** Pipelines, quality gates, staged deploy

---

## Purpose & business value

**Safe, repeatable** delivery of Taifa Core to staging/production with tests, OpenAPI checks, security scans, and rollback.

---

## Responsibilities

Git strategy · PR pipelines · artifact build (ECR) · IaC validate · deploy staging/prod · blue/green or rolling · rollback · environment promotion.

---

## Git strategy

Trunk-based `main`; short-lived `feature/*`; release tags `core-v*`; no force-push main.

---

## Pipelines (target)

| Workflow | Trigger | Steps |
| --- | --- | --- |
| `ci.yml` | PR/push | check, test, OpenAPI diff, spectral |
| `iac.yml` | PR | terraform validate, tflint |
| `deploy-staging.yml` | main / dispatch | build image, migrate, ECS deploy, smoke |
| `contract-tests.yml` | nightly | staging API contracts |

**Today:** [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) — extend per [14](14_PLATFORM_IMPLEMENTATION_GUIDE.md).

---

## Quality gates

- All tests pass  
- `spectacular --fail-on-warn`  
- Production `manage.py check` gates (E002–E006) in prod-like job  
- DoD checklist on PR template  
- No merge with High security findings (future: blocking pip-audit)

---

## Deployment

ECS rolling update; migration job before traffic; **blue/green** for Pay-critical releases (Phase 1b).

---

## Rollback

Revert ECS task definition to previous digest; forward-fix DB preferred.

---

## AWS

ECR · ECS · CodeDeploy (optional) · GitHub Actions OIDC → IAM role.

---

## Monitoring

Pipeline failure SNS; deployment annotations in dashboards.

---

## Roadmap

GitOps (Argo) · canary analysis · SBOM attestation
