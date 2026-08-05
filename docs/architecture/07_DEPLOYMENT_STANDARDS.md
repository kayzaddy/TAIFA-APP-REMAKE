# 07 — Deployment Standards

**Purpose:** Define environments, delivery pipeline, and operational deployment conventions.  
**Scope:** AWS workloads, CI/CD, mobile release trains, infrastructure as code.  
**Principles:** Repeatable, reversible, observable deployments.

---

## Environments

| Env | Purpose | Data |
| --- | --- | --- |
| **Development** | Engineer local + shared dev | Synthetic / anonymized |
| **Testing** | Automated CI, integration | Fixtures, reset nightly |
| **Staging** | Pre-prod validation, demos | Masked copy or subset |
| **Production** | Citizens & partners | Real; strict change control |

No production credentials in dev laptops; use SSO and short-lived tokens.

---

## CI/CD

- **CI:** lint, unit tests, OpenAPI diff, migration check, security scan (SAST/dependency).  
- **CD:** staging auto on main; production manual approval + Change Advisory for tier-1.  
- **Artifacts:** Immutable container images tagged with git SHA.

```mermaid
flowchart LR
  PR[Pull Request] --> CI[CI pipeline]
  CI --> STG[Deploy Staging]
  STG --> APP[Approval]
  APP --> PRD[Deploy Production]
  PRD --> MON[Smoke + SLO check]
```

---

## Git strategy

- Trunk-based development; short-lived feature branches.  
- Conventional commits encouraged; no force-push to `main`.  
- Release tags `v{semver}` for mobile store and public API baselines.

---

## Release strategy

- **Backend:** rolling deploy on ECS; blue/green for high-risk Pay migrations.  
- **Mobile:** staged rollout %; feature flags for cross-domain features.  
- **Database:** migrations run before traffic shift (expand-contract).

---

## Rollback strategy

- Container: revert to previous task definition (&lt; 15 min target).  
- DB: forward-fix preferred; rollback migration only if tested.  
- Feature flags: disable without redeploy.

---

## Infrastructure as Code

- Terraform or CDK in repo; no click-ops production changes.  
- Modules per environment; state locked; peer review on IAM changes.

---

## Monitoring & observability

- CloudWatch dashboards per domain; SLO burn alerts.  
- X-Ray service map; log aggregation with correlation id search.  
- On-call rotation per [`../ONCALL.md`](../ONCALL.md).

---

## AWS deployment conventions

| Concern | Standard |
| --- | --- |
| Region | Primary `af-south-1`; DR per ADR |
| Compute | ECS Fargate for APIs; Lambda for event projectors |
| API edge | API Gateway + CloudFront + WAF |
| Data | RDS Multi-AZ, ElastiCache, S3 |
| Events | EventBridge + SQS DLQ |
| Secrets | Secrets Manager + KMS |
| Backup | AWS Backup policies per [04_DATABASE_STANDARDS.md](04_DATABASE_STANDARDS.md) |

---

## Cross-references

- [`../DEPLOYMENT.md`](../DEPLOYMENT.md)  
- [`../governance/DEVSECOPS.md`](../governance/DEVSECOPS.md)  
- [`../tourism/15_AWS_DEPLOYMENT.md`](../tourism/15_AWS_DEPLOYMENT.md)

---

## Future considerations

- GitOps (Argo CD) for multi-cluster  
- Canary analysis automated via CloudWatch metrics  
- Environment promotion gates tied to [09_DEFINITION_OF_DONE.md](09_DEFINITION_OF_DONE.md)
