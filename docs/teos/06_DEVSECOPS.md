# 06 — DevSecOps

**Owner:** DevSecOps Director

---

## CI (GitHub Actions)

| Workflow | Trigger | Gates |
| --- | --- | --- |
| `ci-pr` | PR | Lint, unit tests, path filters |
| `security-scan` | PR + schedule | SAST, secrets, deps |
| `contract-check` | `apis/` change | OpenAPI diff |
| `iac-plan` | `infrastructure/` | Terraform plan comment |

Reference: [taifa-platform DEVSECOPS](../../taifa-platform/docs/governance/DEVSECOPS.md).

---

## CD

Stages: **build → scan → staging → E2E → approval → canary → prod**

- OIDC to AWS; no long-lived keys  
- Immutable container tags: `taifa/{service}:{semver}-{sha}`  
- ECR per environment

---

## Artifacts

| Type | Store |
| --- | --- |
| Containers | Amazon ECR |
| Mobile | Signed builds (CI) |
| Terraform | Versioned modules + S3 state (locked) |

---

## Terraform standards

- Modules under `infrastructure/terraform/modules/`  
- `terraform fmt` + Checkov/tfsec in CI  
- No manual prod changes without CAB (payments/identity)

---

## Deployment strategies

| Strategy | Use |
| --- | --- |
| **Rolling** | Default ECS |
| **Blue-green** | High-risk migrations |
| **Canary** | 5% → 25% → 100% with metric gates |
| **Feature flags** | Product toggles; kill switch for payments |

---

## Rollback

1. Revert ECS task definition / Helm revision  
2. Disable feature flag  
3. Forward-fix DB migration if needed

---

## Release automation

Tags `v*` trigger `release.yml`; changelog from Conventional Commits.

---

## Cross-references

[governance/DEVSECOPS.md](../governance/DEVSECOPS.md) · [10_RELEASE_MANAGEMENT.md](10_RELEASE_MANAGEMENT.md)
