# Taifa Mobility — Tanzania BRT (Mwendokasi / DART)

**Program:** Taifa Super App · Mobility vertical  
**Version:** 1.0  
**Mode:** Enterprise  
**Status:** Mode expansion (daladala/regional) **COMPLETE**

## Vision

Tanzania's intelligent public transport platform — starting with **DART BRT (Mwendokasi)** and expanding to daladala, regional bus, rail, ferry, and national mobility.

**Primary goals:** reduce waiting time · increase transparency · digitize fares · integrate Taifa Wallet · scale to millions.

## Platform alignment (this monorepo)

| Spec item | TAIFA implementation |
| --- | --- |
| Mobile | Flutter (`apps/mobile`) |
| API | **Django + DRF** today (`apps/backend/trips`) — microservice-ready; FastAPI AVL service is a Phase 4+ option |
| Database | PostgreSQL (prod) / SQLite (dev) |
| Cache / realtime | Redis Channels for WebSocket fan-out |
| Identity | Taifa device auth + enterprise RBAC |
| Payments | Taifa Payments / Wallet — **no mobility ledger** |
| Maps | Maps gateway abstraction (replace mocks in passenger flows) |
| AI | Taifa AI OS (`ecosystem.invoke_ai`) — advisory routing, NL assistant |
| Registry | `mobility_registry` — operators, fleets, stations |

**Do not duplicate:** trip dispatch FSM, wallet engine, identity vault, or Winga-style commerce.

## Existing assets to extend

| Asset | Location | Reuse for BRT |
| --- | --- | --- |
| `PublicTransitRoute`, `PublicTransitTimetable`, `TransportTicket` | `trips/national_models.py` | DART lines, stops, fares, QR tickets |
| `Station`, `Fleet`, `Driver`, `Vehicle` | `trips/models.py` | BRT terminals, bus fleet, drivers |
| Public transit APIs | `trips/national_views.py` | Route browse, ticket issue/validate |
| WebSocket tracking | `trips/consumers.py` | Phase 3+ vehicle AVL |
| Flutter mobility shell | `features/mobility/` | Separate **Transit** product tab |
| Ops consoles | `station_ops`, `city_ops`, `national_ops` | Control center evolution |

**Gap:** No BRT/DART/mwendokasi-specific seed data, no passenger transit Flutter UI, no live fixed-route AVL.

## Module map → delivery phases

| Your module | Phase | Notes |
| --- | --- | --- |
| 1 Home | **1** | Transit hub: location, nearby stations, search, wallet, quick actions |
| 2 Live map | 3 | Requires AVL feed + map provider integration |
| 3 Bus tracking | 3 | Vehicle run model + GPS pipeline |
| 4 Station information | **2** | Rich station cards, facilities, arrivals |
| 5 Route planner | **2** | Multi-modal graph; AI ranking in Phase 6 |
| 6 AI travel assistant | 6 | Kiswahili + English via AI OS |
| 7 Taifa Wallet | **1** | Reuse wallet; ticket purchase idempotent capture |
| 8 Bus passes | **2** | Extend `TransportTicket` types + pass products |
| 9 QR boarding | **1** | Signed QR from existing ticket validate path |
| 10 NFC boarding | 5 | Architecture hooks only in Phase 1 |
| 11 Notifications | 4 | Event outbox → push templates |
| 12 Passenger profile | 4 | Travel stats, favourites, accessibility |
| 13 Family | 7 | Guardian flows |
| 14 Safety | 4 | Extend `SafetyIncident` + SOS |
| 15 Lost & found | 8 | New bounded context |
| 16 Feedback | 4 | Ratings + AI sentiment |
| 17 Driver app | **2** | Extend `mobility_driver` for scheduled runs |
| 18 Control center | 5 | Extend `city_ops` / `national_ops` |
| 19 Analytics | 5 | `MobilityDailyMetric` + BRT dashboards |
| 20 Admin panel | 5 | Registry + route/fare admin |

## Phase documents

| # | Document |
| --- | --- |
| 1 | [Phase 1 — Home + Digital Ticket MVP](01_PHASE1_HOME.md) |
| 2 | [Phase 2 — Stations, Planner, Passes & Driver Runs](02_PHASE2_STATIONS_PLANNER_PASSES.md) |
| 3 | [Phase 3 — Live Map + AVL](03_PHASE3_LIVE_MAP_AVL.md) |
| 4 | [Phase 4 — Notifications, Profile, Safety & Feedback](04_PHASE4_ENGAGEMENT.md) |
| 5 | [Phase 5 — Control Center, NFC, Analytics & Admin](05_PHASE5_OPS_NFC_ANALYTICS.md) |
| 6 | [Phase 6 — AI Travel Assistant](06_PHASE6_AI_ASSISTANT.md) |
| 7 | [Phase 7 — Family / Guardian](07_PHASE7_FAMILY.md) |
| 8 | [Phase 8 — Lost & Found](08_PHASE8_LOST_FOUND.md) |
| 9 | [Production Hardening](09_PRODUCTION_HARDENING.md) |
| 10 | [Mode Expansion — Daladala & Multi-modal](10_MODE_EXPANSION.md) |

## Quality gates (every phase)

1. Architecture review  
2. Schema migration review  
3. OpenAPI / contract tests  
4. Security checklist (RBAC, idempotency, audit)  
5. Performance budget (map 60fps, API p95)  
6. Documentation update  
7. **Stakeholder approval** before next phase  

## Commands (after Phase 1 implementation)

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py seed_mobility_brt
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit
flutter test test/mobility_transit
```
