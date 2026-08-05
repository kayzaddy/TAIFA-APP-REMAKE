# City Mobility Operations Guide

## Roles

| Role | App / API |
| --- | --- |
| Passenger | `/mobility`, favorites, recurring, shared rides, accounts |
| Driver | `/mobility-driver` |
| Station manager | `/station-ops` |
| Fleet owner | `/fleet-ops` + `/api/v1/trips/fleets/{id}/*` |
| Regional supervisor | `/regional-ops` + `/api/v1/trips/regional/supervisor` |
| City ops | `/city-ops`, `/ops` |

## Dispatch algorithm (summary)

1. Resolve nearest **approved** station (Registry SoT).
2. Rank eligible drivers (`rank_drivers`) using distance, ETA (+ peak traffic factor), queue, rating, safety, acceptance, strategy bonuses.
3. Strategies: `station_first` → home queue; `overflow` / `direct_nearby` / `priority` / `corporate` / `emergency` allow cross-station.
4. Offers expire → Celery redispatch: overflow → nearby → cancel.
5. Payments only via Taifa Payments after trip completion.

## Pricing conditions (JSON on PricingRule)

```json
{
  "peak_hours": [7, 8, 9, 16, 17, 18, 19],
  "peak_active": false,
  "holidays": ["2026-07-18"],
  "holiday_multiplier_e4": 13000,
  "traffic_multiplier_e4": 11000,
  "corporate_accounts": ["acme-corp"],
  "corporate_multiplier_e4": 9000,
  "government_multiplier_e4": 8500
}
```

Never hardcode fares in clients.

## Regional supervision

1. Create `MobilityZone` via `POST /api/v1/trips/zones`.
2. Create `RegionalSupervisorAssignment` in admin/ops DB for the principal.
3. Supervisor opens `/regional-ops` to see scoped KPIs and station rankings.

## Fleet owner checklist

- Drivers / vehicles: Registry approval first.
- Schedules: `POST /fleets/{id}/schedules`
- Fuel logs: `POST /fleets/{id}/fuel`
- Settlements list: payment refs only — money stays in Taifa Payments.

## Delivery categories

`food` · `medicine` · `documents` · `package` · `business` · `parcel` · `corporate_logistics`

Recipient verification code required; proof endpoint verifies hash.
