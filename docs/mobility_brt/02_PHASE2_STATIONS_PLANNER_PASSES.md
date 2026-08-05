# Phase 2 — Stations, Route Planner, Passes & Driver Runs

**Status:** **COMPLETE**  
**Depends on:** Phase 1 transit home, ticketing, validation  
**Out of scope:** Live AVL map (Phase 3), AI assistant (Phase 6)

## Objective

Extend Mwendokasi BRT with passenger information depth and operational scheduling:

- Rich **station detail** with facilities and scheduled arrivals  
- **Multi-route journey planner** (BRT direct + daladala alternatives)  
- **Bus pass products** (single + daily) surfaced in purchase flow  
- **Driver scheduled runs** for fixed-route BRT shifts  

## Deliverables

### Backend

| Item | Description |
| --- | --- |
| `GET /transit/products` | Ticket/pass catalog |
| `GET /transit/plan` | Origin→destination journey options |
| `TransitScheduledRun` | Fixed-route driver assignment model |
| `GET /transit/driver/runs` | Driver's scheduled BRT runs |
| `PATCH /transit/driver/runs/{id}` | Check-in / depart / complete |
| `transit-driver` RBAC role | `mobility.transit.driver` |
| `test_brt_phase2.py` | Planner, products, driver run lifecycle |

### Flutter

| Screen | Route |
| --- | --- |
| Station detail | `/mobility/transit/station/:code` |
| Route planner | `/mobility/transit/plan` |
| Pass picker | Route detail bottom sheet |
| Driver BRT runs | Mobility Driver screen section |

## Acceptance criteria

- [x] Station detail shows facilities + upcoming departures  
- [x] Planner returns Kimara→Kivukoni direct BRT option  
- [x] Daily pass purchasable with 10 validations  
- [x] Driver can view and advance scheduled run status  
- [x] Phase 1 + Phase 2 tests green (20 total)
