# 5. Checkout Guide

Remote checkout sessions wrap an `AcceptanceIntent` for:

- Share / web / mobile / embedded modes
- Return / cancel URLs
- Optional `sales_order_id`, `winga_deal_id`, `trip_id`

`POST /api/v1/map/merchants/{id}/checkout`

Completion = pay the session intent via Payments capture.
