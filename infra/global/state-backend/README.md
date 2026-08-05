# Global: Terraform state backend

Apply once in the **taifa-shared** AWS account.

## Resources

- S3 bucket `taifa-terraform-state-<account_id>` (versioning, encryption, block public access)
- DynamoDB table `terraform-locks`
- IAM policy for CI/human `terraform plan/apply`

## Sprint 0 task

S0-06 — see [SPRINT_0_ENGINEERING_PLAN.md](../../docs/platform/SPRINT_0_ENGINEERING_PLAN.md).

Terraform implementation: add `main.tf` in this folder when account ID is known.
