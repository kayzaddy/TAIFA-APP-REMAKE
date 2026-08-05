# Winga Property — Phase 4: AI + Human Winga

**Status:** COMPLETE  
**Depends on:** Phases 1–3, `winga` brokerage platform, `commerce` chat

## Scope delivered

| Capability | Implementation |
| --- | --- |
| AI Property Copilot | `copilot.py` → `winga.ai.assist` (no payment auth) |
| Property ranking | `/copilot/rankings` with visit-score weights |
| Negotiation assistance | `/listings/{id}/negotiation-assist` |
| Relocation advice | `/listings/{id}/relocation-assist` |
| Human Winga assignment | Auto-assign best verified property Winga |
| Winga CRM timeline | `PropertyTimelineEvent` per assignment |
| Secure chat | Reuses `commerce.ChatThread` / `ChatMessage` |
| Document sharing | `PropertySharedDocument` |
| Viewing appointments | `PropertyViewingAppointment` |
| Commission preview | Property domain `default_commission_bps` |
| Leaderboard & trust | `WingaProfile.reputation_score_e4` → trust stars |
| Winga Lead | Auto-creates `winga.Lead` on assignment |

## Reuse (no duplication)

- **AI:** `winga.ai.assist` / `ecosystem.ai`
- **Human Wingas:** `winga.WingaProfile` + property domain
- **Chat:** `commerce` chat models
- **CRM leads:** `winga.Lead`
- **Commission:** `winga.BrokerageDomain` rules (preview only)

## Flutter UX

- **Ask AI** — Property Copilot chat sheet
- **Human Winga** — assigned advisor profile, trust stars, secure chat

## Seed

`seed_winga_property` creates 3 verified property Wingas (Asha, Juma, Neema).

## Tests

`winga_property.tests` — 16 tests

## Phase 6 (not implemented)

Enterprise operations — analytics, fraud, moderation, ops portal, disputes.
