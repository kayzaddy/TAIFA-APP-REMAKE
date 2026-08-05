# 06 — Maps Platform

**Bounded context:** `platform.maps`  
**Phase 1:** Geocoding, routing, places facade

---

## Purpose & business value

One **maps adapter** (Mapbox/Google/OSM) for Mobility, Tourism, Express—geocode, reverse geocode, route, distance, nearby search, traffic—cached and rate-limited.

---

## Responsibilities

Adapter abstraction · quota management · response cache · no tile hosting (provider CDN).

---

## Architecture

Domains → `MapsPort` → `integrations.maps.HttpMapsAdapter` (`TAIFA_MAPS_PROVIDER_JSON`).

---

## APIs

GET `/platform/maps/geocode` · `/reverse` · `/route` · `/places/search` · `/distance`

---

## Events

`maps.quota.warning` (ops)

---

## Database

Optional `maps_cache` (query hash, response, expires_at) in Redis.

---

## Security

API keys in Secrets Manager; no client-side provider keys in prod.

---

## AWS

ElastiCache · ECS facade · outbound HTTPS only.

---

## Roadmap

Offline tile packs · national addressing (TTB) dataset integration
