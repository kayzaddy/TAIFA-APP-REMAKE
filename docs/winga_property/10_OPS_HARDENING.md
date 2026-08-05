# Winga Property — Ops Hardening (Post Phase 6)

**Status:** COMPLETE

## Production RBAC

Ops endpoints require enterprise `PlatformPrincipal` roles:

| Role | Permissions |
| --- | --- |
| `property-ops-viewer` | `winga.property.ops.read` |
| `property-ops-officer` | `winga.property.ops.read`, `winga.property.ops.write` |

**Read:** dashboard, analytics, moderation queue, disputes list, ops console, application fraud ML  
**Write:** resolve moderation, suspend listing, assign/resolve disputes  

User-facing endpoints remain open to any device: report listing, open dispute.

Migration: `0007_property_ops_rbac.py`

## Fraud ML

`listing_fraud_signals` and `application_fraud_signals` now call Taifa AI OS `fraud_detection` via `ecosystem.invoke_ai`, merged with rule-based signals.

Response includes `ml` block with `risk_band`, `score_e4`, `reasoning`. Always `advisory_only: true` and `payment_authorized: false`.

## Dedicated ops console

- **Route:** `/winga-property/ops` (Flutter web + mobile)
- **API:** `GET /ops/console` — bundled dashboard, moderation, disputes, audit
- **UI:** Tabbed console with overview KPIs, moderation actions, disputes, audit log

Grant `property-ops-officer` to an ops principal before opening the console in production.
