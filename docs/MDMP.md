# Minimum Deployable Mobility Platform (MDMP)

Production pilot for station-based motorcycle transport in Tanzania.

## Non-negotiables

- **Taifa Payments** is the only payment engine (wallet / cash reconciliation / merchant capture).
- **Mobility Registry** is the only identity & eligibility authority.
- Only verified drivers, verified vehicles, and approved stations participate in dispatch.

## Pilot loop

```
Passenger request → nearest approved station → ranked queue drivers
→ offer → accept / reject / timeout → redispatch → trip FSM
→ complete → Taifa Payments settlement → driver returns to queue
```

## Backend surfaces (Django `trips`)

| Capability | Endpoint / service |
| --- | --- |
| Station dashboard | `GET /api/v1/trips/stations/{id}/dashboard` |
| Queue list / join | `GET|POST /api/v1/trips/stations/{id}/queue` |
| Queue leave | `POST .../queue/leave` |
| Queue reorder (manager) | `POST .../queue/reorder` |
| Driver availability | `POST /api/v1/trips/driver/availability` |
| Offers | `GET /api/v1/trips/driver/offers` |
| Accept / reject | `POST .../offers/{id}/accept\|reject` |
| Redispatch | `reject_offer`, `expire_dispatch_offers` Celery task |
| Ops command center | `GET /api/v1/trips/operations/dashboard` |
| Notifications | `GET /api/v1/trips/notifications` |
| Station merchant | Registry station approve → `enterprise.Merchant` linked |

## Flutter pilot apps

| Route | Role |
| --- | --- |
| `/mobility` | Passenger ride booking |
| `/mobility-driver` | Driver online/queue/offers/SOS |
| `/station-ops` | Station manager dashboard + queue override |
| `/ops` | Command center (remote dashboard when `TAIFA_USE_REMOTE=true`) |

## Dispatch recovery

1. Offer expires → Celery `mobility.expire_dispatch_offers`
2. Pending offers cleared → `redispatch_trip`
3. After max attempts → widen to `direct_nearby`, then cancel with notification

## Deploy checklist (one district)

1. Migrate backend (`0009` notifications/availability, `0010` trip metadata).
2. Approve ≥5 stations in Mobility Registry (auto-provisions payment merchants).
3. Approve ≥50 drivers + vehicles; assign to stations.
4. Run Daphne + Celery worker (beat: expire offers every ~15s recommended).
5. Launch Flutter with `--dart-define=TAIFA_USE_REMOTE=true`.

## Tests

```bash
cd apps/backend
.\.venv\Scripts\python.exe manage.py test trips.tests.MobilityDispatchTests
```

Covered: station-first dispatch, accept race, reject→redispatch, queue reorder auth, payment delegation.
