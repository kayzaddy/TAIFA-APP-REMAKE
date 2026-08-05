# Taifa Mobility Hybrid Dispatch — Index

**Status:** Foundation (2026-07-21)  
**Nature:** Multi-channel dispatch **orchestration** — not a second trip engine, ledger, or payment stack.

Smartphone and feature-phone drivers participate in the **same** network. Passengers see only *"Finding your nearest driver…"* — never SMS, USSD, or IVR.

---

## Documents

| # | Doc |
| --- | --- |
| 1 | [Product Requirements (PRD)](01_PRD.md) |
| 2 | [Architecture](02_ARCHITECTURE.md) |
| 3 | [API Documentation](03_API.md) |
| 4 | [User Stories](04_USER_STORIES.md) |
| 5 | [Security](05_SECURITY.md) |
| 6 | [Deployment & Operations](06_DEPLOYMENT.md) |

**API:** `/api/v1/mobility-channels/`  
**Backend:** `apps/backend/mobility_channels/`  
**Flutter:** passenger polling via `MobilityOpsClient.hybridTripStatus`  
**Tests:** `mobility_channels.tests` (9/9)  
**Seed:** `python manage.py seed_hybrid_dispatch`  
**SMS simulation:** `python manage.py simulate_sms_ride [--accept]`

**Hooks:** `trips.dispatch_trip` → `fanout_dispatch_offers` · `trips.accept_offer` → `on_trip_accepted` (boarding PIN + passenger SMS)
