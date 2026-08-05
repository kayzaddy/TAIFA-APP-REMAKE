# City-Scale Taifa Mobility (Phase 2)

Evolution of MDMP into a city operating system. Payments, Identity, and Mobility Registry remain shared platform services.

## Module coverage

| Module | Status |
| --- | --- |
| City dispatch | Production — overflow / priority / corporate / emergency |
| Smart stations | Production — intelligence, rankings, alerts, load balance |
| Fleet intelligence | Production — drivers, vehicles, schedules, fuel, settlements refs |
| Live city map | Production — `/city/map` |
| Demand forecasting | Production — seasonal v2 + city heatmap |
| Driver performance | Production — scores, rankings, refresh job |
| Passenger | Production — favorites, recurring, shared, family/corporate links |
| Fleet portal | Production — Flutter `/fleet-ops` + fleet APIs |
| City ops center | Production — `/city-ops`, `/city/operations` |
| Regional management | Production — zones + supervisor assignment + `/regional-ops` |
| Incidents | Production — SOS workflow |
| Pricing | Production — peak/night/holiday/traffic/corporate/government conditions |
| Delivery | Production — categories + proof + list |
| Analytics | Production — `/city/analytics`, rankings |
| Mobile apps | Passenger, Driver, Station, Fleet, City, Regional, Ops |

## Guides

- [`MOBILITY_CITY_OPERATIONS.md`](MOBILITY_CITY_OPERATIONS.md)
- [`MOBILITY_DISPATCH_ALGORITHMS.md`](MOBILITY_DISPATCH_ALGORITHMS.md)
- [`MDMP.md`](MDMP.md)

## Scale path

Keep contracts (`rank_drivers`, `forecast_station_demand`, `city_map_snapshot`). Swap Haversine for PostGIS and seasonal models for ML behind `model_version`.

## Phase 3

National mobility infrastructure builds on this city layer — see [`NATIONAL_MOBILITY.md`](NATIONAL_MOBILITY.md).
