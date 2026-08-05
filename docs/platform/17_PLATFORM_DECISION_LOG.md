# 17 — Platform Decision Log

**Purpose:** Record platform-level decisions (complements [architecture/adr/](../architecture/adr/README.md)).

| ID | Date | Decision | Status | Doc |
| --- | --- | --- | --- | --- |
| PDL-001 | 2026-08-05 | Event prefix policy `booking.reservation.*` | Accepted | [ADR-0002](../architecture/adr/0002-event-catalog-prefix-policy.md) |
| PDL-002 | 2026-08-05 | Commerce vertical strangler E0–E5 | Accepted | [ADR-0003](../architecture/adr/0003-commerce-vertical-extraction.md) |
| PDL-003 | 2026-08-05 | Tourism Protection/Connectivity tables in `tourism` app (phase-1) | Accepted | [Tourism ADR-0001](../tourism/adr/0001-phase1-protection-connectivity-in-tourism-app.md) |
| PDL-004 | 2026-08-06 | Taifa Core doc pack `00–17` as execution blueprint | Accepted | [README](README.md) |
| PDL-005 | 2026-08-06 | Renumber platform services: Feature Flags = 08, Audit = 09 | Accepted | This log |
| PDL-006 | 2026-08-06 | Sprint 0 Conditional GO for implementation (infra/repo, not domains) | Accepted | [14 § Readiness](14_PLATFORM_IMPLEMENTATION_GUIDE.md) |
| PDL-007 | 2026-08-06 | Sprint 0 Engineering Plan adopted as platform engineering contract | Accepted | [SPRINT_0_ENGINEERING_PLAN.md](SPRINT_0_ENGINEERING_PLAN.md) |
| PDL-008 | TBD | Identity: Cognito vs self-hosted OIDC | Proposed | — |
| PDL-009 | TBD | API edge: ALB-only vs API Gateway phase 1 | Proposed | — |

**Process:** New PDL entry for any platform-wide choice; promote to ADR if boundary or cross-team impact.
