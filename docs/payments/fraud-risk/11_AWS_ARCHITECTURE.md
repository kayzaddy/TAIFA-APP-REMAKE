# 11 — AWS Architecture

---

## Executive summary

Production AWS layout for FRP: API Gateway, ECS Fargate (assess + admin), Lambda (enrichers), Step Functions (batch TM), RDS PostgreSQL, Redis, SQS/SNS, EventBridge, CloudWatch, CloudTrail, KMS, Secrets Manager, Backup, GuardDuty, Security Hub.

---

## Business purpose

Horizontally scalable, low-latency assess path with isolated control plane and clear blast radius.

---

## Architecture overview

```mermaid
flowchart TB
  subgraph edge [Edge]
    APIGW[API Gateway + WAF]
  end
  subgraph compute [Compute]
    ECS_A[ECS Fargate Assess]
    ECS_O[ECS Fargate Ops API]
    LAM[Lambda enrichers]
    SF[Step Functions batch TM]
  end
  subgraph data [Data]
    RDS[(RDS PostgreSQL)]
    REDIS[(ElastiCache Redis)]
    S3[(S3 evidence)]
  end
  subgraph messaging [Messaging]
    EB[EventBridge]
    SQS[SQS]
    SNS[SNS alerts]
  end
  APIGW --> ECS_A
  APIGW --> ECS_O
  EB --> LAM --> SQS --> ECS_O
  ECS_A --> RDS & REDIS
  ECS_O --> RDS & S3
  SF --> RDS
  ECS_A --> EB
  SNS --> Ops[PagerDuty email]
```

---

## Sync assess path

API Gateway → VPC Link → Fargate assess service (auto-scaling on CPU + p99 latency); Redis for velocity; RDS write assessment async buffer optional (SQS) if spike.

---

## Async path

`payment.*` rules on EventBridge → SQS → Fargate workers; DLQ + alarm.

---

## Sequence: assess at scale

```mermaid
sequenceDiagram
  participant O as Orchestration
  participant GW as API Gateway
  participant ECS as Fargate Assess
  participant R as Redis
  participant D as RDS
  O->>GW: assess
  GW->>ECS: route
  ECS->>R: incr velocity
  ECS->>D: insert assessment
  ECS-->>O: decision
```

---

## Multi-account

| Account | Workloads |
| --- | --- |
| TNPI prod | FRP prod |
| TNPI staging | FRP staging |
| Security | CloudTrail aggregation |

---

## DR

RDS cross-region read replica; RTO 4h / RPO 15m targets; runbook in Taifa Core.

---

## Secrets

PSP intel API keys, internal JWT signing — Secrets Manager rotation.

---

## Observability

CloudWatch metrics, X-Ray on assess path, log insights — [12_OBSERVABILITY.md](12_OBSERVABILITY.md).

---

## Security

Private subnets; SG least privilege; KMS CMK per env.

---

## Implementation strategy

Terraform module `tnpi-fraud-risk`; reuse Taifa Core VPC from Sprint 0.

---

## Future expansion

SageMaker in ML account; VPC endpoints for S3/DynamoDB.

---

## Cross-references

[02_RISK_ENGINE.md](02_RISK_ENGINE.md) · [10_SECURITY_MODEL.md](10_SECURITY_MODEL.md)
