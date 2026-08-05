# Phase 1 — Transit Home + Digital Ticket MVP (DART / Mwendokasi)

**Status:** **COMPLETE** — E2E demo verified (purchase + validate + replay rejection)  
**Depends on:** `trips` national models, Taifa Payments, Taifa Identity  
**Out of scope:** Live AVL map, NFC tap, control center, driver schedule app

## Objective

Ship a **production-shaped foundation** for Tanzania BRT inside Taifa Super App:

- Passenger discovers DART routes and stations  
- Buys a single-ride digital ticket via **Taifa Wallet**  
- Receives **signed QR** boarding pass  
- Conductor validates ticket via API (foundation for Module 9)  
- Architecture ready for Phases 2–20 without rework  

## User stories (Module 1 + 7 + 9 partial)

| ID | Story |
| --- | --- |
| P1-01 | As a passenger, I see a **Transit Home** with my location, nearby BRT stations, and wallet balance |
| P1-02 | I can **search** a destination and see matching DART routes |
| P1-03 | I can view **route detail** (stops, fare, operator DART) |
| P1-04 | I can **buy a single ticket** with wallet (idempotent) |
| P1-05 | I see **QR boarding pass** with expiry and route metadata |
| P1-06 | Staff can **validate** QR (offline-capable token verification) |
| P1-07 | I see **recent tickets** and **travel alerts** placeholder on home |

## Backend deliverables

### 1. Domain extensions (`trips`)

Extend `PublicTransitRoute.metadata` convention:

```json
{
  "operator": "DART",
  "mode": "brt",
  "brand": "Mwendokasi",
  "corridor": "phase_1",
  "color": "#00A651"
}
```

New models (migration `brt_phase1`):

| Model | Purpose |
| --- | --- |
| `TransitStationProfile` | Rich station: image, facilities, accessibility, platform, exits |
| `TransitAlert` | Service announcements (delay, maintenance) |
| `TransitTicketProduct` | Catalog: single, daily (pass types expanded Phase 2) |

Enhance `TransportTicket`:

- `signature` / `token_hash` for tamper detection  
- `media_payload` encrypted QR JSON  
- `validation_count`, `max_validations` (one-time default)  
- `route` FK, `origin_stop`, `destination_stop`  

### 2. APIs (`/api/v1/trips/transit/...`)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/transit/home` | Bundled: nearby stations, alerts, wallet hint, recent tickets |
| GET | `/transit/routes` | List DART routes (`?region=Dar es Salaam&mode=brt`) |
| GET | `/transit/routes/{id}` | Route + stops + next departures |
| GET | `/transit/stations/nearby` | Geo query stations |
| GET | `/transit/stations/{code}` | Station profile + upcoming buses (scheduled, not live AVL) |
| POST | `/transit/tickets/purchase` | Wallet capture + issue QR ticket |
| GET | `/transit/tickets/mine` | Passenger ticket wallet |
| POST | `/transit/tickets/validate` | Conductor scan (RBAC: `transit.validator`) |
| GET | `/transit/search` | Destination / route search |

**Payments:** `enterprise.orchestrator.capture_merchant_payment` with DART merchant sector `mobility_transit`.  
**Never** store balances in mobility tables.

### 3. Seed data (`seed_mobility_brt`)

DART Phase 1 illustrative corridor:

- **Kimara ↔ Kivukoni** (representative stops: Kimara, Ubungo, Morocco, Kariakoo, Posta, Kivukoni)  
- Fares in TZS minor units  
- 2–3 daladala routes as `metadata.mode: daladala` for future expansion demo  

### 4. Security (Phase 1)

| Control | Implementation |
| --- | --- |
| Auth | `IsDevice` passenger; validator role via `PlatformRole` |
| QR | HMAC-SHA256 over ticket payload + rotating kid |
| Idempotency | Required on purchase |
| Rate limit | Validate endpoint throttled |
| Audit | `TransitAuditEvent` on issue/validate |
| OWASP | Input validation, no secrets in QR plaintext |

### 5. Tests

`trips/test_brt_phase1.py` — target **12+** tests:

- Seed idempotency  
- Home bundle  
- Route list/filter  
- Ticket purchase + wallet debit  
- QR validate success / expired / replay  
- RBAC deny validator without role  

## Flutter deliverables

### New feature module: `features/mobility_transit/`

```
mobility_transit/
  domain/          # TransitRoute, TransitStation, TransitTicket
  application/     # providers, repository interface
  presentation/    # TransitHomeScreen, RouteDetail, TicketWallet, QrBoardingPass
```

**Route:** `/mobility/transit` (nested under existing `/mobility` hub)

### UI (Module 1)

- **Transit Home** — glass header, wallet chip, nearby stations carousel, search bar  
- **Route detail** — stop timeline (CityMapper-style), buy CTA  
- **Ticket wallet** — Apple Wallet–inspired cards  
- **QR pass** — fullscreen QR + countdown + brightness boost  
- Dark + light theme via existing `TaifaTheme`  

### Data layer

- `lib/data/trips/transit_api_paths.dart`  
- `RestTransitRepository` + `SeedTransitRepository`  
- Extend `MobilityOpsClient` or dedicated client  

**Maps:** Phase 1 uses static stop list + simple map pins; **no** live bus animation yet.

## NFC (Module 10 — architecture only)

- `TransportTicket.media_type` already supports `nfc`  
- Phase 1: document `NfcBoardingPort` interface in domain layer (no hardware impl)  
- Validator API accepts `media_type` discriminator for Phase 5  

## Documentation

- This file + API section in `docs/NATIONAL_API.md` (append transit paths)  
- Runbook: [RUNBOOK_PHASE1.md](RUNBOOK_PHASE1.md)  

## Acceptance criteria

- [x] `seed_mobility_brt` loads DART demo corridor  
- [ ] Passenger buys ticket E2E on device with funded wallet  
- [x] QR validates once; second scan rejected (backend tests)  
- [ ] Flutter analyze 0 issues on `mobility_transit`  
- [x] Backend phase tests green  
- [x] No duplicate payment or identity logic  
- [ ] Product owner sign-off  

## Estimated engineering sequence (after approval)

1. Backend models + migration + seed  
2. Services + APIs + RBAC + tests  
3. Flutter domain + repository  
4. Transit Home + purchase + QR UI  
5. Docs + demo script  
6. **Stop for Phase 1 review**  

---

**Approve Phase 1 to begin implementation.**
