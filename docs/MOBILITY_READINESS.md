# TAIFA Mobility Implementation Readiness

Date: 2026-07-17

## Implemented foundation

- First-class stations, drivers, fleets, vehicles, verification, schedules,
  station queues and operational logs.
- Server-authoritative, versioned pricing and bounded promotions.
- Station-first dispatch, auditable ranking, expiring offers and transactional
  first-accept assignment.
- Controlled trip state machine and append-only trip events.
- GPS batch ingestion and authenticated Redis-backed WebSocket fan-out.
- Passenger, scheduled, corporate/government trip types and delivery proof.
- SOS/safety incidents, ratings and saved locations.
- Payment delegation to the existing enterprise/payment orchestrator.
- Cash remains pending reconciliation; Mobility has no balance or settlement
  engine.
- Operations, station, fleet, driver gross-fare and regulatory APIs.
- Daily projections, deterministic intelligence contracts, Prometheus metrics,
  Grafana dashboard, alerts and runbooks.
- Flutter remote repository no longer submits fares or fabricates payment
  references; production lifecycle is server authoritative.

## Required before a controlled field pilot

- Configure real Maps, routing, traffic and geocoding providers; current Flutter
  gateways still use simulation.
- Configure push notification provider and event-outbox consumers.
- Complete shared customer KYC/profile integration and document-vault
  integration for driver evidence.
- Add encryption/key-management implementation for trusted-contact phone data.
- Implement production cash collection/reconciliation workflow in Taifa
  Payments for mobility stations.
- Add PostGIS and geospatial indexes; current Haversine candidate scan is only
  suitable for a controlled pilot.
- Add explicit GPS retention, deletion, consent and law-enforcement access
  policy.
- Conduct SOS field drills with response authorities and station managers.
- Complete Flutter driver, station manager, fleet, operations and government
  applications. Backend contracts exist; those production user experiences do
  not.
- Complete offline command queue, map tiles and conflict resolution in Flutter.
- Run security, privacy, accessibility, device, network-loss and abuse tests.
- Run realistic load tests for dispatch/GPS/WebSockets and multi-instance
  failover.

## Required before national rollout

- Regional dispatch partitioning and ownership.
- PostGIS/geocell nearest-neighbour matching.
- Time/region partitioning and lifecycle management for GPS telemetry.
- Multi-region database, Redis and event-platform disaster recovery.
- Multiple map/notification/provider paths where required by SLO.
- ML governance, shadow evaluation, drift/fairness monitoring and rollback.
- Formal LATRA/BoT/privacy/legal review and regional authority onboarding.

## Gate

Software foundation: **IMPLEMENTED AND UNDER TEST**

Controlled pilot: **NOT CERTIFIED**

National production: **NOT CERTIFIED**

The remaining controls depend on provider credentials, field operations,
privacy policy, external authority coordination, infrastructure sizing and
validated mobile/portal applications. They must not be represented as complete
by backend code alone.
