# National Operations Manual

## Daily operations

1. Open Flutter **National Ops** (`/national-ops`) or `GET /national/command-center`.
2. Confirm `system_health` (`healthy` / `degraded` / `critical`).
3. Drill into regions with elevated SOS, emergency, or degraded city KPIs.
4. Review `/national/optimization` for fleet balancing and station expansion signals.
5. File authority reports via `/national/reports` on the agreed schedule (LATRA weekly/monthly).

## Celery jobs

| Task | Purpose |
| --- | --- |
| `mobility.build_national_daily_metrics` | Roll up trip stats into `NationalDailyMetric` |
| City intelligence refresh (Phase 2) | Demand / driver performance inputs to national AI |

## Incident ladder

| Signal | Action |
| --- | --- |
| Open SOS | City ops incident workflow; escalate regionally |
| Emergency open | Confirm ambulance/van trip; hospital coordination |
| Degraded regions | Check station capacity, driver availability, Redis/Celery |
| Critical national health | Treat as P1 — identity/GPS/payment refs may be involved; follow platform incident response |

## Failover & DR

- Align with [`DISASTER_RECOVERY.md`](DISASTER_RECOVERY.md) and [`DEPLOYMENT.md`](DEPLOYMENT.md).
- Mobility state is Postgres + Redis offers; rebuild metrics from trip history after restore.
- Government adapters are outbound — failure must not block passenger trips (report endpoints fail soft to operator).

## Load / failover testing

- Unit: `trips.test_national_phase3.NationwideSimulationTests`
- City mass dispatch: `trips.test_city_phase2b.CityDispatchSimulationTests`
- Full stack: use staging compose + k6/locust against `/api/v1/trips/` create + dispatch (Payments sandbox)

## Contacts

Operators need enterprise roles with `mobility.operations`. Regulatory viewers need `mobility.regulatory.read` where enforced.
