# Winga Property — Phase 3: Virtual Property Experience

**Status:** COMPLETE  
**Depends on:** Phase 1 foundation, Phase 2 discovery

## Scope delivered

| Capability | Implementation |
| --- | --- |
| Property gallery | Extended `PropertyMedia` (HD, tour kinds) |
| Room-by-room walkthrough | `tour_kind=walkthrough` + `room_code` per room |
| Video / guided tours | `video_tour`, `guided_tour` media kinds |
| Interactive floor plan | `floor_plan` + `floor_plan_data` JSON |
| 360° architecture | `panorama_360` + `panorama_url` (VR-ready flag) |
| Viewing Pass | `PropertyViewingPass` — single, bundle, unlimited plans |
| Paid unlock | Address, navigation, contact, scheduling via wallet |
| QR verification | `qr_token` + `/viewing-pass/verify` |
| Live property mode | `PropertyLiveSession` + Q&A messages |
| AI transcript | Generated on session end via `ecosystem.ai` |
| Listing masking | Detail API redacts address/contact until pass active |

## Payments (ledger-backed)

Viewing Pass payments use `enterprise.orchestrator.capture_merchant_payment` via `commerce.services.ensure_platform_commerce_merchant` — same path as other Taifa commerce flows. AI does not authorize payments.

## API endpoints

| Method | Path | Description |
| --- | --- | --- |
| GET | `/listings/{id}/experience` | Gallery, walkthrough, floor plans, 360 |
| GET | `/viewing-pass/plans` | Available pass plans |
| GET/POST | `/viewing-pass` | List / create pass |
| POST | `/viewing-pass/{id}/pay` | Wallet payment (`Idempotency-Key`) |
| POST | `/viewing-pass/verify` | QR token verification |
| POST | `/viewing-pass/unlock/{listing_id}` | Apply bundle pass to listing |
| GET/POST | `/listings/{id}/live-sessions` | List / request live tour |
| GET | `/live-sessions/{id}` | Session detail |
| POST | `/live-sessions/{id}/start` | Owner starts stream |
| POST | `/live-sessions/{id}/join` | Customer joins |
| POST | `/live-sessions/{id}/end` | End + AI transcript |
| GET/POST | `/live-sessions/{id}/messages` | Live Q&A |

## Flutter UX

- Detail sheet: **Virtual tour**, **Viewing Pass**, **Live tour** actions
- Virtual tour sheet: room-by-room walkthrough + floor plan
- Viewing Pass sheet: plan picker + wallet pay
- Live session sheet: join code, live indicator, end tour + transcript

## Tests

`winga_property.tests` — 14 tests (Phase 1–3)

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py seed_winga_property
.venv\Scripts\python.exe manage.py test winga_property -v 1
```

## Phase 4 (not implemented)

AI + Human Winga — copilot, assignment, secure chat, CRM.
