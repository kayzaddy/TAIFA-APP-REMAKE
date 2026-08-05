# Winga Marketplace Guide

Catalog and discovery for the brokerage platform (not a standalone e-commerce mall).

## Concepts

| Concept | Purpose |
| --- | --- |
| Domain | Industry vertical (`retail`, `hotels`, `logistics`, …) |
| Category | Nested taxonomy within a domain |
| Offering | Listable product/service/booking/rental/referral |
| Favorite | Customer shortlist |
| Collection | Group via offering `attributes.collection` (config) |

## Search

`GET /api/v1/winga/offerings?domain=hotels&kind=booking&q=beach`

Filters: `domain`, `kind`, `q` (title contains). Extend with attribute filters via `attributes` JSON without schema migrations.

## Booking payload

Deals carry `booking` JSON for appointments/reservations:

```json
{
  "start": "2026-08-01T14:00:00Z",
  "end": "2026-08-03T10:00:00Z",
  "guests": 2,
  "resource_id": "room-12",
  "cancellation_policy": "flexible"
}
```

Availability rules live on `Offering.availability` (config-driven).

## Recommendations

`POST /api/v1/winga/assist` with `capability=recommendations` — advisory only.
