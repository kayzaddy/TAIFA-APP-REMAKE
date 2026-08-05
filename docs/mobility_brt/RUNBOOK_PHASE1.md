# Taifa Mobility BRT — Phase 1 Runbook

## Prerequisites

- Backend running on `http://127.0.0.1:8000`
- Flutter with `TAIFA_USE_REMOTE=true`
- Device registered and wallet funded

## Backend setup

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py seed_mobility_brt
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 -v 1
```

## Flutter

```bash
cd apps/mobile
flutter analyze lib/features/mobility_transit
flutter test test/mobility_transit
flutter run -d windows --dart-define=TAIFA_USE_REMOTE=true --dart-define=TAIFA_API_BASE_URL=http://127.0.0.1:8000
```

## Demo flow (passenger)

1. Open **Mobility** tab → tap **Mwendokasi BRT** promo card (or navigate to `/mobility/transit`).
2. Transit Home shows nearby stations, DART Kimara—Kivukoni route, wallet balance chip.
3. Tap route → review stops → **Buy single ride** (TZS 650 via wallet).
4. Boarding pass screen shows `media_code` and signed QR JSON payload.
5. **My tickets** lists active passes for re-open.

## Validator demo (API)

Assign `transit-validator` role to a device, then:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/trips/transit/tickets/validate \
  -H "Authorization: Device <token>" \
  -H "Content-Type: application/json" \
  -d '{"media_code": "BRT-..."}'
```

Second validation on a single-ride ticket returns replay rejection.

## Troubleshooting

| Issue | Fix |
| --- | --- |
| 409 on purchase | Fund wallet; check `commerce` merchant for `mobility_transit` |
| Empty home stations | Pass `lat`/`lng` query params (Flutter defaults to Ubungo) |
| Route list empty | Run `seed_mobility_brt` |
