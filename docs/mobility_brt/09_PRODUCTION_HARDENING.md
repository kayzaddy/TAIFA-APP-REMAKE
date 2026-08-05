# Production Hardening — Mwendokasi BRT

**Status:** COMPLETE  
**Follows:** Phase 8 (Lost & Found)

## Scope

Production-readiness for DART launch:

1. **Push delivery** — transit notifications fan out to device push tokens
2. **Photo uploads** — lost & found reports can include item photos
3. **Ops console** — lost & found queue in BRT admin + city control center KPIs

## Backend

### Push tokens

- `Device.push_token` on `payments.Device` (migration `0008_device_push_token`)
- `POST /auth/device/push-token` — update token for authenticated device
- `POST /auth/device/register` accepts optional `push_token`
- `_emit_transit_notification` → `_deliver_transit_push` via `integrations.notifications.deliver_notification`

Configure production push via `TAIFA_PUSH_PROVIDER_JSON`.

### Photo uploads

- `TransitLostFoundItem.photo_url` (migration `0024_brt_hardening_lost_found_photo`)
- `POST /transit/lost-found/photo` — base64 upload → S3-compatible storage (dev/test fallback URL)
- Reports accept `photo_url` on `POST /transit/lost-found`

Configure storage via `TAIFA_OBJECT_STORAGE_JSON`.

### Ops console

- `transit_ops_snapshot` includes `lost_found_open`, `lost_found_claimed`
- `GET /transit/admin/lost-found?status=` — operator queue (`IsMobilityOperator`)
- `POST /transit/admin/lost-found/{id}/resolve` — operator close/match

### Tests

`trips/test_brt_hardening.py` — 6 tests (push, photo, ops list, ops resolve, push token API, ops snapshot).

## Flutter

| Surface | Notes |
| --- | --- |
| `TransitAdminScreen` | Lost & found queue with Close action |
| `CityOpsScreen` | L&F open/claimed KPI chips |
| `TransitLostFoundScreen` | Photo picker on report sheet |
| `DeviceSession.registerPushToken` | Best-effort push token registration |

## Verification

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 trips.test_brt_phase2 trips.test_brt_phase3 trips.test_brt_phase4 trips.test_brt_phase5 trips.test_brt_phase6 trips.test_brt_phase7 trips.test_brt_phase8 trips.test_brt_hardening -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit lib/features/city_ops
flutter test test/mobility_transit
```

## Next

Mode expansion — daladala/regional routes, multi-mode planner UI (separate track).
