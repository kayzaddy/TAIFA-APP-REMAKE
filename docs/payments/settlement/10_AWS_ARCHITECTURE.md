# 10 — AWS Architecture

---

## Executive summary

Event-driven settlement on EventBridge, Step Functions, Lambda, ECS, RDS, Redis, SQS, SNS, observability & backup.

---

## Component diagram

```mermaid
flowchart TB
  EB[EventBridge] --> LAM[Lambda Ingest]
  LAM --> ECS[ECS Settlement Service]
  ECS --> RDS[(RDS settlement)]
  ECS --> REDIS[(Redis locks)]
  SF[Step Functions Batch] --> ECS
  ECS --> SQS[Payout Queue]
  SQS --> PAY[Payout Workers]
  PAY --> PSP[PSP APIs]
  ECS --> S3[Reports]
  SNS[SNS Alerts] --> OPS[Finance Ops]
  CW[CloudWatch] --> ECS
```

---

## Sequence: event to batch

```mermaid
sequenceDiagram
  participant EB as EventBridge
  participant L as Lambda
  participant E as ECS
  participant SF as Step Functions
  EB->>L: payment.completed
  L->>E: idempotent create settlement
  SF->>E: nightly close batch
  E->>E: execute payouts
```

---

## Security / operational model

Least privilege; no public RDS; backup RPO 5m.

---

## Implementation strategy

IaC module `tnpi-settlement`.

---

## Future expansion

Multi-region read for reporting.

---

## Cross-references

[11_AWS_ARCHITECTURE.md](../11_AWS_ARCHITECTURE.md) program
