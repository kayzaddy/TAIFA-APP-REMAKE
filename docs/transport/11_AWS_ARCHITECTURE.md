# 11 — AWS Architecture

---

## Executive summary

TPP on AWS: **ECS Fargate** microservices, **RDS PostgreSQL** + PostGIS, **Redis** (validation cache, revocation), **EventBridge** + **SQS**, **API Gateway** (via Developer Platform), **CloudWatch**, **KMS**, integration with Maps/AI/Identity as managed services.

---

## Business purpose

Scale morning/evening peaks; regional presence for corridors (Dar, Dodoma, Mwanza).

---

## Architecture overview

```mermaid
flowchart TB
  DP[Developer Platform GW]
  subgraph tpp [TPP VPC]
    PAX_SVC[Passenger service]
    OP_SVC[Operator service]
    RTE[Route fare service]
    TIX[Ticket validation]
    JRN[Journey planner]
    WRK[Event workers]
  end
  RDS[(RDS PostGIS)]
  REDIS[(Redis)]
  EB[EventBridge]
  DP --> PAX_SVC & OP_SVC & RTE & TIX & JRN
  PAX_SVC --> RDS
  TIX --> RDS & REDIS
  EB --> WRK --> RDS
  WRK -->|payment.completed| TNPI_BUS[TNPI bus]
```

---

## Services

| Service | Scaling trigger |
| --- | --- |
| Validation | CPU + RPS 7–9am |
| Route/fare | Moderate |
| Journey planner | AI latency bound |
| Workers | Queue depth |

---

## Sequence: peak commute

```mermaid
sequenceDiagram
  participant G as API Gateway
  participant V as Validation
  participant R as Redis
  G->>V: validate burst
  V->>R: hot ticket cache
  V-->>G: 200 OK
```

---

## TNPI connectivity

Private VPC endpoints to TNPI internal ALB / Developer proxy—no public payment keys in TPP pods.

---

## Maps & AI

External APIs via VPC egress allowlist; cache geocode results.

---

## DR

Multi-AZ RDS; validation degrade to offline bundle mode documented.

---

## Security

Private subnets; no direct internet from data tier.

---

## Operational considerations

CloudWatch SLOs per city rollout.

---

## Implementation strategy

Terraform `taifa-transport`; reuse Taifa Core network.

---

## Future expansion

Edge validation appliance sync (ferry terminals).

---

## Cross-references

[12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md)
