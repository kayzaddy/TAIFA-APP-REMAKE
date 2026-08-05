# GIS Architecture — National Mobility

## Role

Provide a stable geographic fabric for the National Operations Center: regions → districts → stations → live trips / drivers / SOS, without locking the platform to a single spatial engine.

## Current contract

`national_map_layers(region=None)` →

```json
{
  "generated_at": "...",
  "layers": [
    {
      "region": "Dar es Salaam",
      "summary": { "stations": 12, "live_trips": 40, "open_sos": 1 },
      "stations": [ { "id", "name", "lat", "lng", "load", ... } ],
      "sos": [ ... ],
      "trips_sample": [ ... ],
      "drivers_sample": [ ... ]
    }
  ],
  "model_version": "national-map-v1"
}
```

City map snapshots (`city_map_snapshot`) remain the regional building block.

## Coordinate model

- WGS84 decimal degrees on trip, station, driver location, intercity, logistics, and emergency entities
- Distance ranking today: Haversine / service-radius filters in dispatch
- Future: PostGIS `geography` columns + spatial indexes; **same API shape**

## National layers (conceptual)

1. Administrative — region / district from Station attributes  
2. Network — stations, transfer points, intercity corridors  
3. Fleet — sampled driver locations  
4. Demand — intelligence hotspots / optimization expansion signals  
5. Safety — SOS + emergency dispatch overlays  
6. Traffic — reserved via `TRAFFIC` government adapter (feeds into pricing/ETA conditions)

## Simulations & testing

- `NationwideSimulationTests` builds multi-region station grids and asserts command-center / map layer counts
- GIS simulation = contract tests on layer presence, not pixel maps
- Traffic / mass dispatch simulations reuse Phase 2 city dispatch tests + national emergency/logistics paths

## Offline

Mobile clients cache last command-center / map payloads; writes queue through existing trip APIs when connectivity returns.
