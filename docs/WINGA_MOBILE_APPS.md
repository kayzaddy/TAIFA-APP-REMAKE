# Winga Mobile Applications Guide

**Scope:** Flutter Customer · Winga (broker) · Provider apps  
**Backend:** Existing `/api/v1/winga/*` — no redesigned money/identity logic  

---

## Entry

| Route | Screen |
| --- | --- |
| `/winga` | Role hub |
| `/winga/onboarding` | First-success onboarding |
| `/winga/opportunities` | Opportunity marketplace feed |
| `/winga/customer` | Customer app |
| `/winga/broker` | Winga desk (CRM) |
| `/winga/provider` | Provider hub |
| `/winga/marketplace` | Legacy demo shop (`WingaScreen`) |

---

## Architecture

```
Hub → Role app (NavigationBar)
        → BrokerageController (Riverpod)
        → BrokerageRepository
              ├─ SeedBrokerageRepository (offline-first)
              └─ RestBrokerageRepository (TAIFA_USE_REMOTE=true)
                    → TaifaApiClient → /api/v1/winga/*
```

Payments: `POST …/deals/{id}/pay` with Idempotency-Key (server ledger).  
AI: `POST …/assist` — payment capabilities rejected.

---

## Actor workflows

### Customer
Discover → filter domains → favorite → open deal → **Pay** → track in Deals → AI tips

### Winga
Dashboard (pending/settled commission) → CRM leads → Providers directory → Settle commission → Sales coach

### Provider
Snapshot → Catalog → Inbound deals → Campaign AI suggestions

---

## Design system

Reusable widgets in `features/winga/presentation/widgets/winga_ui.dart` using Taifa tokens (`TaifaColors`, `TaifaSpacing`, `TaifaRadii`). Dark mode follows app theme.

**Experience layer:** journey chrome, next-actions, trust, commission/payment transparency in `experience_kit.dart`. See [`WINGA_EXPERIENCE.md`](WINGA_EXPERIENCE.md).

**Hotels pilot (value validation):** [`winga_pilot/00_INDEX.md`](winga_pilot/00_INDEX.md) — Conditional GO for field; business-value Gate C pending real transactions.

---

## Offline

Seed repository ships demo domains/offerings/Wingas/providers. REST client soft-falls back to seed on network errors (except AI payment blocks).

---

## Tests

```bash
cd apps/mobile
flutter test test/winga/
```
