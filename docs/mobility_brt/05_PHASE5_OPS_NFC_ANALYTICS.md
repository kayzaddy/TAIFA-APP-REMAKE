# Phase 5 — Control Center, NFC, Analytics & Admin

**Status:** COMPLETE  
**Modules:** 10 (NFC boarding hooks), 18 (Control center), 19 (Analytics), 20 (Admin panel)

## Scope

Operations and admin layer for Mwendokasi BRT:

- **Analytics** — `TransitDailyMetric` rollups + `/transit/analytics` dashboard API
- **Control center** — BRT KPI block embedded in city/national ops surfaces
- **NFC** — `media_type=nfc` validation path + `NfcBoardingPort` / `NoOpNfcBoardingPort`
- **Admin** — ops-gated route/product upsert APIs + Flutter admin screen

## Backend

### Models

| Model | Purpose |
| --- | --- |
| `TransitDailyMetric` | Daily tickets/validations/fare by route + product |

Migration: `0021_brt_phase5_ops_analytics.py`

### APIs

| Method | Path | RBAC | Description |
| --- | --- | --- | --- |
| GET | `/transit/analytics` | `mobility.operations` | 7–30 day corridor analytics |
| POST | `/transit/admin/routes` | `mobility.operations` | Create route |
| PATCH | `/transit/admin/routes/{id}` | `mobility.operations` | Update route |
| POST | `/transit/admin/products` | `mobility.operations` | Create pass product |
| PATCH | `/transit/admin/products/{id}` | `mobility.operations` | Update pass product |
| POST | `/transit/tickets/validate` | `transit-validator` | Now accepts `media_type` (`qr` \| `nfc`) |

### Ops extensions

- `regional_kpis.transit` and `city_map_snapshot.summary.transit` — live BRT snapshot
- `national_command_center.national.transit` — national BRT rollup

### Services

- `transit_ops_snapshot()` — live KPIs
- `build_transit_daily_metrics()` — materialize daily rows
- `transit_analytics_bundle()` — dashboard payload
- `admin_upsert_route()` / `admin_upsert_product()` — admin CRUD

### Tests

`trips/test_brt_phase5.py` — 7 tests (analytics RBAC, ops KPIs, admin, NFC validate).

## Flutter

| Surface | Route / location | Notes |
| --- | --- | --- |
| `TransitAdminScreen` | `/mobility/transit/admin` | Routes, products, analytics chips |
| `NoOpNfcBoardingPort` | provider | Hardware stub |
| NFC simulate button | boarding pass screen | Shows media code until hardware lands |
| City / National ops | existing screens | BRT ticket/scan/AVL chips |

## Verification

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 trips.test_brt_phase2 trips.test_brt_phase3 trips.test_brt_phase4 trips.test_brt_phase5 -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit lib/features/city_ops lib/features/national_ops
flutter test test/mobility_transit
```

## Next: Phase 6

AI travel assistant (Kiswahili + English) via Taifa AI OS.

**Delivered in Phase 6** — see `06_PHASE6_AI_ASSISTANT.md`.
