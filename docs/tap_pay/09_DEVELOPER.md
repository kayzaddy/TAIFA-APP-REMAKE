# 9. Developer Documentation

## API

| Method | Path |
| --- | --- |
| GET/PUT/PATCH/POST | `/api/v1/map/funding/prefs` |
| POST | `/api/v1/map/funding/resolve` |
| POST | `/api/v1/map/merchants/{id}/tap` |
| GET | `/api/v1/map/tap/{code}` |
| POST | `/api/v1/map/tap/{code}/auth` |
| POST | `/api/v1/map/tap/{code}/confirm` *(Idempotency-Key)* |
| POST | `/api/v1/map/tap/{code}/cancel` |

## Flutter

- Routes: `/tap`, `/tap/funding`
- Module: `lib/features/tap_pay/`
- Remote: `RestTapPayRepository` → MAP APIs

## Code

- Backend: `acceptance/tap.py`, models `TapSession`, `WalletFundingPreference`
