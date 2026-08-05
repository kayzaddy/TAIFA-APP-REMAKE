# TAIFA Delivery Roadmap

The mandated 20-phase order, with current status. We do not skip steps and we do
not ship placeholder business logic.

Legend: ✅ done · 🟢 foundation complete + real artifacts, extends per feature ·
🟡 in progress · ⬜ not started. Some phases are inherently continuous (they grow
with every new module) or gated on external accounts (cloud, Daraja prod, stores)
— those are marked and explained under the table.

| # | Phase | Status |
|---|-------|--------|
| 1 | Discovery | ✅ Workspace + canonical mockup analyzed |
| 2 | Product Definition | ✅ `docs/PRD.md` — vision, personas, JTBD, scope, metrics, NFRs |
| 3 | UX Analysis | ✅ 19 screens + flows inventoried from mockup |
| 4 | Extract Design System | ✅ Tokens, themes, typography encoded (`DESIGN_SYSTEM.md`) |
| 5 | Architecture | ✅ `docs/SYSTEM_ARCHITECTURE.md` — topology, principles, data flow |
| 6 | Database Design | 🟢 Payment schema built+migrated (append-only ledger, txns, idempotency, webhooks, devices); other domains specced in `DATA_MODEL.md` |
| 7 | API Contracts (OpenAPI) | ✅ OpenAPI 3 via drf-spectacular; Swagger `/api/docs`, Redoc, committed `openapi.yaml`, CI-validated |
| 8 | Mobile Architecture | ✅ Feature-first, Riverpod, GoRouter, `data/` layer |
| 9 | Backend Architecture | 🟢 Payment service (Django+DRF, engine, gateways, webhooks, device auth, request-id, health/readiness); new domains follow the same shape |
| 10 | Infrastructure | 🟢 CI (GitHub Actions), Dockerfile, dev + **prod** compose (gunicorn+nginx+release job); managed cloud/k8s wiring is your-account work |
| 11 | Security Review | 🟢 Device-bound tokens, owner scoping, throttling, prod TLS/HSTS/CORS lock-down; threat model in `SECURITY.md`; external pen-test pending |
| 12 | Build Shared Components | 🟢 Core design-system set; expands per feature |
| 13 | Build Feature Modules | 🟡 **Home** + **Wallet** shipped as real slices; remaining modules planned (no placeholder logic) |
| 14 | Integrate APIs | 🟢 **Wallet ↔ payment service live end-to-end**; other domains integrate via the same pattern |
| 15 | Testing | 🟢 208 tests (93 backend + 115 mobile) + analyze/schema gates in CI |
| 16 | Performance Optimization | 🟢 Budgets + techniques in `PERFORMANCE.md`; indexes + lazy loading in place; load tests planned |
| 17 | Production Deployment | 🟢 Prod compose + release procedure + runbook (`DEPLOYMENT.md`); live deploy needs your host/DNS/TLS |
| 18 | Monitoring | 🟢 Health/readiness, request-id, logs, Sentry + Prometheus `/metrics` + Alertmanager rules / Grafana JSON (`OBSERVABILITY.md`); live receiver secrets planned |
| 19 | Post-launch Improvements | 🟡 Backlog seeded (below); driven by real usage after launch |
| 20 | Regional Scaling (East Africa) | 🟢 Multi-currency/multi-rail core + strategy in `SCALING.md`; per-country rollout is future work |

### Gated on external resources (cannot be finalized from the repo)

- **Live cloud deploy** — needs a host/cluster, managed Postgres+Redis, DNS + TLS.
  Everything to do it is in `DEPLOYMENT.md`.
- **Real M-Pesa** — needs Safaricom/Vodacom **production** Daraja credentials + a
  public HTTPS callback URL. Adapter + config are ready.
- **App-store release** — needs Play/App Store accounts + signing certs.
- **External security review / pen-test** — independent audit before public launch.

### Continuous phases

Feature modules (13), shared components (12), performance (16) and monitoring (18)
are never "done" — they grow with each module. The pattern is proven by Wallet:
UI → domain → API → tests, wired end-to-end and gated by CI.

## Screen inventory (from mockup)

Home · Transportation · Food & Grocery · Digital Wallet · Tourist Mode · NFC
Tap-to-Translate · Housing/Stays · Government Services · AI Assistant ·
Chat & Social · Merchant Dashboard · Driver/Rider · Family Wallet · Voice+Offline
· TAIFA Life (Health/Edu/Insurance) · TAIFA Wealth (Harambee/Vault) · Logistics
& Jobs · Huduma (Home Services) · Ecosystem Overview.

## Feature module status

| Module | Status |
|--------|--------|
| Home | ✅ Vertical slice (dark+light, wallet, quick actions, services, promo) |
| Wallet | ✅ Vertical slice — Platinum card, currency switcher, live txns, **Send Money wired to the real backend** (`POST /transfers`) via a versioned REST client + device-bound auth, behind the same `WalletRepository` interface (see `docs/PAYMENTS.md`) |
| Food | 🟢 **Demo Complete (Foundation Sprint)** — restaurants → menu → cart → checkout → mock courier tracking → wallet pay → receipt/history; **`RestFoodOrderRepository`** persists to `/api/v1/commerce/food-orders` when remote |
| Hotels | 🟢 **Demo Complete (Foundation Sprint)** — search → hotel detail → dates/guests → rooms → reserve → wallet pay → receipt/history; **`RestStayBookingRepository`** persists to `/api/v1/commerce/stay-bookings` when remote |
| Flights | 🟢 **Demo Complete (Foundation Sprint)** — search DAR/ZNZ/JRO/NBO/EBB → results → hold seats → wallet pay → PNR receipt/history; **`RestFlightBookingRepository`** persists to `/api/v1/commerce/flight-bookings` when remote |
| Tourism | 🟢 **Demo Complete (Foundation Sprint)** — experiences (Stone Town, safari, reefs) → book guests/date → reserve → wallet pay → receipt/history; **`RestTourBookingRepository`** persists to `/api/v1/commerce/tour-bookings` when remote |
| Gov | 🟢 **Demo Complete + remote requests** — Huduma catalog seed; submit/pay/history via `/commerce/gov-requests` when remote |
| Health | 🟢 **Demo Complete + remote appointments** — facility catalog seed; book/pay/history via `/commerce/health-appointments` when remote |
| Education | 🟢 **Demo Complete + remote invoices** — school catalog seed; invoice/pay/history via `/commerce/edu-payments` when remote |
| Merchant | 🟢 **Demo Complete + remote kitchen** — orders hydrate/advance via `/commerce/merchant-orders` when remote |
| Driver | 🟢 **Demo Complete + remote offers** — jobs hydrate/update via `/commerce/driver-jobs` when remote |
| Chat | 🟢 **Demo Complete + remote inbox** — threads/messages via `/commerce/chat-threads` when remote |
| Admin | 🟢 **Demo Complete + remote ops queue** — cases advance via `/commerce/admin-cases` when remote |
| Housing | 🟢 **Demo Complete + remote inquiries** — listings seed; viewing/deposit via `/commerce/housing-inquiries` when remote |
| Winga Property | 🟢 **Phase 6 Enterprise Ops** — dashboard, analytics, fraud signals, moderation, disputes — see `docs/winga_property/09_PHASE6_OPS.md` |
| Wealth | 🟢 **Demo Complete + remote contributions** — Harambee circles seed; contribute/history via `/commerce/wealth-contributions` when remote |
| Jobs | 🟢 **Demo Complete + remote assignments** — gigs catalog seed; accept/advance/history via `/commerce/job-assignments` when remote |
| Insurance | 🟢 **Demo Complete + remote policies** — plan catalog seed; buy/history via `/commerce/insurance-policies` when remote |
| Family Wallet | 🟢 **Demo Complete + remote transfers** — members seed; send/history via `/commerce/family-transfers` when remote |
| Huduma | 🟢 **Demo Complete + remote bookings** — services seed; book/history via `/commerce/huduma-bookings` when remote |
| Ops | 🟢 **Demo Complete (Foundation Sprint)** — live rides/food/pay stats + incident ack → resolve |
| **WINGA** | 🟢 **Ops handbook v1.0** — RACI, playbooks, SOPs, settlement, incidents, KPI dictionary (`docs/winga_ops/`). Hotels field Week 0 · Blueprint **NOT CERTIFIED** |
| **COMMERCE MOS** | 🟢 **Ops handbook v1.0** — RACI, onboarding, store/warehouse/procurement/finance SOPs, certification & pilot governance (`docs/commerce_ops/`). Experience `/commerce` · API `/api/v1/mos/` |
| **MAP (Acceptance)** | 🟢 **Foundation** — QR · links · invoices · checkout · terminals · receipts; money via `capture_merchant_payment` only (`docs/map/`). API `/api/v1/map/` · Flutter `/map` · tests 7/7 |
| **TAP & PAY** | 🟢 **Foundation** — NFC/SoftPOS sessions · funding priority · biometric gate · confirm via MAP (`docs/tap_pay/`). API `/api/v1/map/tap/*` · Flutter `/tap` |
| **TAIFA EXPRESS** | 🟢 **Fulfillment engine** — Smart Shopping List · packages/QR · READY→dispatch · settlement plan · live map track (`docs/express/`). API `/api/v1/express/` · `/express/list` · tests 10/10 |
| **SUPER APP** | 🟢 **Consumer orchestration** — universal search · QR · pay hub · home journey rail · AI payment guard (`docs/super_app/`). Routes `/search` `/scan` `/pay` — no new backend |
| **PLATFORM GOVERNANCE** | 🟢 **Lifecycle Constitution v1.0** — Stages 0–9 · Gates G0–G8 · certification library · scorecard (`docs/platform_governance/`). Unifies all platforms; no gate skips |
| **PROGRAM CLOSURE** | ✅ **Design program COMPLETE** (2026-07-19) — baseline `TAIFA-BASELINE-2026-07-19` · 15 closure deliverables (`docs/program_closure/`). Execution open; national rollout **NO-GO** until pilots validate |


| Mobility | 🟢 **Demo Complete + Hybrid Dispatch foundation** — full passenger ride loop on mock location/route/ETA/matching gateways + **`MapsProvider`/`MapScene`**; **`RestTripRepository`** persists lifecycle to Trip API when remote; **`mobility_channels`** multi-channel orchestration (push/SMS/USSD/IVR/stage) with boarding PIN, telco webhooks, passenger status polling — see `docs/mobility_channels/` |
| AI Assistant | 🟢 **Demo Complete (Foundation Sprint)** — Swahili-first chat UI on `MockAiGateway` (swap-ready for OpenAI/Anthropic/Gemini); suggestions for Ride/Food/Flights/Wallet |
| NFC | 🟢 **Demo Complete (Foundation Sprint)** — Tap-to-Translate phrase packs (market/travel/clinic) with simulated scan → unlock (no hardware NFC) |
| Profile | 🟢 **Demo Complete (Foundation Sprint)** — display name/phone/language persisted via SharedPreferences; avatar entry from Home |
| Settings | 🟢 **Demo Complete (Foundation Sprint)** — dark/light persisted; links to Profile, Notifications, NFC |
| Notifications | 🟢 **Demo Complete (Foundation Sprint)** — inbox with mark-read / mark-all; ride/food/payment/promo seeds |
| Menu (directory) | 🟢 **Demo Complete (Foundation Sprint)** — live directory to all Demo Complete modules |
| All others | ✅ Foundation Demo Complete across consumer + operator portals; next is Production Complete rails |

## Suggested next slices (priority order)

1. ✅ **Connect mobile → backend** — `data/` layer (DTOs + versioned REST client),
   `RestWalletRepository` behind the `WalletRepository` interface, device-bound
   auth tokens. Send Money calls `POST /transfers` for real; `load()` reads
   `GET /wallet`. Toggle with `--dart-define=TAIFA_USE_REMOTE=true`.
2. ✅ **M-Pesa Daraja sandbox** — live adapter activates when
   `MPESA_CONSUMER_KEY`/`SECRET` are set (sandbox Lipa Na M-Pesa passkey
   defaults). `python manage.py check_daraja` verifies OAuth.
   Local STK can settle via `POST /topups/{id}/poll-status` or demo-complete;
   **public callback** via ngrok → `MPESA_CALLBACK_BASE_URL` so Daraja can
   POST `/webhooks/mpesa/stk` directly. Production still needs prod credentials.
3. ✅ **OpenAPI + contract tests** — commerce/trips views annotated for
   spectacular; `openapi.yaml` regenerated; CI diffs committed schema;
   payment path contract tests (backend + mobile `PaymentApiPaths`).
4. ✅ **Top-up flow in the UI** — `/wallet/topup` surfaces `POST /topups` (STK)
   via `WalletRepository.topUp`; seed auto-settles; remote stays `processing`
   until webhook / demo-complete. Home “Top Up” + Wallet action wired.
5. ✅ **Mobility maps + live tracking** — `MapsProvider` / `MapScene`
   abstraction with `MockMapsProvider` (CustomPaint, no API keys); camera
   follows driver on approach; in-trip driver advances along route polyline.
   Google/Mapbox adapters can swap via Riverpod without UI changes.
6. ✅ **Mobility ↔ Trip API** — `RestTripRepository` behind the same
   `TripRepository` interface when `TAIFA_USE_REMOTE=true` (create / patch /
   history / pay); matching & maps stay client-side.
7. ✅ **Food ↔ commerce API** — `RestFoodOrderRepository` behind
   `FoodOrderRepository` when remote (place / track / pay / history on
   `/commerce/food-orders`); restaurant catalog stays seed/local.
8. ✅ **Hotels ↔ stay-bookings API** — `RestStayBookingRepository` behind
   `StayBookingRepository` when remote (book / pay / history on
   `/commerce/stay-bookings`); hotel catalog stays seed/local.
9. ✅ **Flights ↔ flight-bookings API** — `RestFlightBookingRepository` behind
   `FlightBookingRepository` when remote (book / pay / history on
   `/commerce/flight-bookings`); search catalog stays seed/local.
10. ✅ **Tourism ↔ tour-bookings API** — `RestTourBookingRepository` behind
    `TourBookingRepository` when remote (book / pay / history on
    `/commerce/tour-bookings`); experience catalog stays seed/local.
11. ✅ **Daraja STK public callback (ngrok)** — local tunnel exposes
    `/api/v1/payments/webhooks/mpesa/stk`; `MPESA_CALLBACK_BASE_URL` set in
    gitignored `.env` so live STK can settle without poll-status.
12. ✅ **WINGA ↔ commerce APIs** — `RestWingaRepository` when remote: orders,
    service bookings, Open Shop on `/commerce/winga-*`; catalog/AI/NEGOTIA
    stay client mocks.
13. ✅ **Commerce/trips OpenAPI contract gate** — committed schema must list
    payment + trips + food/stay/flight/tour + winga paths; mobile path
    constants locked in `test/contract/api_paths_contract_test.dart`.
14. ✅ **Gov ↔ commerce API** — `RestGovRequestRepository` when remote
    (submit / pay / history on `/commerce/gov-requests`); Huduma catalog
    stays seed/local.
15. ✅ **Health ↔ commerce API** — `RestAppointmentRepository` when remote
    (book / pay / history on `/commerce/health-appointments`); facility
    catalog stays seed/local.
16. ✅ **Education ↔ commerce API** — `RestEduPaymentRepository` when remote
    (invoice / pay / history on `/commerce/edu-payments`); school catalog
    stays seed/local.
17. ✅ **Housing ↔ commerce API** — `RestHousingRepository` when remote
    (inquire / deposit / history on `/commerce/housing-inquiries`); listings
    stay seed/local.
18. ✅ **Wealth ↔ commerce API** — `RestWealthRepository` when remote
    (contribute / history on `/commerce/wealth-contributions`); Harambee
    circles stay seed/local.
19. ✅ **Jobs ↔ commerce API** — `RestJobsRepository` when remote
    (accept / advance / history on `/commerce/job-assignments`); gig catalog
    stays seed/local.
20. ✅ **Insurance ↔ commerce API** — `RestInsuranceRepository` when remote
    (buy / history on `/commerce/insurance-policies`); plan catalog stays
    seed/local.
21. ✅ **Family Wallet ↔ commerce API** — `RestFamilyRepository` when remote
    (send / history on `/commerce/family-transfers`); members stay seed/local.
22. ✅ **Huduma ↔ commerce API** — `RestHudumaRepository` when remote
    (book / history on `/commerce/huduma-bookings`); service catalog stays
    seed/local.
23. ✅ **Merchant ↔ commerce API** — `RestMerchantRepository` when remote
    (list / advance on `/commerce/merchant-orders`); empty queues hydrate
    from demo seed once.
24. ✅ **Driver ↔ commerce API** — `RestDriverRepository` when remote
    (offers / update / earnings on `/commerce/driver-jobs`); empty queues
    hydrate from demo seed once.
25. ✅ **Chat ↔ commerce API** — `RestChatRepository` when remote
    (threads / messages / send on `/commerce/chat-threads`); empty inbox
    hydrates from demo seed once.
26. ✅ **Admin ↔ commerce API** — `RestAdminRepository` when remote
    (list / advance on `/commerce/admin-cases`); empty queue hydrates from
    demo seed once.
27. ✅ **M-Pesa webhook trust rails** — optional IP/CIDR allow-list
    (`MPESA_WEBHOOK_ALLOWED_IPS`), shared-secret header
    (`MPESA_WEBHOOK_SHARED_SECRET`), and STK payload shape checks on
    `POST /payments/webhooks/mpesa/stk`.
28. ✅ **Prometheus `/metrics`** — scrape-time gauges for txn status, webhook
    results, pending backlog (>5m), devices, and app info
    (`payments/metrics.py`); optional `METRICS_ALLOWED_IPS`.
29. ✅ **Daily ledger reconciliation** — `reconcile_ledger` management command +
    Celery task `payments.reconcile_ledger` (beat every 24h); checks balanced
    entries, global conservation, currency consistency, succeeded↔ledger links;
    exposes `taifa_ledger_reconciliation_*` gauges after each run.
30. ✅ **Journal + withdrawals / refunds / reversals** — single `journal.py`
    posting recipes; withdrawal hold→settle/release lifecycle; partial/full
    refunds with cap; compensating reversals; Alertmanager rules + Grafana
    dashboard JSON under `deploy/observability/`; architecture in
    `PAYMENT_ENGINE.md`.
31. ✅ **Core banking control plane** — `CORE_BANKING_ARCHITECTURE.md`; Payment
    Orchestrator (risk→engine→events→audit); formal state machine; append-only
    domain events + audit log; Risk Engine (sanctions / limits / velocity);
    expanded CoA + posting FX metadata (`base_currency`, `fx_rate_e8`).

## Post-launch backlog (Phase 19)

Driven by real usage once live; seeded here so the direction is explicit:

- Short-lived access tokens + refresh; device attestation (Play Integrity / App Attest).
- Wire Alertmanager receivers (Slack/PagerDuty/email secrets) in the live cluster.
- Provider settlement-file reconciliation (missing/duplicate/amount/currency/late).
- Chargebacks + merchant settlement batches + treasury adjustments + reporting projections.
- Load tests (k6/Locust) with p95 assertions gating CI nightly.
- Materialised balance snapshots + monthly ledger partitioning as volume grows.
- Full localisation (Swahili) pass + accessibility audit.
- Generated Dart API client from OpenAPI, locking client/server alignment in CI.
