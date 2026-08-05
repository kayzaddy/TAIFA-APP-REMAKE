# Global: GitHub OIDC → AWS IAM

Configure in each workload account (or shared for ECR-only):

1. IAM OIDC identity provider for `token.actions.githubusercontent.com`
2. Role `TaifaGitHubTerraformPlan` — `plan` on PR
3. Role `TaifaGitHubDeployStaging` — `apply` + ECS deploy on `main`
4. Trust policy: restrict to `repo:ORG/TAIFA-APP-REMAKE:*` and branch/environment

## Sprint 0 task

S0-07 — document role ARNs in [aws-account-register.md](../../docs/platform/evidence/aws-account-register.md).
