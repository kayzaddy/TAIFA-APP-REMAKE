# Taifa Mobility Hybrid Dispatch — Architecture

## Design principle

**Orchestrate, don't duplicate.** Trip creation, ranking, offers, fares, and settlement remain in `trips`. `mobility_channels` only decides *how to reach* each driver and processes *inbound* telco events.

```
Passenger request
        │
        ▼
 trips.create_trip + dispatch_trip
        │
        ├─► rank_drivers → DispatchOffer rows
        │
        └─► mobility_channels.fanout_dispatch_offers
                 │
                 ├─► select_channel(binding)
                 │      push → notify_mobility + IVR fallback timer
                 │      sms  → integrations.notifications + IVR fallback
                 │      ussd → session hint + IVR fallback
                 │      stage → notify_stage_dispatcher
                 │
                 ▼
        Driver accepts (app / SMS / USSD / IVR)
                 │
                 └─► trips.accept_offer
                          └─► on_trip_accepted
                                 ├─► TripBoardingPin (6-digit)
                                 ├─► passenger SMS (if msisdn in trip.metadata)
                                 └─► feature-phone driver contact SMS
```

## Models

| Model | Purpose |
| --- | --- |
| `DriverChannelBinding` | MSISDN, device capability, connectivity flags |
| `ChannelDispatchAttempt` | Audit per offer × channel |
| `InboundMessage` | SMS/USSD inbound log (MSISDN hashed) |
| `UssdSession` | Stateful USSD menu |
| `TripBoardingPin` | Hashed verification PIN |

## Integrations

| Integration | Module |
| --- | --- |
| Outbound SMS / push | `integrations.notifications` |
| Trip dispatch | `trips.services.dispatch_trip` |
| Accept/reject | `trips.services.accept_offer` |
| Station ops | `trips` station models + `StationManualDispatchView` |
| IVR fallback | Celery `mobility_channels.ivr_fallback` (25s countdown) |

## Scalability notes

- Channel selection is O(1) per offer; fan-out is bounded by dispatch batch size
- Inbound webhooks are stateless except USSD session rows (TTL via `expires_at` in future)
- MSISDN stored on binding; inbound logs use SHA-256 hash only
- For 100M+ users: shard telco webhooks by region; Redis for USSD session cache; read replicas for attempt audit

## Flutter passenger UX

`RideController` polls `GET /mobility-channels/trips/{id}/status` every 2s during `RidePhase.searching`. The `message` field is channel-agnostic copy from `passenger_status_message()`.
