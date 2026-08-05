# Phase 7 — Family / Guardian Flows

**Status:** COMPLETE  
**Module:** 13 (Family — guardian purchases for dependents)

## Scope

Guardians can link family members and buy Mwendokasi BRT tickets on their behalf:

- Link dependents by Taifa device owner ID (child, spouse, parent, other)
- Optional monthly spend limit per member (guardian wallet charged)
- Purchase tickets where `ticket.owner` = beneficiary; metadata records guardian
- Notifications to guardian and beneficiary on purchase
- Family bundle: members + recent tickets purchased for dependents

## Backend

### Model

`TransitFamilyMember` in `national_models.py`:

- `guardian_owner`, `member_owner` (unique pair)
- `display_name`, `relationship`, `status`, `can_purchase`, `monthly_limit_minor`

Migration: `0022_brt_phase7_family.py`

### API

| Method | Path | Description |
| --- | --- | --- |
| GET | `/transit/family` | Guardian bundle (members + recent family tickets) |
| GET | `/transit/family/members` | List active members |
| POST | `/transit/family/members` | Link member (`member_owner`, `display_name`, `relationship`, `monthly_limit_minor`) |
| DELETE | `/transit/family/members/{id}` | Soft-remove member |
| POST | `/transit/tickets/purchase` | Add `beneficiary_owner` for guardian purchase |

### Service

`transit_services.py`:

- `transit_family_bundle`, `add_transit_family_member`, `remove_transit_family_member`
- `purchase_transit_ticket(..., beneficiary_owner=)` — limit check, wallet capture, notifications

### Tests

`trips/test_brt_phase7.py` — 5 tests (add, bundle, guardian purchase, reject unlinked, remove).

## Flutter

| Surface | Route | Notes |
| --- | --- | --- |
| `TransitFamilyScreen` | `/mobility/transit/family` | Members list, add/remove, buy ticket |
| `TransitFamilyController` | provider | Bundle load, member CRUD, purchase for member |
| Transit home | button | “Family tickets” |

## Verification

```bash
cd apps/backend
.venv\Scripts\python.exe manage.py migrate
.venv\Scripts\python.exe manage.py test trips.test_brt_phase1 trips.test_brt_phase2 trips.test_brt_phase3 trips.test_brt_phase4 trips.test_brt_phase5 trips.test_brt_phase6 trips.test_brt_phase7 -v 1

cd apps/mobile
flutter analyze lib/features/mobility_transit
flutter test test/mobility_transit
```

## Next

Phase 8 — Lost & found (module 15). See [08_PHASE8_LOST_FOUND.md](08_PHASE8_LOST_FOUND.md).
