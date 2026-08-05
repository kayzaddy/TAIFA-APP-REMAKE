# Taifa Express — Dispatch Guide

## Principle

No manual rider assignment. Merchant READY triggers smart dispatch.

## Happy path

```
Checkout (wallet)
  → merchant_found / merchant_accepted
  → paid + preparing
  → merchant READY (or auto_ready)
  → trips.create_trip (delivery_bike)
  → trips.dispatch_trip
  → trips.Delivery POD (package verification pin)
  → rider_assigned
```

## Package

Every order gets:

- `package_code` — `pkg_…`
- `package_qr` — `taifa://express/pkg/{code}`
- `packing_checklist` — line items, marked packed on READY
- `delivery_pin` — customer POD code (hashed on `trips.Delivery`)

## API

`POST /api/v1/express/orders/{id}/ready` → `merchant_ready` → auto dispatch.

`POST /api/v1/express/orders/{id}/advance` with `{ "stage": "picked_up" | "on_the_way" | "delivered" | "completed" }` mirrors live timeline.

## Ranking inputs (merchant)

Distance · inventory coverage · prep time · rating · reliability · workload.

## Ranking inputs (rider)

Reuse Mobility `dispatch_trip` (nearest / station-first strategy). Express does not re-implement matching.
