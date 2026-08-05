# 16 — Platform Backlog

**Owner:** Platform Engineering Lead  
**Prioritization:** MoSCoW within Phase 1 Taifa Core

---

## Must have (Phase 1)

| ID | Item | Service | Sprint |
| --- | --- | --- | --- |
| PB-001 | `taifa_kernel` event envelope + Money VO spec | Kernel | S0 |
| PB-002 | IaC staging VPC + ECS + RDS + Redis | Infra | S0 |
| PB-003 | GitHub OIDC deploy role | CI/CD | S0 |
| PB-004 | Correlation ID platform standard | Gateway / Monitoring | S2 |
| PB-005 | OIDC validator + device bridge | Identity | S1 |
| PB-006 | Outbox table + publisher design | Events | S3 |
| PB-007 | EventBridge bus + DLQ | Events | S3 |
| PB-008 | Notification send facade API | Notifications | S3 |
| PB-009 | Media presign + S3 module | Media | S3 |
| PB-010 | Feature flag evaluate API | Feature flags | S3 |
| PB-011 | Audit append API | Audit | S4 |
| PB-012 | Structured logging schema | Monitoring | S4 |
| PB-013 | Grafana dashboards + alerts | Monitoring | S4 |
| PB-014 | WAF + KMS staging | Security | S4 |
| PB-015 | Platform integration test suite | Validation | S5 |

---

## Should have

| ID | Item | Service |
| --- | --- | --- |
| PB-020 | API Gateway custom domain | Gateway |
| PB-021 | Maps port formal OpenAPI | Maps |
| PB-022 | AppConfig for flags | Feature flags |
| PB-023 | Step Functions saga template | Events |
| PB-024 | Python/Dart SDK alpha | SDK |

---

## Could have

| ID | Item |
| --- | --- |
| PB-030 | OpenSearch for audit query |
| PB-031 | Multi-region state bucket |
| PB-032 | Service mesh (App Mesh) |

---

## Won't have (Phase 1)

| Item | Reason |
| --- | --- |
| Tourism checkout / BookingPort code | Domain Phase 2 |
| Commerce vertical extraction code | Domain Phase 2 |
| Trade domain | No pack |
| Production prod cutover | After staging validation |

---

## Cross-references

[14_PLATFORM_IMPLEMENTATION_GUIDE.md](14_PLATFORM_IMPLEMENTATION_GUIDE.md) · [15_PLATFORM_ROADMAP.md](15_PLATFORM_ROADMAP.md)
