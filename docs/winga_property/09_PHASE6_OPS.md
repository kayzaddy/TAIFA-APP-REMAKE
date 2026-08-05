# Winga Property — Phase 6: Enterprise Operations

**Status:** COMPLETE  
**Depends on:** Phases 1–5

## Scope delivered

| Capability | Implementation |
| --- | --- |
| Executive dashboard | `operations.executive_dashboard` — KPIs |
| Analytics | Conversion funnel, regional breakdown, GMV |
| Fraud signals (advisory) | Listing + application risk scoring |
| Moderation queue | Reports + pending verifications |
| Report listing | User reports → ops queue |
| Suspend listing | Ops enforcement action |
| Disputes | Open, assign, resolve workflow |
| Ops audit trail | `PropertyOpsAuditEvent` |

## Reuse (no duplication)

- **Fraud pattern:** advisory-only signals (like Mobility `trip_fraud_signals`)
- **Disputes pattern:** aligned with `winga.Dispute` workflow
- **Analytics:** Django aggregates on property domain models (no duplicate warehouse)
- **AI:** fraud remains advisory; `payment_authorized: false`

## API highlights

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/ops/dashboard` | Executive KPIs |
| GET | `/ops/analytics` | Analytics summary |
| GET | `/ops/moderation-queue` | Pending reports + verifications |
| POST | `/listings/{id}/report` | Report listing |
| GET | `/listings/{id}/fraud-signals` | Advisory fraud signals |
| GET | `/applications/{id}/fraud-signals` | Application fraud signals |
| POST | `/ops/moderation/{id}/resolve` | Resolve moderation report |
| POST | `/ops/listings/{id}/suspend` | Suspend listing |
| GET/POST | `/ops/disputes` | List / open disputes |
| POST | `/ops/disputes/{id}/assign` | Assign ops agent |
| POST | `/ops/disputes/{id}/resolve` | Resolve dispute |

## Flutter UX

- **Ops portal** — dashboard icon in app bar
- **Report** — action on listing detail sheet

## Tests

`winga_property.tests` — 18 tests
