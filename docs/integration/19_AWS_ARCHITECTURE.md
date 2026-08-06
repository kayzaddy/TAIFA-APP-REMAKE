# 19 — AWS Architecture

---

## Executive summary

Production TIP on AWS: multi-account, **CloudFront**, **Route53**, **WAF**, **Shield**, dual **API Gateway** (enterprise + partner), **ECS Fargate**, **Lambda**, **Step Functions**, **EventBridge**, **SNS**, **SQS**, **RDS**, **Redis**, **CloudWatch**, **CloudTrail**, **KMS**, **Secrets Manager**, **Backup**.

---

## Architecture overview

```mermaid
flowchart TB
  R53[Route53]
  CF[CloudFront]
  subgraph edge [Edge account]
    WAF[WAF Shield]
    EGW[Enterprise API GW]
    PGW[Partner API GW]
  end
  subgraph runtime [Workload account]
    ECS[ECS Fargate control data plane]
    SF[Step Functions]
    EB[EventBridge]
    L[Lambda]
  end
  subgraph data [Data]
    RDS[(RDS)]
    REDIS[(Redis)]
  end
  R53 --> CF --> WAF --> EGW & PGW
  EGW & PGW --> ECS
  ECS --> SF & EB & L
  ECS --> RDS & REDIS
```

---

## Multi-account

| Account | Purpose |
| --- | --- |
| Network | TGW, firewall |
| Integration prod | TIP runtime |
| Integration nonprod | Sandbox |
| Security | Logs, GuardDuty agg |

---

## DR

Multi-AZ; cross-region EventBridge archive; RTO 4h national target.

---

## Cross-references

[11_SERVICE_MESH.md](11_SERVICE_MESH.md) · [20_IMPLEMENTATION_GUIDE.md](20_IMPLEMENTATION_GUIDE.md)
