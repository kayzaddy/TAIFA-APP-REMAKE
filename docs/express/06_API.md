# Taifa Express — API

Base: `/api/v1/express/`  
Auth: device bearer (`IsDevice`) + `X-Device-Id`

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/rank?lat=&lng=&q=&category=` | Rank nearby merchants |
| GET | `/stores` | List active storefronts |
| GET | `/products?q=&category=` | Search inventory |
| POST | `/ai/basket` | `{ "prompt": "Need breakfast" }` |
| POST | `/list/parse` | Smart Shopping List → matched basket |
| POST | `/quote` | Preview fees + best merchant |
| GET/POST | `/orders` | List / create order |
| GET | `/orders/{id}` | Order detail + timeline |
| POST | `/orders/{id}/accept` | Merchant accept |
| POST | `/orders/{id}/pay` | Pay (Idempotency-Key) |
| POST | `/orders/{id}/ready` | READY → auto-dispatch + POD |
| POST | `/orders/{id}/deliver` | Retry delivery trip |
| POST | `/orders/{id}/advance` | Live stage update |
| POST | `/checkout` | Place → accept → pay → READY → rider |

## Checkout body

```json
{
  "items": [{"name": "Milk", "qty": 1}, {"name": "Bread", "qty": 1}],
  "lat": -6.75,
  "lng": 39.28,
  "address": "Masaki",
  "notes": "Gate 2",
  "urgency": "standard",
  "payment_timing": "prepaid",
  "payment_method": "wallet",
  "auto_ready": true
}
```

Header: `Idempotency-Key: unique-key`

## Money

`pay` / prepaid `checkout` create a `FoodOrder` and call `collect_food_order_payment` → `capture_merchant_payment`.  
`payment_ref` is the ledger transaction id.  
`settlement_plan` allocates merchant / rider / platform amounts (control plane only).
