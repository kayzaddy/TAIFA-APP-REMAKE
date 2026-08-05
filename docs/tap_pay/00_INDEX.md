# Taifa Tap & Pay — Index

**Status:** Foundation (2026-07-19)  
**Nature:** Interaction layer — **not** a payment engine  

Tap. Authenticate. Done.  
All money movement: MAP `pay_intent` → `capture_merchant_payment` → ledger.

---

## Documents

| # | Doc |
| --- | --- |
| 1 | [Architecture](01_ARCHITECTURE.md) |
| 2 | [NFC Integration Guide](02_NFC_INTEGRATION.md) |
| 3 | [Wallet Routing Guide](03_WALLET_ROUTING.md) |
| 4 | [Authentication Guide](04_AUTHENTICATION.md) |
| 5 | [Merchant Acceptance Guide](05_MERCHANT_ACCEPTANCE.md) |
| 6 | [Security Manual](06_SECURITY.md) |
| 7 | [Device Compatibility](07_DEVICE_COMPATIBILITY.md) |
| 8 | [Operations Handbook](08_OPERATIONS.md) |
| 9 | [Developer Documentation](09_DEVELOPER.md) |

**API:** `/api/v1/map/tap/*` · `/api/v1/map/funding/*`  
**Flutter:** `/tap` · `features/tap_pay/`  
**Tests:** `acceptance.tests_tap` (4/4)
