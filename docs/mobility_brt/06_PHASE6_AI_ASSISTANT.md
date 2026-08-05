# Phase 6 — AI Travel Assistant

**Status:** COMPLETE  
**Module:** 6 (AI travel assistant — Kiswahili + English)

## Scope

Bilingual natural-language assistant for Mwendokasi BRT passengers:

- Parse Swahili/English journey requests (`kutoka Kimara hadi Kivukoni`, `from Ubungo to Kariakoo`)
- Resolve commute shortcuts (`kazini`, `nyumbani`) from passenger profile home/work stops
- Rank planner options via Taifa AI OS `route_optimization` (advisory)
- Generate conversational replies via `voice_assistant` / `natural_language`
- Suggest actions: open planner, buy ticket, open station

## Backend

### API

| Method | Path | Description |
| --- | --- | --- |
| GET | `/transit/assistant?q=&locale=&region=` | Quick assistant query |
| POST | `/transit/assistant` | Body: `{query, locale?, region?, origin_stop?, destination_stop?}` |

### Service

`transit_ai_assistant()` in `transit_services.py`:

- NL stop extraction + locale detection
- `plan_transit_journey()` when origin/destination resolved
- `search_transit()` for station/route discovery queries
- `invoke_ai()` for reply + plan ranking (domain `mobility_transit`)

### Tests

`trips/test_brt_phase6.py` — 5 tests (Swahili/English journey, search, profile commute, validation).

## Flutter

| Surface | Route | Notes |
| --- | --- | --- |
| `TransitAssistantScreen` | `/mobility/transit/assistant` | Chat UI, locale toggle, quick chips |
| `TransitAssistantController` | provider | Message history + `askAssistant()` |
| Transit home | button | “Ask Mwendokasi AI” |

## Verification

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 trips.test_brt_phase2 trips.test_brt_phase3 trips.test_brt_phase4 trips.test_brt_phase5 trips.test_brt_phase6 -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit
flutter test test/mobility_transit
```

## Next: Phase 7

Family / guardian flows (module 13).
