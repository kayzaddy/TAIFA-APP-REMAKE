# National Architecture — Taifa Mobility

## Purpose

Define the reusable national transport platform for Tanzania: every region, multiple vehicle classes, enterprise and government fleets, logistics, public transport, and a National Operations Center — without forking Payments, Identity, or Registry.

## Bounded contexts

| Context | Owns | Does not own |
| --- | --- | --- |
| Trip / Dispatch | Lifecycle, offers, queue, pricing quote | Wallet balances, settlement |
| Station / City / National Ops | KPIs, maps, rankings, SOS workflow | Identity proofing |
| Intercity / PT / Tickets | Schedules, seats, media codes | Card acquiring |
| Logistics / Emergency | Shipment + emergency request wrappers | Clinical EMR / CAD cores |
| Enterprise | Org policy, employee enrollment | Payroll / HRIS SoT |
| Government adapters | Outbound statistics / future sync | Authority systems of record |
| Open platform | Partner API keys + catalog | Third-party product UX |

## Data principles

1. **Money**: store `payment_ref` / `fare_minor` snapshots only; capture via Taifa Payments.
2. **Eligibility**: drivers, vehicles, stations require Registry approvals where Phase 1–2 already enforce them.
3. **Audit**: regulatory reports persist adapter references + analytics payloads.
4. **Extensibility**: new vehicle modes are choice + pricing rule + dispatch filter — not new engines.
5. **Observability**: every aggregation returns `model_version` for safe ML/GIS swaps.

## Deployment topology

```text
[ Mobile / Partner / Municipality clients ]
                 │ HTTPS
         [ API (Gunicorn / ASGI) ]
           │           │
      [ Postgres ]  [ Redis + Celery ]
           │
   [ Object storage / logs / metrics ]
```

Regional failover: run read replicas per AZ; Celery beat for `mobility.build_national_daily_metrics` and city intelligence refresh; sticky device sessions via existing payments auth.

## Security

- Device-bound auth (`IsDevice`) on all mobility APIs
- Enterprise RBAC: `mobility.operations`, `mobility.national.read`, `mobility.regulatory.read`
- Partner keys hashed (`PartnerApiCredential.api_key_hash`); raw key shown once
- GPS / trip history restricted to owner + operators; government payloads are aggregates by default

## Evolution path

| Horizon | Change |
| --- | --- |
| Near | Live authority adapters replacing stubs |
| Mid | PostGIS national map; ML demand models behind same contracts |
| Long | Priority traffic / police escort modules consuming Emergency + Traffic adapters |
