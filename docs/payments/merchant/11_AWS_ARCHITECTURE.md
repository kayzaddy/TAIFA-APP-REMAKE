# 11 — AWS Architecture (Merchant Platform)

**Region:** `af-south-1` · Accounts: staging / prod per [SPRINT_0](../../platform/SPRINT_0_ENGINEERING_PLAN.md)

---

## Executive summary

Production deployment of Merchant Platform on AWS: API Gateway, ECS Fargate, Lambda (document scan), RDS PostgreSQL, Redis, S3, CloudFront (portal), IAM, KMS, Secrets Manager, observability, EventBridge, backup, and security services.

---

## Business purpose

Scalable, Well-Architected hosting for national merchant registry workloads.

---

## Architecture diagram

```mermaid
flowchart TB
  subgraph edge [Edge]
    CF[CloudFront - Merchant Portal]
    WAF[WAF]
    APIGW[API Gateway HTTP]
  end
  subgraph compute [Compute]
    ECS[ECS Fargate - merchant-service]
    LAM[Lambda - doc scan / virus]
  end
  subgraph data [Data]
    RDS[(RDS PostgreSQL merchant schema)]
    REDIS[(ElastiCache Redis)]
    S3[S3 - KYB documents]
  end
  subgraph events [Events]
    EB[EventBridge]
    SQS[SQS workers]
    SNS[SNS alerts]
  end
  subgraph sec [Security]
    KMS[KMS]
    SM[Secrets Manager]
    CT[CloudTrail]
    GD[GuardDuty]
    SH[Security Hub]
    BK[AWS Backup]
  end
  CF --> APIGW
  WAF --> APIGW
  APIGW --> ECS
  ECS --> RDS & REDIS & S3 & SM
  ECS --> EB
  S3 --> LAM
  EB --> SQS
  KMS --> RDS & S3
  BK --> RDS
```

---

## Service sizing (initial)

| Component | Staging | Prod (pilot) |
| --- | --- | --- |
| ECS tasks | 2 × 0.5 vCPU | 3+ × 1 vCPU |
| RDS | db.t4g.medium | db.r6g.large Multi-AZ |
| Redis | cache.t4g.small | cache.r6g.large |

---

## IAM

- Task role: RDS, S3 prefix `merchant-docs/*`, Secrets Manager read, EventBridge publish.
- No task role access to payment orchestration resources in Phase 1.

---

## Sequence: document upload

```mermaid
sequenceDiagram
  participant C as Client
  participant API as API GW
  participant E as ECS
  participant S3 as S3
  participant L as Lambda
  C->>API: POST presign request
  API->>E: issue presigned URL
  C->>S3: PUT document
  S3->>L: scan
  L->>E: mark document clean
```

---

## Domain model / API / events

Hosted by ECS — see sibling docs.

---

## Security considerations

Private subnets; VPC endpoints; WAF rate limits on `/merchants`.

---

## Implementation strategy

Terraform module `tnpi-merchant` (future) in `infra/`; deploy staging first.

---

## Future expansion

OpenSearch for merchant search; multi-region read replica for portal.

---

## Cross-references

[11_AWS_ARCHITECTURE.md](../11_AWS_ARCHITECTURE.md) (TNPI program)
