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
| PDL-010 | 2026-08-06 | TNPI program architecture pack (`docs/payments/00–18`) approved for implementation planning | Accepted | [payments/00_PAYMENT_PROGRAM.md](../payments/00_PAYMENT_PROGRAM.md) |
| PDL-011 | 2026-08-06 | TNPI Phase 1 Merchant Platform architecture pack approved; implementation may start (no pay rails) | Accepted | [payments/merchant/PHASE1_GATE_PACKAGE.md](../payments/merchant/PHASE1_GATE_PACKAGE.md) |
| PDL-012 | 2026-08-06 | TNPI Phase 2 Payment Sources Platform architecture pack approved (link/consent/tokens only) | Accepted | [payments/payment-sources/PHASE2_GATE_PACKAGE.md](../payments/payment-sources/PHASE2_GATE_PACKAGE.md) |
| PDL-013 | 2026-08-06 | TNPI Phase 3 Payment Orchestration Platform architecture pack approved | Accepted | [payments/orchestration/PHASE3_GATE_PACKAGE.md](../payments/orchestration/PHASE3_GATE_PACKAGE.md) |
| PDL-014 | 2026-08-06 | TNPI Phase 4 Merchant Acceptance Platform (MAP) architecture pack approved | Accepted | [payments/merchant-acceptance/PHASE4_GATE_PACKAGE.md](../payments/merchant-acceptance/PHASE4_GATE_PACKAGE.md) |
| PDL-015 | 2026-08-06 | TNPI Phase 5 Settlement Platform architecture pack approved | Accepted | [payments/settlement/PHASE5_GATE_PACKAGE.md](../payments/settlement/PHASE5_GATE_PACKAGE.md) |
| PDL-016 | 2026-08-06 | TNPI Phase 6 Reconciliation Platform architecture pack approved | Accepted | [payments/reconciliation/PHASE6_GATE_PACKAGE.md](../payments/reconciliation/PHASE6_GATE_PACKAGE.md) |
| PDL-017 | 2026-08-06 | TNPI Phase 7 Fraud & Risk Platform architecture pack approved | Accepted | [payments/fraud-risk/PHASE7_GATE_PACKAGE.md](../payments/fraud-risk/PHASE7_GATE_PACKAGE.md) |
| PDL-018 | 2026-08-06 | TNPI Phase 8 Developer Platform architecture pack approved | Accepted | [payments/developer-platform/PHASE8_GATE_PACKAGE.md](../payments/developer-platform/PHASE8_GATE_PACKAGE.md) |
| PDL-019 | 2026-08-06 | Transport Payments Platform (TPP) architecture pack approved | Accepted | [transport/00_PLATFORM_OVERVIEW.md](../transport/00_PLATFORM_OVERVIEW.md) |
| PDL-020 | 2026-08-06 | Taifa National Mobility Platform (TNMP) architecture pack approved | Accepted | [mobility/TNMP_GATE_PACKAGE.md](../mobility/TNMP_GATE_PACKAGE.md) |
| PDL-021 | 2026-08-06 | Government Digital Services Platform (GDSP) architecture pack approved | Accepted | [government/GDSP_GATE_PACKAGE.md](../government/GDSP_GATE_PACKAGE.md) |
| PDL-022 | 2026-08-06 | Taifa Integration Platform (TIP) architecture pack approved | Accepted | [integration/TIP_GATE_PACKAGE.md](../integration/TIP_GATE_PACKAGE.md) |
| PDL-023 | 2026-08-06 | Taifa Product Portfolio & Enterprise Delivery Roadmap approved as master execution plan | Accepted | [TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md](../TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md) |
| PDL-024 | 2026-08-06 | Taifa Merchant flagship business application architecture pack approved | Accepted | [taifa-merchant/TAIFA_MERCHANT_GATE_PACKAGE.md](../taifa-merchant/TAIFA_MERCHANT_GATE_PACKAGE.md) |
| PDL-025 | 2026-08-06 | Taifa Product Operating System (TPOS) approved as mandatory product engineering framework | Accepted | [tpos/00_TPOS_CHARTER.md](../tpos/00_TPOS_CHARTER.md) |
| PDL-026 | 2026-08-06 | Enterprise monorepo `taifa-platform` structure and governance approved (G0; docs/structure only) | Accepted | [taifa-platform/MONOREPO_GATE_PACKAGE.md](../../taifa-platform/MONOREPO_GATE_PACKAGE.md) |
| PDL-027 | 2026-08-06 | Taifa Engineering Operating System (TEOS) approved as mandatory engineering framework | Accepted | [teos/00_TEOS_CHARTER.md](../teos/00_TEOS_CHARTER.md) |

**Process:** New PDL entry for any platform-wide choice; promote to ADR if boundary or cross-team impact.
