# TAIFA Super App — Product Requirements (PRD)

## Vision

TAIFA is the digital operating system of Tanzania: one trusted, fast, beautiful
app through which citizens pay, move, eat, access government services, and build
wealth — with a companion set of portals for merchants, drivers, operators,
partners and government. The bar is the best super apps in the world (M-Pesa,
Grab, WeChat, Alipay) adapted to Tanzanian realities: mobile-money-first,
multilingual (Swahili/English), and resilient on low-end devices and networks.

## Who we serve (personas)

- **Amani (consumer)** — smartphone, M-Pesa/Airtel user; wants to send money,
  pay bills, ride, and shop without juggling apps.
- **Fatima (merchant)** — small business; wants instant, low-fee collections and
  a clear dashboard.
- **Juma (driver/rider)** — earns on mobility/logistics; wants jobs, navigation
  and daily payouts.
- **Neema (family organiser)** — manages a family wallet, remittances and
  allowances.
- **Operators / Government** — need oversight, compliance and service delivery
  at scale.

## Jobs to be done

1. Move money instantly and safely (P2P, bills, merchants) across rails.
2. Get around (rides, bajaji, logistics) with fair, transparent pricing.
3. Access daily services (food, groceries, stays, home services).
4. Reach government/Huduma services digitally.
5. Grow and protect money (savings/Harambee, vault, insurance).
6. Do all of the above in Swahili, offline-tolerant, on any device.

## Product scope (modules)

| Module | Priority | Status |
|--------|----------|--------|
| Digital Wallet (pay/send/topup) | P0 | ✅ shipped (live backend) |
| Home / super-app shell | P0 | ✅ shipped |
| Mobility (rides) | P1 | preview surface |
| Food & Grocery | P1 | preview surface |
| Government / Huduma | P1 | preview surface |
| AI Assistant | P2 | preview surface |
| Merchant / Driver portals | P1 | planned |
| Family Wallet, Wealth, Life (health/edu/insurance) | P2 | planned |
| Tourist Mode, NFC Tap-to-Translate, Chat/Social | P3 | planned |

Portals (web): Admin, Merchant, Driver, Operations, Government, Support,
Analytics, Developer, Partner APIs — planned, sharing the same backend contracts.

## Success metrics

- **Activation**: % of new devices that complete a first transaction.
- **Reliability**: transfer success rate ≥ 99%; API availability ≥ 99.9%.
- **Speed**: cold start < 2s on mid-range Android; p95 API < 300ms.
- **Engagement**: weekly active wallets; transactions per active user.
- **Trust**: chargeback/dispute rate; reconciliation break count = 0.

## Non-functional requirements

- **Correctness of money**: integer minor units, double-entry ledger, exactly-once.
- **Security & compliance**: device-bound auth, owner scoping, KYC tiers, auditability.
- **Performance**: 60fps UI, lazy module loading, offline-tolerant reads.
- **Localisation**: Swahili + English; TZS-first, multi-currency ready.
- **Accessibility**: large-type, high-contrast, voice-forward flows.
- **Observability**: health/readiness, request tracing, error tracking (see `OBSERVABILITY.md`).

## Guardrails

- No placeholder business logic in shipped modules — a module is "done" only as a
  real vertical slice (UI → domain → API → tests), as proven by Wallet.
- Provider-agnostic by design: rails, maps, messaging plug in behind interfaces.

## Release strategy

Phased vertical slices, highest value/risk first (Wallet → Mobility → …), each
wired end-to-end and gated by CI. Regional expansion (Kenya/Uganda) reuses the
multi-currency, multi-rail core — see `SCALING.md`.
