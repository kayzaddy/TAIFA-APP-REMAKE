# ADR 0001 — Phase-1 Protection & Connectivity tables in `taifa_tourism`

**Status:** Accepted  
**Date:** 2026-08-05  
**Domains:** 02 Travel Orchestration (deploy unit), 05 Connectivity, 06 Protection (logical owners)

## Context

The modular monolith ships trip orchestration first in Django app `apps/backend/tourism/` (`taifa_tourism`). Protection (SOS, assistance, insurance attach) and Connectivity (eSIM at checkout) are separate bounded contexts in the canonical model but were implemented alongside unified checkout to reduce cross-app latency and migration churn.

Without a recorded decision, teams may:

- Treat `tourism` as a generic “tourism features” bucket and add Booking or Finance tables there.
- Confuse HTTP paths (`tourism/assist/*`) with domain ownership.
- Block extraction later because ownership was never explicit.

## Decision

1. **Physical deployment (phase-1):** `tourism_assistance_case` and `tourism_esim_order` remain in the `taifa_tourism` Django app and database schema prefix `tourism_*`.
2. **Logical ownership (authoritative):**
   - `tourism_assistance_case` → **06 Protection**
   - `tourism_esim_order` → **05 Connectivity**
   - `tourism_trip`, `tourism_itinerary_version`, `tourism_checkout` → **02 Orchestration** only
3. **Code organization:** New Protection/Connectivity behavior is implemented behind **ports** (`protection.*`, `connectivity.*`) in application layer; views may live in `tourism` URLs until namespaces migrate per canonical §6.
4. **SafetyIncident:** Created on SOS via Mobility (`trips`); Protection owns assistance workflow and `protection.sos.opened` — not duplicate incident SoR in `tourism` tables.
5. **Freeze:** No new tables in `taifa_tourism` whose **logical owner** is not 02, 05, or 06 without a new ADR. Booking, Finance, Discovery, Government, and AI persistence do not land in this app.

## Consequences

**Positive**

- Faster checkout saga (orchestration + optional lines in one transaction boundary today).
- Clear extraction target: `tourism_connectivity/`, `tourism_protection/` packages per [17_IMPLEMENTATION_GUIDE.md](../17_IMPLEMENTATION_GUIDE.md).

**Negative**

- Django app name implies single bounded context; requires discipline in imports and OpenAPI tags.
- Cross-domain tests may import from one app module.

**Mitigations**

- OpenAPI tags: `Tourism - Protection`, `Tourism - Connectivity` (not “Assist” for AI).
- Target URLs: `/api/v1/tourism/protection/`, `/api/v1/tourism/connectivity/`; keep `tourism/assist/*` as compatibility aliases until clients migrate.
- Event names per §5 only (`protection.sos.opened`, `connectivity.esim.provisioned`).

## Compliance

| Canonical section | Application |
| --- | --- |
| §2 | Protection owns assistance case + SOS workflow; Connectivity owns eSIM order; Mobility owns `SafetyIncident`. |
| §5 | Publish/subscribe using registry names above. |
| §6 | Migrate public paths to protection/connectivity namespaces; no `POST tourism/assist` for AI (09). |
| §7 | Table ownership row unchanged; this ADR documents the deployment concession. |
| §10 | Extraction when EventBridge outbox is live **or** independent team owns 05/06 release cadence ([16_ROADMAP.md](../16_ROADMAP.md)). |

## References

- [CANONICAL_ENTERPRISE_ARCHITECTURE.md](../CANONICAL_ENTERPRISE_ARCHITECTURE.md) §7, §11
- [06_PROTECTION_DOMAIN.md](../06_PROTECTION_DOMAIN.md) §2a (SafetyIncident RACI)
- [05_CONNECTIVITY_DOMAIN.md](../05_CONNECTIVITY_DOMAIN.md) (logical owner)
