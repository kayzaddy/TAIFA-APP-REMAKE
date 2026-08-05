# AWS Account Register — Taifa Platform

**Status:** Template — fill during Sprint 0 task **S0-05**  
**Owner:** Platform Engineering Lead + Cloud Foundation team

---

## Organization

| Field | Value |
| --- | --- |
| AWS Organization ID | _TBD_ |
| Management account email | _TBD_ |
| Primary region | `af-south-1` |

---

## Organizational units

| OU | Purpose |
| --- | --- |
| `taifa-workloads-dev` | Developer sandboxes |
| `taifa-workloads-test` | CI integration |
| `taifa-workloads-staging` | Pre-production Core |
| `taifa-workloads-prod` | Production |
| `taifa-security` | Audit, log archive |
| `taifa-shared` | Terraform state, shared ECR |

---

## Accounts

| Alias | Account ID | OU | Notes |
| --- | --- | --- | --- |
| `taifa-dev` | _TBD_ | workloads-dev | |
| `taifa-test` | _TBD_ | workloads-test | |
| `taifa-staging` | _TBD_ | workloads-staging | Core integration target |
| `taifa-prod` | _TBD_ | workloads-prod | No traffic in S0 |
| `taifa-audit` | _TBD_ | security | Org CloudTrail |
| `taifa-shared` | _TBD_ | shared | State bucket S0-06 |

---

## IAM roles (GitHub OIDC)

| Role name | Account | Purpose | ARN |
| --- | --- | --- | --- |
| `TaifaGitHubTerraformPlan` | staging | PR terraform plan | _TBD_ |
| `TaifaGitHubDeployStaging` | staging | Deploy from `main` | _TBD_ |

---

## DNS

| Zone | Account | Notes |
| --- | --- | --- |
| _e.g. staging.taifa.go.tz_ | _TBD_ | Route 53 — task S0-13 |

---

## Sign-off

| Role | Name | Date |
| --- | --- | --- |
| Platform Lead | | |
| Security | | |
| DevOps | | |
