# 17 — Implementation Guide (for engineering)

**Gate:** No merge without [CANONICAL_ENTERPRISE_ARCHITECTURE.md](CANONICAL_ENTERPRISE_ARCHITECTURE.md) §12 **and** platform [09_DEFINITION_OF_DONE.md](../architecture/09_DEFINITION_OF_DONE.md).

**When coding resumes:** every change must cite **primary domain** + **port** used. No new top-level folders without architect review.

---

## Strangler fig (monorepo today)

| Domain | Current location | Target package |
| --- | --- | --- |
| Orchestration | `apps/backend/tourism/` | `tourism_orchestration/` |
| Booking | `apps/backend/commerce/` | `tourism_booking/` |
| Mobility | `apps/backend/trips/` | bridge module only in tourism |
| Protection | `tourism/assist`, `commerce/insurance` | consolidate under protection ports |
| Connectivity | `tourism` esim models | `tourism_connectivity/` |
| Finance | `enterprise`, `payments` | adapters only in tourism |
| Discovery | `apps/mobile/.../tourism_catalog.dart` | backend discovery service |
| AI | seed plan in `tourism.services` | invoke AI Experience port |
| Presentation | `apps/mobile/lib/features/tourism/` | BFF calls orchestration APIs |

---

## Clean architecture layers (per domain)

```
domain/          # entities, aggregates, domain services, events
application/     # use cases / command handlers
ports/           # interfaces (inbound/outbound)
adapters/
  in/http/       # DRF views
  in/events/     # EventBridge handlers
  out/booking/   # HTTP clients
  out/persistence/
```

**Rule:** `domain/` has zero Django imports.

---

## What NOT to do

- Add booking pricing logic to `tourism/views.py`.  
- Capture payments outside Taifa Pay.  
- Create `tourism_hotels` app duplicating `commerce`.  
- Cross-domain SQL joins in reports (use warehouse).  
- New microservice repo before Phase 4 triggers.

---

## Definition of Done (feature)

1. Domain doc section updated (API/event/table).  
2. OpenAPI tag matches domain namespace.  
3. Domain event published (if state change cross-cutting).  
4. Idempotency on money/reservation paths.  
5. Tests: unit on aggregate + contract on port.  
6. Security checklist [14_SECURITY_ARCHITECTURE.md](14_SECURITY_ARCHITECTURE.md).

---

## Migration path for APIs

1. Keep `/commerce/*` stable.  
2. Introduce `/tourism/booking/` facade delegating to commerce.  
3. Deprecate with sunset headers.  

---

## Flutter presentation

- `TourismController` = orchestration client only.  
- Catalog UI → Discovery port (future).  
- SOS → Protection port.  
- No wallet math in widgets—Finance/Pay SDK.

---

## ADRs

Create `docs/tourism/adr/NNN-title.md` for boundary changes. Index: [adr/README.md](adr/README.md). **Accepted:** [0001](adr/0001-phase1-protection-connectivity-in-tourism-app.md) (phase-1 Protection/Connectivity in `taifa_tourism`).

---

## Testing pyramid

| Level | Scope |
| --- | --- |
| Unit | Domain invariants |
| Integration | Adapters + DB |
| Contract | Pact between Orchestration ↔ Booking |
| E2E | Mobile + staging API |

---

## Current API surface (orchestration — reference)

Documented in [00_INDEX.md](00_INDEX.md) legacy bullets; canonical owner: **02 Travel Orchestration**.

---

## Contact / governance

Architecture changes require update to **[CANONICAL_ENTERPRISE_ARCHITECTURE.md](CANONICAL_ENTERPRISE_ARCHITECTURE.md)** (§2–§7 as applicable), [00_INDEX.md](00_INDEX.md) context map, and affected domain doc §8 (events) + §9 (APIs).
