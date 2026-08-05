# Taifa Express — Settlement Guide

## Principle

One customer authorization. One ledger. Automatic allocation.

Express **does not** invent a second ledger. Capture remains:

`collect_food_order_payment` → `capture_merchant_payment` → Taifa Payments journal.

## Settlement plan (control plane)

After prepaid capture, Express stores `settlement_plan` on `ExpressOrder`:

| Party | Amount | Note |
| --- | --- | --- |
| Merchant | `subtotal_minor` | Goods |
| Rider | `delivery_fee_minor` | Mobility earnings path |
| Platform | `platform_fee_minor` | Taifa Express commission (~2%, min 200) |

`settlement_status`: `pending` → `allocated` (after pay) → `settled` (on order completed).

## Pay on delivery

When `payment_timing=on_delivery`:

1. Checkout skips wallet capture.
2. Merchant prepares; READY dispatches rider.
3. Rider SoftPOS / Tap & Pay via MAP captures at door.
4. Settlement plan allocates after successful Tap confirm.

## Ops rule

Merchant and rider payouts execute through existing enterprise settlement / trip earnings — never by mutating wallet balances outside Payments.
