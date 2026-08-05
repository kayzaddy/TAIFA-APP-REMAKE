# Taifa Express — Index

**Status:** Foundation (2026-07-18)  
**Nature:** Hyperlocal commerce **orchestration** — not a second marketplace, ledger, or payment engine  

Anything nearby. Delivered in minutes.  
Customer asks → Express ranks merchants → Commerce pays → Mobility delivers.

---

## Documents

| # | Doc |
| --- | --- |
| 1 | [Architecture](01_ARCHITECTURE.md) |
| 2 | [Merchant Guide](02_MERCHANT_GUIDE.md) |
| 3 | [Customer Guide](03_CUSTOMER_GUIDE.md) |
| 4 | [Rider Guide](04_RIDER_GUIDE.md) |
| 5 | [Operations Handbook](05_OPERATIONS.md) |
| 6 | [API Documentation](06_API.md) |
| 7 | [Deployment Guide](07_DEPLOYMENT.md) |
| 8 | [Security Manual](08_SECURITY.md) |
| 9 | [AI Guide](09_AI_GUIDE.md) |
| 10 | [Settlement Guide](10_SETTLEMENT.md) |
| 11 | [Dispatch Guide](11_DISPATCH.md) |
| 12 | [Smart Shopping List](12_SMART_SHOPPING_LIST.md) |

**API:** `/api/v1/express/`  
**Flutter:** `/express` · `/express/list` · `/express/basket` · `/express/track/:id`  
**Tests:** `express.tests` (10/10)  
**Seed:** `python manage.py seed_express`

**Fulfillment engine (2026-07-19):** packages · READY→auto-dispatch · settlement plan · live timeline · **Smart Shopping List**
