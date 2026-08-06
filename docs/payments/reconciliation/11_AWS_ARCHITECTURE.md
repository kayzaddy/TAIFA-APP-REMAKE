# 11 — AWS Architecture

---

## Executive summary

API Gateway, EventBridge, Step Functions, Lambda, ECS, RDS, Redis, SQS, SNS, backup, security services.

---

## Component diagram

```mermaid
flowchart TB
  EB[EventBridge] --> LAM[Lambda ingest triggers]
  LAM --> SF[Step Functions Recon Job]
  SF --> ECS[ECS Matching Workers]
  ECS --> RDS[(RDS reconciliation)]
  ECS --> REDIS[(Redis index)]
  S3[S3 Statements] --> LAM
  ECS --> SQS[Exception queue]
  SNS --> OPS[Finance alerts]
  APIGW[API Gateway] --> ECS
```

---

## Sequence: large file ingest

```mermaid
sequenceDiagram
  participant PSP as PSP SFTP
  participant S3 as S3 Landing
  participant L as Lambda
  participant SF as Step Functions
  PSP->>S3: drop file
  S3->>L: event
  L->>SF: start parse+match
```

---

## Security / observability

[12](12_OBSERVABILITY.md)

---

## Operational considerations

Auto-scale workers on queue depth.

---

## Implementation strategy

IaC `tnpi-reconciliation`.

---

## Future expansion

MWAA for complex ETL if needed.

---

## Cross-references

[settlement/10_AWS_ARCHITECTURE.md](../settlement/10_AWS_ARCHITECTURE.md)
