# Taifa Merchant Acceptance Platform (MAP) — Index

**Status:** Foundation complete (2026-07-19)  
**Principle:** Accept Everywhere · Process Once · Settle Once  

MAP is the unified **customer payment acceptance layer**. It is **not** a payment system.

| Owns (MAP) | Owns (Payments Platform) |
| --- | --- |
| Channels, QR, links, invoices, checkout UX | Authorization, capture, ledger |
| Merchant presentation & receipts | Settlement, refunds, risk, treasury |
| Payment Intent (acceptance control plane) | Transaction + LedgerEntry |

**Never:** second ledger · merchant balances in MAP · settlement logic in MAP.

---

## Documents

| # | Doc |
| --- | --- |
| 1 | [Architecture](01_ARCHITECTURE.md) |
| 2 | [QR Specification](02_QR_SPECIFICATION.md) |
| 3 | [Payment Link Guide](03_PAYMENT_LINK_GUIDE.md) |
| 4 | [Invoice Guide](04_INVOICE_GUIDE.md) |
| 5 | [Checkout Guide](05_CHECKOUT_GUIDE.md) |
| 6 | [POS Guide](06_POS_GUIDE.md) |
| 7 | [Merchant Guide](07_MERCHANT_GUIDE.md) |
| 8 | [API Documentation](08_API.md) |
| 9 | [Deployment Guide](09_DEPLOYMENT.md) |
| 10 | [Operations Manual](10_OPERATIONS.md) |

**Code:** `apps/backend/acceptance/` · API `/api/v1/map/` · Flutter `/map`  
**Money path:** `enterprise.PlatformOrchestrator.capture_merchant_payment`  
**Seed:** `python manage.py seed_map`  
**Tests:** `python manage.py test acceptance` (7/7)
