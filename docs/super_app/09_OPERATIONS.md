# 9. Operations Manual

## What to monitor (client)

- Crash / ANR (existing Sentry hooks if configured)
- Feature adoption: `/search`, `/scan`, `/pay` opens
- Payment success: Payments + MAP metrics (server)
- Ride / order completion: domain APIs

## Support playbooks

| Issue | Action |
| --- | --- |
| QR won’t pay | Check MAP intent + wallet funds |
| Search misses module | Update `EcosystemCatalog` keywords |
| AI “paid for me” claim | Bug — AI must refuse; verify gateway |

Success metrics: DAU/MAU, session duration, conversion, retention, wallet & QR usage, CSAT — **not** feature count.
