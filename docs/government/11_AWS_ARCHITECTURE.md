# 11 — AWS Architecture

---

## Executive summary

GDSP production on AWS: **CloudFront** portal, **Route53**, **API Gateway**, **ECS Fargate**, **Lambda**, **Step Functions** (workflows), **EventBridge**, **SQS/SNS**, **RDS PostgreSQL**, **Redis**, **S3**, **CloudWatch**, **CloudTrail**, **KMS**, **Backup**, **GuardDuty**, **Security Hub**.

---

## Business purpose

Multi-tenant national scale with agency isolation and DR.

---

## Architecture overview

```mermaid
flowchart TB
  CF[CloudFront gov portal]
  APIGW[API Gateway]
  subgraph ecs [ECS Fargate]
    CAT[Catalog]
    APP[Applications]
    WF[Workflow workers]
    DOC[Documents BFF]
    AI[AI BFF]
  end
  SF[Step Functions]
  EB[EventBridge]
  RDS[(RDS)]
  S3[(S3 docs)]
  REDIS[(Redis)]
  APIGW --> ecs
  WF --> SF
  ecs --> RDS & S3 & REDIS
  ecs --> EB
```

---

## Multi-tenancy

`organization_id` partition; optional dedicated VPC per high-security agency (courts).

---

## TNPI / Identity

PrivateLink or VPC peering to platform services; no public TNPI keys in GDSP.

---

## Sequence: document upload

```mermaid
sequenceDiagram
  participant U as User
  participant D as Doc API
  participant S3 as S3
  participant L as Lambda scan
  U->>D: presigned upload
  U->>S3: PUT
  S3->>L: scan
  L->>D: clean metadata
```

---

## DR

Multi-AZ; cross-region backup; RPO 15m government target.

---

## Operational considerations

Cost allocation tags per agency; autoscale on tax season.

---

## Implementation strategy

Terraform `taifa-government`; landing zone from Taifa Core.

---

## Future expansion

Air-gapped disaster recovery site.

---

## Cross-references

[12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md)
