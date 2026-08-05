# 4. Invoice Guide

Digital invoices support:

- Line items JSON
- Invoice QR
- Partial payments (`allow_partial`)
- Installment plan JSON
- Status tracking (`open` → `partially_paid` → `paid`)
- Reminders counter (ops-driven)

Settlement tracking is via Payments `payment_ref` + merchant_payable — not a MAP balance.

`POST /api/v1/map/merchants/{id}/invoices`
