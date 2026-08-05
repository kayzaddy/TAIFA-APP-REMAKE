# Winga Property — API

Base: `/api/v1/winga-property/`  
Auth: Device JWT (`IsDevice`)

## Catalog

| Method | Path | Description |
| --- | --- | --- |
| GET | `/categories` | Property categories |
| GET | `/types?category=` | Property types |

## Owners

| Method | Path | Description |
| --- | --- | --- |
| GET | `/owners/me` | Current owner profile |
| POST | `/owners/me` | Create/update owner profile |

## Listings

| Method | Path | Description |
| --- | --- | --- |
| GET | `/listings` | Search (`q`, `category`, `type`, `region`, `min_price`, `max_price`, `beds`, `verified`, `mine`) |
| POST | `/listings` | Create listing |
| GET | `/listings/{id}` | Detail (records recently viewed) |
| PATCH | `/listings/{id}` | Update (owner only) |
| DELETE | `/listings/{id}` | Soft-delete (owner only) |
| POST | `/listings/{id}/media` | Add photo/video URL |
| POST | `/listings/{id}/submit-verification` | Submit for review |
| POST | `/listings/{id}/verify` | Approve/reject (ops) |
| GET | `/listings/{id}/verification-history` | Audit trail |

## Discovery (Phase 1)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/map/pins` | GeoJSON-style pin list |
| GET/POST | `/favorites` | List / toggle favorite |
| GET/POST | `/saved-searches` | List / create saved search |

## Discovery (Phase 2)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/discovery/search` | Advanced search (`lifestyle`, `min_walkability_e4`, `min_safety_e4`, + Phase 1 filters) |
| POST | `/discovery/ai-search` | Natural-language search (`query`, `lifestyle`, `neighborhood`) |
| GET | `/discovery/recommendations` | AI recommendations from favorites + views |
| GET | `/discovery/recently-viewed` | Recently viewed listings |
| POST | `/discovery/compare` | Compare up to 4 listings (`listing_ids`) |
| GET | `/listings/{id}/intelligence` | Neighborhood scores + nearby POIs |
| GET | `/listings/{id}/commute` | Commute estimate (`dest_lat`, `dest_lng`, `mode`) |
| GET | `/listings/{id}/visit-score` | Visit decision score 1–5 stars |
| GET | `/map/clusters` | Grid-clustered map pins |

## Virtual Experience (Phase 3)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/listings/{id}/experience` | Gallery, walkthrough, floor plans, 360° |
| GET | `/viewing-pass/plans` | Viewing Pass plan catalog |
| GET/POST | `/viewing-pass` | List / create pass |
| POST | `/viewing-pass/{id}/pay` | Wallet payment (`Idempotency-Key`) |
| POST | `/viewing-pass/verify` | QR verification |
| POST | `/viewing-pass/unlock/{listing_id}` | Apply bundle pass to listing |
| GET/POST | `/listings/{id}/live-sessions` | Live tour request / list |
| POST | `/live-sessions/{id}/join` | Join live walkthrough |
| POST | `/live-sessions/{id}/end` | End session + AI transcript |
| GET/POST | `/live-sessions/{id}/messages` | Live Q&A |

## AI + Human Winga (Phase 4)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/copilot/chat` | AI property copilot (`query`, optional `listing_id`) |
| GET | `/copilot/rankings` | Rank listings by visit score (`listing_ids`) |
| POST | `/listings/{id}/negotiation-assist` | Negotiation hints (`offer_minor`) |
| POST | `/listings/{id}/relocation-assist` | Relocation advice (`destination`) |
| GET | `/wingas` | Verified property Wingas |
| GET | `/wingas/leaderboard` | Trust leaderboard |
| POST | `/listings/{id}/assign-winga` | Assign human Winga + CRM case |
| GET | `/assignments` | Customer assignments |
| GET | `/assignments/{id}` | Assignment detail + timeline |
| GET/POST | `/assignments/{id}/chat` | Secure chat messages |
| GET/POST | `/assignments/{id}/documents` | Document sharing |
| GET/POST | `/assignments/{id}/appointments` | Viewing appointments |
| GET | `/assignments/{id}/commission-preview` | Commission preview (no payment) |

## Digital Transactions (Phase 5)

| Method | Path | Description |
| --- | --- | --- |
| POST | `/listings/{id}/applications` | Create rental application |
| GET | `/applications` | List my applications |
| GET | `/applications/{id}` | Application detail (+ lease if exists) |
| POST | `/applications/{id}/submit` | Submit application |
| POST | `/applications/{id}/documents` | Upload document (`kind`, `title`, `url`) |
| POST | `/applications/{id}/verify-identity` | NIDA identity check |
| POST | `/applications/{id}/verify-income` | Income-to-rent ratio check |
| POST | `/applications/{id}/approve` | Approve after verifications |
| POST | `/applications/{id}/generate-lease` | Generate digital lease |
| GET | `/leases/{id}` | Lease detail |
| POST | `/leases/{id}/sign` | E-sign lease |
| POST | `/lease-payments/{id}/pay` | Pay deposit/rent (`Idempotency-Key`) |
| POST | `/leases/{id}/renew` | Renew lease (`months`) |
| POST | `/leases/{id}/move` | Schedule move-in/out |
| POST | `/move-workflows/{id}/complete` | Complete move checklist |

## Enterprise Operations (Phase 6)

| Method | Path | Description |
| --- | --- | --- |
| GET | `/ops/dashboard` | Executive KPIs (`region`) |
| GET | `/ops/analytics` | Analytics + conversion funnel (`region`, `days`) |
| GET | `/ops/moderation-queue` | Pending reports + verifications |
| POST | `/listings/{id}/report` | Report listing (`reason`, `notes`) |
| GET | `/listings/{id}/fraud-signals` | Advisory fraud signals |
| GET | `/applications/{id}/fraud-signals` | Application fraud signals |
| POST | `/ops/moderation/{id}/resolve` | Resolve report (`action`, `notes`) |
| POST | `/ops/listings/{id}/suspend` | Suspend listing |
| GET/POST | `/ops/disputes` | List / open disputes |
| POST | `/ops/disputes/{id}/assign` | Assign ops agent |
| POST | `/ops/disputes/{id}/resolve` | Resolve dispute |
| GET | `/ops/console` | Bundled ops console payload (RBAC) |
