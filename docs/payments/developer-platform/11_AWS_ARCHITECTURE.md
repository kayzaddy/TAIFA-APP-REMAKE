# 11 — AWS Architecture

---

## Executive summary

Production layout: **CloudFront** (portal), **Route53**, **API Gateway** (public + control), **ECS Fargate** (developer services, webhook workers), **Lambda** (authorizers, lightweight transforms), **EventBridge**, **SQS/SNS**, **RDS PostgreSQL**, **Redis**, **CloudWatch**, **CloudTrail**, **KMS**, **Secrets Manager**, **Backup**, **GuardDuty**, **Security Hub**.

---

## Business purpose

Scalable, secure edge with clear separation of sandbox and production.

---

## Architecture overview

```mermaid
flowchart TB
  R53[Route53]
  CF[CloudFront portal]
  APIGW[API Gateway]
  subgraph vpc [VPC]
    ECS_DP[ECS Developer control plane]
    ECS_WH[ECS Webhook delivery]
    RDS[(RDS)]
    REDIS[(Redis)]
  end
  R53 --> CF
  R53 --> APIGW
  APIGW --> LAM[Lambda authorizers]
  APIGW --> ECS_DP
  APIGW -->|proxy| INT[Internal ALB TNPI services]
  EB[EventBridge] --> SQS --> ECS_WH
  ECS_DP --> RDS
  ECS_WH --> RDS & REDIS
```

---

## API Gateway

| API | Purpose |
| --- | --- |
| `tnpi-public-prod` | `/v1/*` data plane |
| `tnpi-public-sandbox` | Sandbox stage |
| `tnpi-developer` | Control plane `/v1/developer`, apps, webhooks |

Usage plans + API keys mapped to application records.

---

## Developer Portal

S3 static + CloudFront; BFF on Fargate; WAF OWASP rules.

---

## Webhook plane

EventBridge rules per event type → enrichment Lambda → SQS per webhook → Fargate workers → partner HTTPS.

---

## Sequence: public API request

```mermaid
sequenceDiagram
  participant C as Client
  participant WAF as WAF
  participant G as API Gateway
  participant A as Authorizer
  participant U as Upstream orchestration
  C->>WAF: HTTPS
  WAF->>G: forward
  G->>A: validate key
  A-->>G: IAM policy context
  G->>U: proxy request
  U-->>G: response
  G-->>C: JSON
```

---

## Multi-account

| Account | Workload |
| --- | --- |
| TNPI prod | Gateway prod, portal prod |
| TNPI sandbox | Full sandbox stack |
| Security | Central logging |

---

## Observability (embedded)

CloudWatch metrics: `4xx`, `5xx`, latency, webhook success rate; X-Ray on gateway → upstream.

---

## DR

RDS Multi-AZ; webhook DLQ replay runbook; RPO 15m.

---

## Security

Private subnets; VPC endpoints; KMS CMK per env; Secrets Manager for signing keys.

---

## Implementation strategy

Terraform module `tnpi-developer-platform`; reuse Taifa Core network.

---

## Future expansion

AWS API Gateway developer portal feature evaluate vs custom portal (likely custom for national branding).

---

## Cross-references

[07_API_SECURITY.md](07_API_SECURITY.md) · [12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md)
