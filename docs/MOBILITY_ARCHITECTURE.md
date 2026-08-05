# TAIFA Mobility — National Transport Operating System

## Purpose

TAIFA Mobility digitizes Tanzania's existing transport stations. It is a
transport operations bounded context inside the Taifa Platform; it is not a
second identity, payment, audit, notification, analytics, or map platform.

## Non-negotiable boundaries

| Capability | System of record | Mobility responsibility |
|---|---|---|
| Authentication and customer identity | Taifa Identity/Auth | Reference the authenticated principal |
| KYC | Taifa Identity | Store only transport-specific verification outcomes |
| Wallet, card, mobile-money, balances | Taifa Payments | Submit idempotent payment instructions and retain protected transaction IDs |
| Merchant/fleet/station settlement | Taifa Enterprise Payments | Associate stations with an enterprise merchant; never compute settlement |
| Cash collection | Taifa Payments reconciliation | Keep trip `payment_pending`; never create a fake payment |
| Audit | Taifa Audit | Emit actor/resource before/after records |
| Notifications | Taifa event outbox | Publish mobility events for notification consumers |
| Maps/routing | Maps gateway | Store coordinates/routes needed for operations |
| Analytics | Projection/event platform | Produce mobility projections; do not query payment balances |

No mobility model stores a wallet balance. `Trip.payment_transaction` is a
`PROTECT` reference to the immutable payment transaction.

## Bounded modules

### Identity and operations

- `Station`: GPS, administrative address, capacity, operating hours, service
  radius, manager, station merchant.
- `Driver`: authenticated principal, station/fleet assignment, identity and
  licence verification state, availability, safety and acceptance scores.
- `Vehicle`: mode, registration, owner/fleet/driver, insurance, road licence,
  inspection and maintenance state.
- `Fleet`: independent, small, corporate, government and rental operators.
- `DriverVerification`, `DriverSchedule`, `VehicleOperationalLog`,
  `StationQueueEntry`.

National ID values are not stored in plaintext. Document payloads belong in
the Taifa Identity document vault; Mobility retains hashes and review states.

### Dispatch and trip lifecycle

The default path is station-first:

1. Customer submits pickup, destination, requested vehicle mode and route
   estimate.
2. Server selects the nearest active station within its service radius.
3. Server calculates a fare from a versioned `PricingRule`.
4. Dispatch ranks verified, compliant, available station drivers.
5. Expiring `DispatchOffer` rows are sent.
6. A transactional first-accept wins lock assigns driver and vehicle.
7. Every lifecycle change passes through `transition_trip` and appends a
   `TripEvent`.

Client applications cannot set fares, assign drivers, write payment references,
or skip lifecycle states.

Matching v1 is deterministic and auditable. It weighs distance, ETA, queue
position, driver rating, safety score, and historical acceptance. Traffic and
demand inputs can be introduced as versioned score factors without changing
the dispatch contract.

### Real-time tracking

REST batch ingestion accepts at most 100 ordered GPS points for offline
recovery. Duplicate/out-of-order points are ignored. Authorized customers and
assigned drivers subscribe at:

`/ws/v1/mobility/trips/{trip_id}`

WebSockets are read-only for lifecycle state; all commands use authenticated
REST APIs. Production fan-out uses Redis Channels. Messages are published only
after database commit.

### Pricing

`PricingRule` is versioned and effective-dated. It supports:

- base, distance, time and waiting components;
- station fees;
- night and peak multipliers;
- regional, vehicle and trip-kind rules;
- minimum fares;
- bounded, effective-dated promotions.

The accepted fare and full breakdown are snapshotted onto the trip. Currency is
an existing Taifa Payments currency. Dynamic pricing can update future rule
versions; it must never rewrite an accepted trip.

### Payments

For wallet/card/mobile-money requests, Mobility calls
`PlatformOrchestrator.capture_merchant_payment` with a mandatory idempotency
key. The enterprise merchant payable and later settlement remain in Taifa
Payments. Mobility records the returned transaction ID.

Cash completion changes the trip to `payment_pending`; station cash collection
must be reconciled through Taifa Payments. There is no cash ledger or driver
wallet in Mobility.

Driver "earnings" APIs report operational gross fares linked to successful
payment transactions. They are not wallet balances and cannot be withdrawn.
Withdrawal remains a Taifa Payments operation.

### Safety and delivery

- `SafetyIncident` supports SOS, panic, crash, harassment and fraud response.
- Critical/high open incidents page the mobility safety team.
- Trip WebSocket access is limited to the customer and assigned driver.
- Delivery recipient codes are one-way hashed; plaintext codes are never
  persisted.
- Proof of delivery records method, location and completion timestamp.

### Operations, analytics and regulatory

- Operations dashboard: live trips, available drivers, active stations, SOS,
  daily completion and gross operational fares.
- Fleet/station dashboards are owner/manager scoped.
- `MobilityDailyMetric` provides an analytics projection.
- Regulatory reports are immutable snapshots behind
  `mobility.regulatory.read`.
- Prometheus and Grafana expose lifecycle, dispatch, queues, payment backlog and
  safety.

### Intelligence

The first intelligence interfaces are explicit deterministic baselines:

- station demand forecast;
- driver positioning recommendation;
- odometer maintenance prediction;
- auditable trip fraud signals.

Every output includes a model version and confidence/risk score. Future ML
models must be shadow-tested, monitored for drift and bias, and cannot directly
change payment state or suspend drivers without a reviewed rule/workflow.

## Scale path

The current Django bounded context is microservice-ready:

- UUID identifiers and no cross-module balance ownership;
- append-only domain events plus transactional outbox;
- Celery scheduled dispatch and projection jobs;
- Redis WebSocket fan-out;
- indexed station, driver, trip, queue and GPS access paths;
- stateless APIs suitable for horizontal replication.

Before 100,000+ concurrent drivers, move geospatial candidate generation to
PostGIS (`PointField`, GiST indexes) and partition `DriverLocation` by time and
region. At national scale, shard dispatch by geographic cell/region, retain the
transactional assignment lock in the owning shard, and archive GPS data under
an explicit retention policy.

## Rollout gates

1. Controlled station pilot: one region, verified operators, wallet only.
2. Multi-station district: station queues, SOS operations and cash
   reconciliation exercised.
3. Regional fleet rollout: load, failover, GPS retention and regulator export
   validated.
4. National rollout: PostGIS/geocell dispatch, multi-region DR, push provider,
   map provider and telecom failover certified.

No rollout gate is passed by code presence alone. Load, field operations,
security, privacy, safety response and payment reconciliation evidence are
required.
