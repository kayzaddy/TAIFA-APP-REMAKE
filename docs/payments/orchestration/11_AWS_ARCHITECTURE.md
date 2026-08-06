# 11 — AWS Architecture

---

## Executive summary

Production orchestration on API Gateway, ECS Fargate, Step Functions, Lambda, RDS, Redis, EventBridge, SQS/SNS, X-Ray, security & backup services.

---

## Business purpose

Scale to millions of tx/month with HA and observability.

---

## Component diagram

```mermaid
flowchart TB
  subgraph edge [Edge]
    APIGW[API Gateway]
    WAF[WAF]
  end
  subgraph compute [Compute]
    ECS[ECS orchestration-service]
    SF[Step Functions sagas]
    LAM[Lambda webhooks sweepers]
  end
  subgraph data [Data]
    RDS[(RDS orchestration)]
    REDIS[(Redis idempotency router cache)]
  end
  subgraph msg [Messaging]
    EB[EventBridge]
    SQS[SQS retry DLQ]
    SNS[SNS alerts]
  end
  subgraph o11y [Observability]
    CW[CloudWatch]
    XR[X-Ray]
    CT[CloudTrail]
  end
  WAF --> APIGW --> ECS
  ECS --> RDS & REDIS & EB
  ECS --> SF
  SQS --> LAM --> ECS
  ECS --> XR
```

---

## Sequence: async pending payment

```mermaid
sequenceDiagram
  participant PSP as PSP Webhook
  participant L as Lambda
  participant ECS as Orchestrator
  PSP->>L: callback
  L->>ECS: complete pending
  ECS->>EB: payment.completed
```

---

## Sizing (pilot prod)

| Resource | Initial |
| --- | --- |
| ECS | 6 tasks × 1 vCPU |
| RDS | db.r6g.xlarge Multi-AZ |
| Redis | cluster mode enabled at scale |

---

## Security / observability

[10](10_SECURITY_MODEL.md) · [12](12_OBSERVABILITY.md)

---

## Operational considerations

Multi-AZ; autoscale on CPU and queue depth.

---

## Implementation strategy

IaC module `tnpi-orchestration`.

---

## Future expansion

Multi-region active-passive.

---

## Cross-references

[11_AWS_ARCHITECTURE.md](../11_AWS_ARCHITECTURE.md)
