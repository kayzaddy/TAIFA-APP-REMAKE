# Taifa Express — Architecture

## Mission

Bring the nearest products to the customer in the fastest, simplest way — without forcing the customer to choose shop, rider, or payment rail.

## Non-goals

- Do **not** duplicate Commerce MOS catalog engines, Winga brokerage, Payments ledger, or Mobility dispatch.
- Do **not** let AI authorize money movement.
- Do **not** invent a second settlement path.

## Control plane

```
Customer intent (search / list / AI prompt)
        │
        ▼
 ExpressStore + ExpressProduct   ← neighbourhood inventory profiles
        │
        ▼
 Smart ranking (distance · stock · prep · rating · workload)
        │
        ▼
 ExpressOrder (orchestration record)
        │
        ├─► commerce.FoodOrder + collect_food_order_payment
        │         └─► capture_merchant_payment → ledger
        │
        └─► trips.create_trip + dispatch_trip (delivery_bike)
```

## Reuse map

| Concern | Owner |
| --- | --- |
| Identity / device auth | Taifa Identity (`IsDevice`) |
| Money movement | Taifa Payments via Commerce pay helpers |
| Merchant acceptance / Tap | MAP (`/api/v1/map/`) |
| Delivery | Taifa Mobility (`trips`) |
| Wallet UX | Taifa Wallet |
| AI basket suggestions | Express rule assistant (+ Taifa AI later) |
| Storefront ops depth | Commerce MOS / Merchant Acceptance |

## Order lifecycle

```
basket_submitted → merchant_found → merchant_accepted
  → paid + preparing → ready → rider_assigned
  → picked_up → on_the_way → arriving → delivered → completed
```

`ExpressOrder` stores downstream refs only: `food_order_id`, `trip_id`, `delivery_id`, `payment_ref`, `package_code`, `settlement_plan`, optional `tap_session_code`.

Merchant **READY** automatically calls Mobility dispatch and attaches a `trips.Delivery` POD record.

## Delivery fee

Transparent formula: base + distance + urgency multiplier. Inputs logged on the order; no opaque black-box pricing in foundation.

## Observability

Prometheus counters:

- `taifa_express_orders_created_total`
- `taifa_express_orders_paid_total`
- `taifa_express_deliveries_requested_total`
- `taifa_express_ai_assists_total`
