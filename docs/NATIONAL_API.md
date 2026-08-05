# National Mobility API

Base: `/api/v1/trips/`  
Auth: device session (`IsDevice`) + enterprise RBAC where noted.  
OpenAPI tags: `mobility-national`, `mobility-intercity`, `mobility-public-transit`, etc.

## National Operations

| Method | Path | Permission |
| --- | --- | --- |
| GET | `national/command-center` | `mobility.operations` |
| GET | `national/map?region=` | `mobility.operations` |
| GET | `national/analytics?region=&days=` | `mobility.operations` |
| GET | `national/optimization` | `mobility.operations` |
| POST | `national/reports` | `mobility.operations` |

## Intercity

| Method | Path |
| --- | --- |
| GET/POST | `intercity/corridors` |
| GET/POST | `intercity/departures` |
| POST | `intercity/departures/{id}/book` |

Booking returns `ticket_code` and instructs fare capture via Taifa Payments.

## Public transit & ticketing

| Method | Path |
| --- | --- |
| GET/POST | `public-transit/routes` |
| POST | `public-transit/tickets` |
| POST | `public-transit/tickets/validate` |

Ticket types: `single`, `qr`, `nfc`, `wallet`, `corporate_pass`, `monthly_pass`, `student_pass`, `government_card`.

## Taifa Mobility BRT (Mwendokasi / DART) — Phase 1

Base: `/api/v1/trips/transit/`  
Auth: `IsDevice` (passenger); `transit-validator` role for validate.

| Method | Path | Description |
| --- | --- | --- |
| GET | `transit/home` | Nearby stations, featured routes, alerts, recent tickets (`?mode=brt\|daladala`) |
| GET | `transit/modes` | Mode catalog (BRT, Daladala) with route counts |
| GET | `transit/routes` | List routes (`?region=&mode=brt`) |
| GET | `transit/routes/{id}` | Route detail + scheduled departures |
| GET | `transit/stations/nearby` | Geo stations (`lat`, `lng`, `limit`) |
| GET | `transit/stations/{stop_code}` | Station profile + upcoming departures |
| GET | `transit/search` | Route/stop search (`q`, `region`) |
| POST | `transit/tickets/purchase` | Wallet capture + signed QR ticket (`Idempotency-Key` required) |
| GET | `transit/tickets/mine` | Passenger ticket wallet |
| POST | `transit/tickets/validate` | Conductor scan (RBAC) |
| GET | `transit/products` | Ticket/pass catalog |
| GET | `transit/plan` | Journey planner (`origin_stop`, `destination_stop`) |
| GET | `transit/driver/runs` | Driver scheduled BRT runs (`transit-driver` role) |
| PATCH | `transit/driver/runs/{id}` | Advance run status (`boarding` → `departed` → `completed`) |
| GET | `transit/map` | Live corridor map (polylines, stations, AVL vehicles) |
| POST | `transit/avl/ping` | Driver GPS update (`transit-driver` role) |
| WS | `ws/v1/mobility/transit/live/{region_slug}` | AVL snapshot + `transit.avl.update` events |
| GET/PATCH | `transit/profile` | Passenger profile, stats, favorites |
| GET/POST | `transit/favorites` | List / add station or route favorite |
| DELETE | `transit/favorites/{id}` | Remove favorite |
| GET/POST | `transit/notifications` | Notification inbox / mark read |
| GET/POST | `transit/feedback` | Trip feedback list / submit rating |
| POST | `transit/safety/sos` | Transit SOS → `SafetyIncident` |
| GET | `transit/analytics` | BRT corridor analytics (`mobility.operations`) |
| POST/PATCH | `transit/admin/routes` | Route admin |
| POST/PATCH | `transit/admin/products` | Pass product admin |
| GET/POST | `transit/assistant` | Bilingual NL travel assistant (AI advisory) |
| GET | `transit/family` | Guardian family bundle (members + family tickets) |
| GET/POST | `transit/family/members` | List / link family member |
| DELETE | `transit/family/members/{id}` | Remove family member |
| GET | `transit/lost-found` | Lost & found bundle (open + mine) |
| POST | `transit/lost-found` | Report lost or found item |
| POST | `transit/lost-found/{id}/claim` | Claim found item |
| POST | `transit/lost-found/{id}/resolve` | Resolve / confirm handoff |
| POST | `transit/lost-found/photo` | Upload item photo (base64) |
| GET | `transit/admin/lost-found` | Ops lost & found queue |
| POST | `transit/admin/lost-found/{id}/resolve` | Ops close / match item |
| POST | `auth/device/push-token` | Register device push token |

Payments: `capture_merchant_payment` sector `mobility_transit`. Seed: `python manage.py seed_mobility_brt`.

## Enterprise

| Method | Path |
| --- | --- |
| GET/POST | `enterprise/organizations` |
| GET/POST | `enterprise/organizations/{id}/employees` |
| POST | `enterprise/trips` |

## Emergency & logistics

| Method | Path |
| --- | --- |
| POST | `emergency/dispatch` |
| GET/POST | `logistics/shipments` |

## Open platform

| Method | Path |
| --- | --- |
| POST | `open/partners` | Issues API credential (raw key once) |
| GET | `open/catalog` | Versioned capability catalog |

## Versioning

- URL prefix `/api/v1/` is the public contract.
- Aggregation payloads include `model_version` (e.g. `national-command-center-v1`).
- Spectacular schema documents tags; CI fails on contract warnings.

## Developer notes

- Do not invent payment endpoints under Mobility.
- Do not bypass Registry for driver/vehicle activation.
- Prefer idempotent POSTs with client-generated keys where money is involved (Payments side).
