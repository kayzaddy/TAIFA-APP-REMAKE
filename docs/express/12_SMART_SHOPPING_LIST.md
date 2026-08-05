# Taifa Express — Smart Shopping List

**Not** the AI Assistant. Dedicated list → basket → checkout → live track path.

## Customer flow (< 60 seconds)

```
Write Shopping List  →  Add To Basket  →  Review  →  CHECKOUT  →  Live Track
/express/list           parse API         /express/basket   pay+dispatch   /express/track/:id
```

## Parse API

`POST /api/v1/express/list/parse`

```json
{ "text": "Milk\n2 Bread\nEggs x30\nCooking Oil\nMilk 2L", "lat": -6.75, "lng": 39.28 }
```

Returns `matched`, `unknown`, `items` (checkout-ready), preferred merchant ranking.

### Quantity patterns

- `2 Milk` · `Milk x2` · `Two Milk` · `Milk 2L` · `Rice 5kg`

### Matching

Synonyms (oil / cooking oil / cook oil), Swahili tokens (maziwa, mkate, mayai…), fuzzy score vs inventory name + tags. Prefer top-ranked nearby store stock.

## Flutter routes

| Route | Screen |
| --- | --- |
| `/express` | Hub |
| `/express/list` | Write Shopping List |
| `/express/basket` | Basket Review + CHECKOUT |
| `/express/track/:orderId` | Live timeline + map |

Map reuses Mobility `MockMapView` / `MapScene` (merchant · rider · customer · route).
