# Mode Expansion — Daladala & Multi-modal

**Status:** COMPLETE  
**Follows:** Production Hardening

## Scope

Extend Mwendokasi beyond DART BRT to include **daladala** (informal bus) and **multi-modal transfer plans** (e.g. daladala → BRT at shared stops like Kariakoo or Posta).

## Backend

### Products

Seed command adds daladala products alongside BRT:

| Code | Name | Mode | Fare (TZS) |
| --- | --- | --- | --- |
| `brt_single` | BRT Single Ride | brt | 650 |
| `brt_daily` | BRT Daily Pass | brt | 3,500 |
| `dala_single` | Daladala Single Ride | daladala | 800 |
| `dala_daily` | Daladala Daily Pass | daladala | 2,500 |

### Routes

Two daladala demo routes seeded in `seed_mobility_brt`:

- `dsm-dala-mwenge` — Mwenge → Posta (LATRA)
- `dsm-dala-sinza` — Sinza → Kariakoo (UDA)

### APIs

| Method | Path | Description |
| --- | --- | --- |
| GET | `transit/modes` | Mode catalog (BRT + Daladala) with route counts and sample products |
| GET | `transit/home?mode=` | Home bundle filtered by mode (`brt`, `daladala`, or empty for mixed) |

### Journey planner

`GET /transit/plan` returns `plan.v2` payloads with:

- **Direct** plans on a single route
- **Transfer** plans via shared stops (e.g. sinza → kivukoni via kariakoo: daladala leg + BRT leg)

Transfer plans include `transfer_stop` and `legs[]` for each segment.

### Ticket purchase

- Product mode must match route mode (BRT product on daladala route → rejected)
- Daladala tickets use `DALA-` media code prefix (BRT uses `BRT-`)

### Tests

`trips/test_brt_mode_expansion.py` — 6 tests covering modes catalog, filtered home, daladala purchase, product validation, and multimodal planner.

## Flutter

### Models

- `TransitMode` — mode catalog entry
- `TransitHome.mode` — active filter
- `TransitPlanOption.transferStop` / `legs` — transfer plan details

### Repository

- `loadModes()` — fetch mode catalog
- `loadHome(mode:)` — mode-filtered home bundle
- Seed repo mirrors daladala routes, products, and transfer plans offline

### UI

- **Home screen** — mode selector chips (All / Mwendokasi BRT / Daladala)
- **Route detail** — products filtered by route mode on purchase
- **Planner** — transfer badge, leg breakdown, "Buy 1st leg" for transfer plans

## Commands

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py seed_mobility_brt
.venv\Scripts\python.exe manage.py test trips.test_brt_mode_expansion -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit
flutter test test/mobility_transit
```

## Next steps

- Regional bus / rail mode stubs
- Full multi-leg wallet checkout (buy both legs in one flow)
- LATRA operator onboarding via mobility registry
