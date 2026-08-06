# 12 — AWS Architecture

---

## Executive summary

Production TNMP on AWS: **CloudFront**, **Route53**, **API Gateway**, **ECS Fargate** domain services, **Lambda** ingest, **Step Functions** incident workflows, **EventBridge**, **SQS/SNS**, **RDS PostgreSQL** + PostGIS, **Redis**, **Location Service**, **CloudWatch**, **CloudTrail**, **KMS**, **Backup**.

---

## Business purpose

Scale from one city to nationwide + future smart-city ingest.

---

## Architecture overview

```mermaid
flowchart TB
  CF[CloudFront apps]
  R53[Route53]
  APIGW[API Gateway]
  subgraph ecs [ECS Fargate]
    PAX[Passenger BFF]
    NET[Network]
    FLT[Fleet RT]
    OPS[Ops incidents]
    GOV[Gov analytics]
    AI[AI BFF]
  end
  EB[EventBridge]
  RDS[(RDS PostGIS)]
  REDIS[(Redis geo)]
  LOC[Location Service]
  APIGW --> ecs
  ecs --> RDS & REDIS & LOC
  FLT --> EB
```

---

## Multi-region strategy

| Phase | Topology |
| --- | --- |
| MVP | Single region `af-south-1` |
| National | Active-passive DR |
| Regional EA | Hub in Dar + read replicas |

---

## Sequence: national API

```mermaid
sequenceDiagram
  participant U as User
  participant CF as CloudFront
  participant G as API GW
  participant S as Fleet service
  U->>CF: app API
  CF->>G: /mobility/*
  G->>S: get live positions
  S-->>U: GeoJSON
```

---

## Smart city ingest (future)

IoT Core / Kinesis for sensors → EventBridge → traffic analytics Lambda.

---

## TNPI connectivity

TPP services in same org VPC; no direct TNMP → TNPI except through TPP service mesh policy exception (read-only reporting BFF).

---

## Security

Private subnets; WAF; per-tenant encryption keys optional.

---

## Operational considerations

Autoscale fleet ingest on peak; cost caps on AI inference.

---

## Implementation strategy

Terraform module `taifa-mobility`; wave-based service rollout.

---

## Future expansion

Outposts at major stations for low latency.

---

## Cross-references

[13_IMPLEMENTATION_GUIDE.md](13_IMPLEMENTATION_GUIDE.md)
