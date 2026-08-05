# Phase 3 — Live Map + Bus Tracking (AVL)

**Status:** **COMPLETE**  
**Depends on:** Phase 1–2 transit APIs, Channels WebSocket stack  
**Out of scope:** External GPS hardware integrations, Google Maps SDK swap

## Objective

Passengers see **live BRT bus positions** on a corridor map; drivers publish GPS via AVL ping; updates fan out over WebSocket.

## Deliverables

### Backend

| Item | Description |
| --- | --- |
| `TransitAvlVehicle` | Latest GPS snapshot per vehicle |
| `GET /transit/map` | Route polylines, stations, active vehicles |
| `POST /transit/avl/ping` | Driver GPS update (`transit-driver` role) |
| `WS /ws/v1/mobility/transit/live/{region}` | AVL snapshot + live updates |
| Seed | 3 demo buses on Kimara—Kivukoni corridor |

### Flutter

| Screen | Route |
| --- | --- |
| Live map | `/mobility/transit/live` |
| Polling | 5s refresh of map snapshot |
| Driver ping | From Mobility Driver when advancing run |

## Acceptance criteria

- [x] Map shows 3+ seeded buses on DART corridor  
- [x] Driver AVL ping updates position  
- [x] Phase 3 tests green  
- [x] Flutter live map renders stations + buses  
