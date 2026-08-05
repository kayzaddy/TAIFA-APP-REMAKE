# Winga Experience Layer

**Scope:** Flutter UX journeys on top of the completed Winga backend  
**Constraint:** No backend, API, or workflow redesign — experience only  

---

## Principles

Design for human goals: speed, trust, simplicity, transparency, guidance.  
Every screen answers: *what am I trying to do?* · *what do I need?* · *what’s next?*

---

## Routes

| Route | Journey |
| --- | --- |
| `/winga` | Role hub + onboarding CTA |
| `/winga/onboarding` | Welcome → Role → Trust → First success |
| `/winga/opportunities` | Opportunity marketplace feed |
| `/winga/customer` | Discover → Compare → Pay → Assist |
| `/winga/broker` | Desk · CRM · Earn · Providers · Coach |
| `/winga/provider` | Growth home · Catalog · Leads · Campaigns |

---

## Experience kit

Reusable chrome in `apps/mobile/lib/features/winga/presentation/widgets/experience_kit.dart`:

| Widget | Purpose |
| --- | --- |
| `WingaJourneyStepper` | Journey progress |
| `WingaNextActionBar` | Primary + optional secondary CTA |
| `WingaGoalHeader` | Goal + hint |
| `WingaTrustBadge` | Verification / trust signals |
| `WingaCommissionBreakdown` | Deal · rate · share · status |
| `WingaPaymentSummary` | Amount · payee · status |
| `WingaOpportunityCard` | Campaign opportunity tile |
| `WingaLoadingBlock` / `WingaOfflineBanner` | Performance & resilience states |

Base UI tokens remain in `winga_ui.dart` (money, stats, empty, pipeline).

---

## Persona outcomes

### Customer
Discover offerings → compare providers/Wingas → request/accept path via deals → **pay securely** (server ledger) → track → AI tips (never money).

### Winga
Dashboard next-action (opportunities / CRM / settle) → opportunity feed → lead capture → commission transparency → settle to wallet → sales coach.

### Provider
Growth next-action (leads / catalog / campaigns) → inbound deals → partner Wingas → campaign AI suggestions only.

---

## Opportunity marketplace

Client-side catalog (`WingaOpportunityCatalog`) — filters by industry, query, trending.  
Save / apply prefs via `experiencePrefsProvider` (local, no new APIs).

---

## Money & AI guardrails

- Payments: server `POST …/deals/{id}/pay` + Idempotency-Key  
- Commission settle: server `POST …/deals/{id}/settle-commission`  
- UI never forges balances; breakdowns mirror server events  
- AI assist never authorizes payments  

---

## Success metrics (product)

Onboarding completion · time to first transaction · quote/deal completion · commission settlement clarity · DAU/MAU · CSAT · Winga & provider retention.

---

## Tests

```bash
cd apps/mobile
flutter test test/winga/
```
