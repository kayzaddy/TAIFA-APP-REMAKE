# Winga Property — Phase 1 Index

**Status:** Phase 6 Enterprise Operations — **COMPLETE**  
**API:** `/api/v1/winga-property/`  
**Flutter:** `/winga-property`  
**Seed:** `python manage.py seed_winga_property`  
**Tests:** `winga_property.tests` (19/19)

## Documents

| # | Doc |
| --- | --- |
| 1 | [PRD — Phase 1](01_PRD_PHASE1.md) |
| 2 | [Architecture](02_ARCHITECTURE.md) |
| 3 | [API Reference](03_API.md) |
| 4 | [Flutter Guide](04_FLUTTER.md) |
| 5 | [Phase 2 — Discovery](05_PHASE2_DISCOVERY.md) |
| 6 | [Phase 3 — Virtual Experience](06_PHASE3_EXPERIENCE.md) |
| 7 | [Phase 4 — AI + Human Winga](07_PHASE4_HUMAN_WINGA.md) |
| 8 | [Phase 5 — Digital Transactions](08_PHASE5_TRANSACTIONS.md) |
| 9 | [Phase 6 — Enterprise Operations](09_PHASE6_OPS.md) |
| 10 | [Ops Hardening — RBAC, ML, Console](10_OPS_HARDENING.md) |

## Reuse map

| Capability | Owner |
| --- | --- |
| Identity / device auth | Taifa Identity (`IsDevice`) |
| Brokerage / Human Winga | `winga.WingaProfile`, `winga.Lead`, commission rules |
| Secure chat | `commerce.ChatThread` |
| Payments (Phase 5) | Taifa Payments / Wallet |
| Identity (Phase 5) | Taifa Identity / `continental.adapters` |
| Maps (Phase 2+) | Mobility `MapsProvider` / `MapScene` |
| Notifications | `integrations.notifications` |
| Ops / audit | `PropertyOpsAuditEvent` (domain-local) |
| RBAC | `enterprise.PlatformRole` — `property-ops-officer` |
| Fraud ML | Taifa AI OS `fraud_detection` (advisory) |

## Program complete

All six Winga Property phases are implemented. See phase docs 01–09 for scope.
