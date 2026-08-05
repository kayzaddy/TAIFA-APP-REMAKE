# 2. QR Specification

## Kinds

| Kind | Amount | Intent | Use |
| --- | --- | --- | --- |
| `static` / `merchant` | At scan time | Created on pay | Counter / sticker |
| `dynamic` | Fixed | Bound | One-shot amount |
| `invoice` / `order` / `campaign` | Fixed | Bound | Documented payables |
| `branch` / `terminal` | Via refs | Optional | Routing metadata |
| `offline` | Future | Future | Cached signed payload |

## Canonical payload

```
taifa://pay/{merchant_code}?q={public_code}&a={amount_minor}&c={currency}&i={intent_code}&e={expires_epoch}&s={hmac}
```

Empty `a` / `i` / `e` allowed for static merchant QR.

## Security

- HMAC-SHA256 over intent fields (`public_code`, merchant, amount, currency, channel, expiry)
- Expired intents refuse pay
- Replay blocked by intent status + Idempotency-Key on capture

## API

`POST /api/v1/map/merchants/{id}/qr`  
`GET /api/v1/map/merchants/{id}/qr/library`  
`POST /api/v1/map/merchants/{id}/qr/static/pay`
