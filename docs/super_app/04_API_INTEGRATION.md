# 4. API Integration Guide

The Super App **does not** add money or identity APIs.

| Concern | Client | API |
| --- | --- | --- |
| Wallet | `RestWalletRepository` | `/api/v1/payments/*` |
| MAP pay | `RestMapRepository` | `/api/v1/map/*` |
| Commerce | `RestMosRepository` + commerce repos | `/api/v1/mos/*`, `/api/v1/commerce/*` |
| Winga | Winga repos | `/api/v1/winga/*` |
| Mobility | `RestTripRepository` | `/api/v1/trips/*` |
| Identity | Device session | `/api/v1/auth/device/*` |
| Search / QR | Local orchestration | Routes only |

Remote toggle: `--dart-define=TAIFA_USE_REMOTE=true`
