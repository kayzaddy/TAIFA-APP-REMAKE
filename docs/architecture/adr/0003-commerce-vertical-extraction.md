# ADR 0003 — Commerce vertical extraction and booking facade

**Status:** Accepted  
**Date:** 2026-08-05  
**Deciders:** Enterprise Architecture Review Board (EARB)  
**Domains affected:** Commerce, Booking (logical), Tourism, Health, Education, Government, Finance

## Context

The Django `commerce` app hosts **multiple logical bounded contexts** today:

- Retail / food / merchant orders  
- **Booking** (tour, stay, flight reservations)  
- Vertical facades: health appointments, education payments, government requests, insurance policies, housing, etc.

[`DIGITAL_ECOSYSTEM.md`](../../DIGITAL_ECOSYSTEM.md) maps these as first-class domains, but **physical schema** lives under `commerce_*` tables. Tourism orchestration must delegate booking without becoming a second booking engine. EARB rated this **Amber** ([06_ARCHITECTURE_REVIEW_REPORT.md](../../platform/earb/06_ARCHITECTURE_REVIEW_REPORT.md)).

## Decision

### 1. Logical ownership (immediate — documentation and API design)

| Capability | Logical owner | Phase-1 physical SoR |
| --- | --- | --- |
| Tour / stay / flight reservations | **03 Booking** | `commerce` tour/stay/flight booking models |
| Retail / food / merchant kitchen | **Commerce** | `commerce` order models |
| Health appointments | **Health** | `commerce/health-appointments` API |
| Education fees | **Education** | `commerce/edu-payments` API |
| Government requests | **Government** | `commerce/gov-requests` API |
| Travel insurance policies (generic) | **06 Protection** | `commerce` `InsurancePolicy` (legacy table) |

No change to table names in this ADR—**ownership** and **integration rules** only.

### 2. Strangler sequence (implementation phases — after platform foundation M4+)

| Phase | Deliverable | Domain impact |
| --- | --- | --- |
| **E0** | OpenAPI tags: `Booking`, `Commerce`, `Health`, etc. | Docs/CI only |
| **E1** | HTTP facade `/api/v1/tourism/booking/*` delegating to existing commerce booking endpoints | Tourism clients |
| **E2** | Internal `BookingPort` in tourism (and other orchestrators) — **no direct `commerce.models` import** in orchestration domain layer | Tourism code |
| **E3** | Emit `booking.reservation.*` events from commerce on state change (outbox) | Platform events |
| **E4** | Extract `booking` Django app or service package; commerce imports booking as dependency | Repo structure |
| **E5** | Health/Edu/Gov: optional separate apps with ACL from commerce tables | Vertical domains |

**Freeze:** No E1–E5 until platform foundation **M4** (event outbox) is complete, except **E0** and audit-driven **E2** refactors tied to remediation backlog.

### 3. Tourism integration rule

- Orchestration **stores** `tour_booking_ids`, `stay_booking_ids`, `payment_ref`, `insurance_policy_id`, `esim_order_id` on Trip/Checkout only.  
- **Mark paid / create policy** must migrate to **BookingPort** and **ProtectionPort** (see boundary audit R-001–R-003).  
- Unified checkout **continues** to call **Finance** via `PlatformContext.capture_merchant_payment` until Pay port is formalized.

### 4. Trade domain

**Taifa Trade** (B2B, customs, export) is **out of scope** for `commerce` extraction. Future **Trade** pack must not duplicate Commerce order engine; Trade consumes Booking + Finance + Government.

## Consequences

**Positive**

- Clear path for Tourism and EARB without big-bang rewrite.  
- Vertical domains can graduate from commerce APIs with ADR per vertical.

**Negative**

- Phase-1 remains coupled in one Django app.  
- Engineering discipline required to avoid new vertical tables in `commerce` without logical owner row in this ADR.

**Mitigations**

- ARB review for new `commerce_*` models.  
- [M0 tourism boundary audit](../../platform/evidence/M0-tourism-boundary-audit-report.md) tracks violations.

## Compliance

- [01_DOMAIN_GOVERNANCE.md](../01_DOMAIN_GOVERNANCE.md)  
- [03_CANONICAL_DATA_MODEL.md](../../platform/earb/03_CANONICAL_DATA_MODEL.md) — Booking vs Order  
- Tourism [17_IMPLEMENTATION_GUIDE.md](../../tourism/17_IMPLEMENTATION_GUIDE.md) strangler table  

## Alternatives considered

| Option | Rejected because |
| --- | --- |
| Big-bang split commerce app now | Violates foundation-first plan; high regression risk |
| Tourism owns booking rows | Violates DTOS orchestration charter |

## References

- [14_PLATFORM_IMPLEMENTATION_GUIDE.md](../../platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md) Sprint S1  
- PR-01 in [08_PLATFORM_RISKS.md](../../platform/earb/08_PLATFORM_RISKS.md)
