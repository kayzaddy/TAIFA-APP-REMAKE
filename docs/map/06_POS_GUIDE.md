# 6. POS Guide

MAP terminals register POS / SoftPOS / NFC readers:

`POST /api/v1/map/merchants/{id}/terminals`

POS **sales** continue through Commerce MOS (`/api/v1/mos/.../orders/.../pay`) which already uses `capture_merchant_payment`.

MAP POS channel intents cover standalone counter acceptance (barcode/QR/wallet/cash marker in metadata). Split payments = multiple intents or partial invoice pays against the same merchant.

Receipt printing/sharing uses `AcceptanceReceipt` delivery preferences.
