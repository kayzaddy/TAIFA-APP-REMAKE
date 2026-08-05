# Winga Property — Phase 2: Discovery Experience

**Status:** COMPLETE  
**Depends on:** Phase 1 foundation (`winga_property`)

## Scope delivered

| Capability | Implementation |
| --- | --- |
| Advanced filters | Lifestyle, min beds, min safety score via `/discovery/search` |
| AI / NL search | `/discovery/ai-search` — reuses `ecosystem.ai.invoke_ai` + rule fallback |
| Recently viewed | `PropertyViewEvent` model + `/discovery/recently-viewed` |
| Property comparison | `/discovery/compare` (up to 4 listings) |
| AI recommendations | `/discovery/recommendations` from favorites + views |
| Neighborhood intelligence | `/listings/{id}/intelligence` — safety, water, power, nearby POIs |
| Commute calculator | `/listings/{id}/commute` — haversine + traffic factor |
| Visit decision score | `/listings/{id}/visit-score` — 1–5 stars |
| Clustered discovery map | `/map/clusters` + Flutter `PropertyDiscoveryMap` via Mobility `MapsProvider` |

## Reuse (no duplication)

- **AI:** `ecosystem.ai.invoke_ai` (`semantic_search`)
- **Mobility stations:** `trips.services.nearest_station`
- **Express merchants:** `express.services.rank_stores`
- **Maps (Flutter):** `MockMapsProvider` / `MapScene` from Mobility

## Flutter UX

- AI search toggle on browse screen
- Advanced filter chips (beds, safety, lifestyle)
- Recently viewed + recommendations carousels
- Compare mode (select up to 4, side-by-side sheet)
- Detail sheet: visit score, commute to CBD, neighborhood panel
- Discovery map with cluster chips

## Tests

`winga_property.tests` — Phase 1 + Phase 2 (11 tests)

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py test winga_property -v 1
```

## Phase 3 (not implemented)

Virtual tours, viewing pass, live property mode.
