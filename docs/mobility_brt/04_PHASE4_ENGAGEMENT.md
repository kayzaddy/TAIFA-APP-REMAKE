# Phase 4 — Notifications, Profile, Safety & Feedback

**Status:** COMPLETE  
**Modules:** 11 (Notifications), 12 (Passenger profile), 14 (Safety/SOS), 16 (Feedback)

## Scope

Passenger engagement layer on top of Phase 1–3 BRT flows:

- **Profile** — home/work stops, accessibility prefs, travel stats, favorites
- **Notifications** — event outbox for ticket purchase, validation, SOS
- **Safety** — transit-scoped SOS via existing `SafetyIncident`
- **Feedback** — star ratings, tags, sentiment classification

## Backend

### Models (`trips/national_models.py`)

| Model | Purpose |
| --- | --- |
| `TransitPassengerProfile` | Commute stops, language, accessibility JSON |
| `TransitFavorite` | Station/route favorites |
| `TransitNotification` | Per-passenger outbox with deduplication |
| `TransitFeedback` | Ratings + sentiment |

Migration: `0020_brt_phase4_engagement.py`

### APIs

| Method | Path | Description |
| --- | --- | --- |
| GET/PATCH | `/transit/profile` | Profile bundle (stats + favorites) |
| GET/POST | `/transit/favorites` | List / add favorite |
| DELETE | `/transit/favorites/{id}` | Remove favorite |
| GET/POST | `/transit/notifications` | List / mark read |
| GET/POST | `/transit/feedback` | List / submit feedback |
| POST | `/transit/safety/sos` | Create `SafetyIncident` (kind=sos) |

Home bundle v2 adds `unread_notifications`.

Ticket purchase and validation hooks emit `transit.ticket.purchased` and `transit.ticket.validated` notifications.

### Tests

`trips/test_brt_phase4.py` — 7 tests (profile, favorites, notifications, feedback, SOS).

## Flutter

| Screen / widget | Route | Notes |
| --- | --- | --- |
| `TransitProfileScreen` | `/mobility/transit/profile` | Stats, stops, accessibility, favorites |
| `TransitNotificationsScreen` | `/mobility/transit/notifications` | Inbox + mark all read |
| `TransitFeedbackSheet` | modal | Star rating + tags |
| SOS FAB | transit home | Confirms + posts SOS |

Repository methods on `TransitRepository`; `TransitEngagementController` in providers.

## Verification

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 trips.test_brt_phase2 trips.test_brt_phase3 trips.test_brt_phase4 -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit
flutter test test/mobility_transit
```

## Next: Phase 5

Control center evolution, NFC boarding hooks, analytics dashboards (modules 10, 18, 19, 20).

**Delivered in Phase 5** — see `05_PHASE5_OPS_NFC_ANALYTICS.md`.
