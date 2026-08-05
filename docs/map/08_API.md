# 8. MAP API Documentation

Base: `/api/v1/map/` · Auth: device bearer (`IsDevice`)

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/bootstrap` | Merchant + acceptance profile |
| GET/PATCH | `/merchants/{id}/profile` | Acceptance profile |
| POST | `/merchants/{id}/qr` | Issue QR |
| GET | `/merchants/{id}/qr/library` | QR library |
| POST | `/merchants/{id}/qr/static/pay` | Pay static QR amount |
| GET/POST | `/merchants/{id}/links` | List / create links |
| GET/POST | `/merchants/{id}/invoices` | List / create invoices |
| POST | `/merchants/{id}/checkout` | Checkout session |
| GET/POST | `/merchants/{id}/terminals` | Terminals |
| GET | `/merchants/{id}/analytics` | Channel analytics |
| POST | `/merchants/{id}/winga/accept` | Winga QR+link+checkout |
| POST | `/merchants/{id}/mobility/accept` | Mobility checkout |
| GET | `/intents/{code}` | Intent detail |
| POST | `/intents/{code}/pay` | **Capture via Payments** |
| GET | `/links/{token}` | Resolve link |
| GET | `/receipts/{code}` | Receipt |

Pay endpoints require `Idempotency-Key`.
