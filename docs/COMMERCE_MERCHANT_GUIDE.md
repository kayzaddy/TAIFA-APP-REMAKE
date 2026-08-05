# Taifa Commerce — Merchant Guide

**API base:** `/api/v1/mos/`  
**Auth:** Device token (same as wallet)

---

## 1. Bootstrap your business

```http
POST /api/v1/mos/bootstrap
{ "code": "my-shop", "legal_name": "My Shop Ltd", "business_type": "retail" }
```

Creates/activates `enterprise.Merchant`, MOS profile, HQ branch, main warehouse.

Settlement identity remains the enterprise Merchant — see [`MERCHANT_GUIDE.md`](MERCHANT_GUIDE.md).

---

## 2. Catalog

`POST /merchants/{merchant_id}/products` — SKU, name, price_minor, kind (`physical|digital|service|subscription|bundle`).

Publish to Winga (brokerage discovery):

`POST /merchants/{merchant_id}/products/{product_id}/publish-winga`

---

## 3. Inventory

`POST /merchants/{merchant_id}/stock/adjust`  
`{ "warehouse_id", "product_id", "kind": "receive|issue|adjust|reserve|release|count", "quantity" }`

---

## 4. Sell (POS / online)

1. `POST …/orders` with `lines: [{ product_id, quantity }]`  
2. `POST …/orders/{id}/pay` with header `Idempotency-Key`  
3. `POST …/orders/{id}/fulfill`

Money moves only through Taifa Payments / enterprise capture.

---

## 5. AI assist

`POST …/assist` with `capability`: `inventory_forecast` | `pricing` | `demand`  

`authorize_payment` is **always blocked**.

---

## 6. Analytics

`GET …/analytics/summary` — products, orders, GMV, low stock, Winga flag.
