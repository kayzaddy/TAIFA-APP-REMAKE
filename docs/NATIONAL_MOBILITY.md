# National Mobility Infrastructure (Phase 3)

Taifa Mobility as Tanzania’s digital transportation operating system — multi-modal, multi-region, enterprise, government, logistics, and public transport — built on shared platform services.

## Non-negotiables

| Service | Role |
| --- | --- |
| Taifa Identity | Authentication / principals |
| Taifa Payments | All money movement (refs only in Mobility) |
| Taifa Registry (Mobility Registry) | Eligibility / verification SoT |
| Notifications | Push / in-app alerts |
| Analytics | Platform analytics fabric |

Mobility **consumes** these services. It does not duplicate payment ledgers, identity stores, or registry approval logic. Dispatch and fare engines from Phase 1–2 remain authoritative; Phase 3 extends modes, geography, and national modules around them.

## Module map

| # | Module | Implementation |
| --- | --- | --- |
| 1 | National Operations Center | `national_ops.national_command_center`, `/national/command-center`, Flutter `/national-ops` |
| 2 | Intercity travel | `IntercityCorridor` / `Departure` / `Booking`, `/intercity/*` |
| 3 | Multi-modal transport | Extended `TransportMode` + dispatch by vehicle class |
| 4 | Enterprise mobility | `EnterpriseOrganization` / `Employee`, `/enterprise/*` |
| 5 | Government integration | `trips.adapters.government` + `MOBILITY_GOVERNMENT_ADAPTERS` |
| 6 | Smart transport network | `national_optimization_recommendations` + city intelligence |
| 7 | Logistics | `LogisticsShipment` + existing `Delivery` proof flow |
| 8 | Public transport | `PublicTransitRoute` / `Timetable`, `/public-transit/*` |
| 9 | Emergency mobility | `EmergencyDispatchRequest` + `TripKind.EMERGENCY` |
| 10 | National analytics | `NationalDailyMetric`, Celery `mobility.build_national_daily_metrics` |
| 11 | Digital marketplace | Partner credentials + open catalog |
| 12 | AI platform | Demand / balancing / expansion signals (versioned contracts) |
| 13 | Digital ticketing | `TransportTicket` (QR/NFC/wallet/passes) |
| 14 | National reporting | `/national/reports` → government adapters |
| 15 | Open platform | `/open/partners`, `/open/catalog`, versioned OpenAPI tags |

## Layering

```text
National Ops / GIS / Analytics / Reporting
        │
 Intercity · PT · Tickets · Logistics · Emergency · Enterprise · Partners
        │
 City Ops (Phase 2) — overflow, rankings, regional KPIs
        │
 Station Ops (Phase 1) — queue, dispatch, trips
        │
 Shared: Identity · Payments · Registry · Notifications
```

## Scale posture (10–15 years)

- Horizontal API workers + Celery for metrics / intelligence refresh
- Region-partitioned read models (`NationalDailyMetric`) for nationwide reporting
- Adapter interfaces for LATRA, TANROADS, TARURA, LGA, TRA, Police, Emergency, NIDA, BRELA, Traffic
- Offline-first mobile clients continue to sync via existing device auth + trip APIs
- GIS contracts (`national_map_layers`) stay stable; PostGIS can replace Haversine behind the same response shape

## Guides

- [`NATIONAL_ARCHITECTURE.md`](NATIONAL_ARCHITECTURE.md)
- [`GOVERNMENT_INTEGRATION.md`](GOVERNMENT_INTEGRATION.md)
- [`ENTERPRISE_MOBILITY.md`](ENTERPRISE_MOBILITY.md)
- [`NATIONAL_API.md`](NATIONAL_API.md)
- [`GIS_ARCHITECTURE.md`](GIS_ARCHITECTURE.md)
- [`NATIONAL_OPERATIONS.md`](NATIONAL_OPERATIONS.md)
- [`CITY_MOBILITY.md`](CITY_MOBILITY.md) · [`MDMP.md`](MDMP.md)
