# Rollback — Staging (Taifa Core)

**Owner:** Platform Engineering / DevOps  
**Authority:** [SPRINT_0_ENGINEERING_PLAN.md](../SPRINT_0_ENGINEERING_PLAN.md) §14 · [12_CICD_PLATFORM.md](../12_CICD_PLATFORM.md)

---

## When to rollback

- Smoke tests fail after deploy (`/healthz` non-200, error rate spike).  
- Critical regression with no forward fix within SLA.  
- Bad migration already applied → prefer **forward fix**; rollback app only if DB compatible.

---

## Application rollback (ECS)

1. Identify previous task definition revision or image digest from ECR / ECS console.  
2. Update service to previous revision:
   - AWS Console: ECS → Service → Update → Task definition revision  
   - CLI: `aws ecs update-service --cluster <cluster> --service taifa-api --task-definition <family>:<prev-rev>`  
3. Wait for steady state; re-run smoke tests.  
4. Post incident note in `docs/platform/evidence/`.

**GitHub:** `rollback-staging.yml` (draft) — manual `workflow_dispatch` with `task_definition_revision` input.

---

## Database

- **Before deploy:** automated snapshot (staging) where RDS module enabled.  
- **Rollback:** do not restore snapshot without Platform Lead + DBA approval (data loss risk).  
- **Preferred:** ship forward migration `N+1` fixing bad state.

---

## Infrastructure (Terraform)

1. Checkout tag or commit known-good for `infra/envs/staging`.  
2. `terraform plan` → review → `terraform apply` with approved role.  
3. State history in S3 versioning if enabled.

---

## Feature flags

When platform feature flags are live, disable `core.<service>.*` before infra rollback if the incident is feature-specific.

---

## Contacts

Update on-call rotation in internal ops wiki; link here when defined.
