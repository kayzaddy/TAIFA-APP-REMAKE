# Winga Brokerage Platform — Architecture Guide

**Product:** Taifa Winga (Universal Brokerage Platform)  
**Not:** e-commerce, ride-hailing, classifieds, or single-vertical booking apps  
**Role:** Verified intermediaries (Wingas) connect customers with verified providers and earn configurable commissions.

---

## Actors

| Actor | Role |
| --- | --- |
| Customer | Buys, rents, books, hires via Winga-assisted deals |
| Winga | Verified intermediary — no inventory ownership required |
| Provider | Verified supplier (optional Taifa Merchant link) |
| Taifa Platform | Identity, Payments, Wallet, Ledger, AI, Notifications, Audit |

---

## Architecture

```
Customer / Winga / Provider Apps
        │
        ▼
   /api/v1/winga/*     ← brokerage layer (this app)
        │
        ├── enterprise.Merchant + capture_merchant_payment
        ├── payments.ledger (money truth)
        ├── enterprise.workflow (configurable stages)
        ├── ecosystem/ai_os (assist only — never pays)
        └── integrations (notify, docs, identity adapters)
```

New industries = new `BrokerageDomain` + commission rules + workflow code. **No redesign.**

---

## Modules (backend)

| Module | Location |
| --- | --- |
| Identity profiles | `WingaProfile`, `ProviderProfile` + verify endpoints |
| Catalog | `Offering`, `Category`, `BrokerageDomain` |
| Leads / quotes | `Lead`, `Quotation` |
| Deal workflow | `BrokerageDeal`, `DealEvent`, `services.advance_deal` |
| Commission engine | `commission.py` — % / flat / tiered / campaign / multi-level |
| Settlement | `settlement.py` — pay + commission credit to Winga wallet |
| Trust | verification statuses, `Review`, `Dispute`, risk scores |
| AI assist | `ai.py` — blocks payment authorization |
| Analytics | `GET /analytics/summary` + Prometheus counters |
| Seed | `manage.py seed_winga` |

---

## Deal lifecycle

`lead → inquiry → quotation → negotiation? → offer → accepted → payment → fulfillment → settlement → commission_payout → review → closed`

- **Payment** only via `POST /api/v1/winga/deals/{id}/pay` + `Idempotency-Key`
- **Commission** only via `POST /api/v1/winga/deals/{id}/settle-commission`
- AI cannot call either path

---

## Commission → ledger

1. Capture customer payment (platform fee + Winga commission reserved in `commission_income`)
2. `CommissionEvent` recorded (auditable)
3. Settle: debit `commission_income` → credit Winga `user_wallet` (`LedgerEntryKind.COMMISSION`)

---

## API surface

Base: `/api/v1/winga/`

Domains, categories, wingas, providers, offerings, leads, quotations, deals (+ advance/pay/settle-commission), commission-rules/events, reviews, favorites, assist, analytics/summary.

Auth: Taifa device identity (`IsDevice`).

---

## Mobile

Existing Flutter `features/winga` remains the customer surface. Brokerage APIs are under `/api/v1/winga/`. Commerce `winga-orders` remain demo checkout summaries — new brokerage deals use this platform.

---

## Ops

```bash
python manage.py migrate winga
python manage.py seed_winga
```

See also: [WINGA_COMMISSION_ENGINE.md](./WINGA_COMMISSION_ENGINE.md), [WINGA_GUIDE.md](./WINGA_GUIDE.md).
