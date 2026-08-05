# Taifa Infrastructure (Terraform)

**Region:** `af-south-1` (primary)  
**Law:** [docs/platform/13_INFRASTRUCTURE_PLATFORM.md](../docs/platform/13_INFRASTRUCTURE_PLATFORM.md) · [SPRINT_0_ENGINEERING_PLAN.md](../docs/platform/SPRINT_0_ENGINEERING_PLAN.md)

---

## Layout

```
infra/
├── global/
│   ├── state-backend/     # S3 + DynamoDB for Terraform state (shared account)
│   └── github-oidc/       # GitHub Actions OIDC provider + IAM roles
├── modules/
│   ├── vpc/
│   ├── iam/
│   ├── kms/
│   ├── secrets/
│   ├── s3/
│   ├── ecs/
│   ├── rds/
│   ├── redis/
│   ├── eventbridge/
│   ├── cloudfront/
│   └── api-gateway/
└── envs/
    ├── dev/
    ├── test/
    ├── staging/
    └── prod/
```

---

## State & backends

1. Bootstrap `global/state-backend` in the **shared** AWS account.  
2. Copy `backend.tf.example` → `backend.tf` per environment (never commit secrets).  
3. State key: `env/<environment>/terraform.tfstate`.

---

## Module wiring (staging target)

| Module | Purpose |
| --- | --- |
| `vpc` | 3 AZ, public/private/isolated subnets, NAT, endpoints |
| `iam` | ECS task roles, GitHub OIDC roles |
| `kms` | CMK per environment |
| `secrets` | Secrets Manager patterns for RDS/app |
| `s3` | App buckets, logs |
| `ecs` | Fargate cluster, services, ALB target groups |
| `rds` | PostgreSQL Multi-AZ (staging+) |
| `redis` | ElastiCache |
| `eventbridge` | Custom bus `taifa-platform` |
| `cloudfront` | CDN (assets) |
| `api-gateway` | HTTP API v2 (phase 2 edge) |

**Sprint 0:** Modules contain README + minimal Terraform stubs; `terraform validate` only. Resource `apply` begins after account register (A1) and OIDC (A2).

---

## Commands

```bash
cd infra/envs/staging
terraform init -backend=false   # local validate without remote state
terraform validate
terraform fmt -check -recursive ..
```

CI runs validate on all env folders via [.github/workflows/iac.yml](../.github/workflows/iac.yml).

---

## Accounts

Document live account IDs in [docs/platform/evidence/aws-account-register.md](../docs/platform/evidence/aws-account-register.md).
