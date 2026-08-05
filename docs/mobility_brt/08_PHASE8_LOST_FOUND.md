# Phase 8 — Lost & Found

**Status:** COMPLETE  
**Module:** 15 (Lost & found — station reports and claims)

## Scope

Passengers can report and recover items lost on Mwendokasi BRT:

- Report **lost** or **found** items with category, station, and description
- Browse open reports filtered by kind and stop code
- Claim a **found** item (notifies the finder)
- Confirm handoff — reporter or claimant resolves to `matched` / `closed`
- In-app notifications on report, claim, and resolve

## Backend

### Model

`TransitLostFoundItem` in `national_models.py`:

- `reporter_owner`, `kind` (lost/found), `category`, `title`, `description`
- `stop_code`, optional `route` FK
- `status`: open → claimed → matched/closed
- `claimant_owner`, `claim_message`, timestamps

Migration: `0023_brt_phase8_lost_found.py`

### API

| Method | Path | Description |
| --- | --- | --- |
| GET | `/transit/lost-found?kind=&stop_code=` | Bundle: open items + my reports + my claims |
| POST | `/transit/lost-found` | Report lost or found item |
| POST | `/transit/lost-found/{id}/claim` | Claim a found item |
| POST | `/transit/lost-found/{id}/resolve` | Confirm handoff (`status`: matched or closed) |

### Service

`transit_services.py`:

- `transit_lost_found_bundle`, `report_transit_lost_found`
- `claim_transit_lost_found`, `resolve_transit_lost_found`
- Notifications via `_emit_transit_notification`

### Tests

`trips/test_brt_phase8.py` — 5 tests (report lost, browse found, claim, reject self-claim, resolve).

## Flutter

| Surface | Route | Notes |
| --- | --- | --- |
| `TransitLostFoundScreen` | `/mobility/transit/lost-found` | Browse / My reports tabs, report sheet, claim & resolve |
| `TransitLostFoundController` | provider | Bundle load, report, claim, resolve |
| Transit home | button | “Lost & found” |

## Verification

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 trips.test_brt_phase2 trips.test_brt_phase3 trips.test_brt_phase4 trips.test_brt_phase5 trips.test_brt_phase6 trips.test_brt_phase7 trips.test_brt_phase8 -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit
flutter test test/mobility_transit
```

## BRT program complete

All 20 modules from the phase map are now delivered across Phases 1–8.
