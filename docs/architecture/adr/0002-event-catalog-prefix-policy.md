# ADR 0002 — Domain event catalog prefix policy

**Status:** Accepted  
**Date:** 2026-08-05  
**Deciders:** Enterprise Architecture Review Board (EARB)  
**Domains affected:** Platform (event bus), Commerce/Booking, Finance, Tourism, Mobility, all future publishers

## Context

The platform [02_EVENT_CATALOG.md](../02_EVENT_CATALOG.md) and Tourism canonical registry use mixed prefixes:

- `tourism.*`, `finance.*`, `protection.*`, `connectivity.*`, `mobility.*`, `government.*`, `ai.*`
- `booking.reservation.*` (no `commerce.` prefix) for reservation lifecycle events

New engineers and integrators may emit duplicate events (`booking.confirmed` vs `booking.reservation.confirmed`, or `commerce.booking.created` vs `booking.reservation.confirmed`). EventBridge rules and analytics depend on a **single** naming law.

## Decision

1. **Canonical format (mandatory for all new events):**

   ```
   {context_prefix}.{entity}.{action_past_tense}
   ```

   - `context_prefix` = bounded context or platform module (lowercase): `tourism`, `finance`, `commerce`, `booking`, `mobility`, `protection`, `connectivity`, `government`, `ai`, `identity`, `notification`, `discovery`
   - Use **snake_case** segments; no camelCase.

2. **Reservation lifecycle (Commerce / Booking):**  
   Publish as **`booking.reservation.{action}`** — not `commerce.booking.*`, not bare `booking.confirmed`.

   | Action | Event name |
   | --- | --- |
   | Hold created | `booking.hold.created` |
   | Confirmed | `booking.reservation.confirmed` |
   | Paid | `booking.reservation.paid` |
   | Cancelled | `booking.reservation.cancelled` |
   | Stay checked in | `booking.stay.checked_in` |
   | Stay checked out | `booking.stay.checked_out` |

   **Rationale:** `booking` is the ubiquitous context name in Tourism orchestration and OpenAPI facades (`/tourism/booking/` target). Physical publisher remains the **Commerce** Django app until a `booking` service is extracted; `producer` envelope field = `commerce` or `booking-service`.

3. **Commerce order events (retail, food, non-reservation):** use prefix **`commerce.`**:

   - Examples: `commerce.order.created`, `commerce.order.paid`, `commerce.merchant_order.updated`

4. **Finance:** prefix **`finance.`** only (e.g. `finance.payment.captured`, `finance.refund.completed`).

5. **Deprecated aliases** — must not appear in new code or EventBridge rules:

   | Deprecated | Use instead |
   | --- | --- |
   | `booking.confirmed` | `booking.reservation.confirmed` |
   | `booking.paid` | `booking.reservation.paid` |
   | `assistance.sos.opened` | `protection.sos.opened` |
   | `payment.captured` (unqualified) | `finance.payment.captured` |

6. **Documentation shorthand** (product docs only): `trip.created` means `tourism.trip.created`; code and bus use full name.

7. **Registry updates:** Any new event requires a row in [02_EVENT_CATALOG.md](../02_EVENT_CATALOG.md) and Tourism §5 if tourism-related, before merge.

## Consequences

**Positive**

- Single rule for CI linting and partner subscriptions.
- Tourism orchestration subscriptions stay stable.

**Negative**

- Legacy code or docs mentioning `commerce.booking.*` need migration notes.

**Mitigations**

- Dual-publish **not** required for deprecated aliases (none in production bus yet).
- OpenAPI/webhook docs reference full event names only.

## Compliance

- [00_ARCHITECTURE_CONSTITUTION.md](../00_ARCHITECTURE_CONSTITUTION.md) — event-driven architecture  
- [01_DOMAIN_GOVERNANCE.md](../01_DOMAIN_GOVERNANCE.md) — Booking owns reservation SoR  
- Tourism [CANONICAL_ENTERPRISE_ARCHITECTURE.md](../../tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md) §5 — aligned  

## Alternatives considered

| Option | Rejected because |
| --- | --- |
| All events under `commerce.*` | Hides domain boundaries; Tourism subscribes to wrong mental model |
| `taifa.{domain}.*` four segments | Verbose; context prefix sufficient |

## References

- Sprint S1 (M0) — [14_PLATFORM_IMPLEMENTATION_GUIDE.md](../../platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md)
