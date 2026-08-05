# Winga Property — Phase 5: Digital Transactions

**Status:** COMPLETE  
**Depends on:** Phases 1–4, Taifa Identity, Taifa Payments / Wallet

## Scope delivered

| Capability | Implementation |
| --- | --- |
| Rental applications | `PropertyApplication` + document upload |
| Identity verification | `continental.adapters` (NIDA federation) |
| Income verification | Rent-to-income ratio check (≥3×) |
| Digital lease | `PropertyLease` with AI-assisted contract text |
| E-signatures | Tenant + owner signature timestamps |
| Deposit & rent payments | Wallet via `capture_merchant_payment` |
| Lease renewal | Extend term + renewal payment |
| Move-in / move-out | `PropertyMoveWorkflow` checklists |

## Reuse (no duplication)

- **Identity:** `continental.adapters.resolve_identity_adapter` (TZ/NIDA)
- **Payments:** `enterprise.orchestrator.capture_merchant_payment`
- **Commerce merchant:** `ensure_platform_commerce_merchant(sector="winga_property")`
- **CRM timeline:** `PropertyTimelineEvent` via Winga assignment
- **Notifications:** `integrations.notifications`

## API highlights

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/listings/{id}/applications` | Start application |
| POST | `/applications/{id}/submit` | Submit for review |
| POST | `/applications/{id}/documents` | Upload document URL |
| POST | `/applications/{id}/verify-identity` | NIDA check |
| POST | `/applications/{id}/verify-income` | Income ratio check |
| POST | `/applications/{id}/approve` | Approve after checks |
| POST | `/applications/{id}/generate-lease` | Generate contract |
| POST | `/leases/{id}/sign` | E-sign lease |
| POST | `/lease-payments/{id}/pay` | Wallet payment |
| POST | `/leases/{id}/renew` | Renew lease |
| POST | `/move-workflows/{id}/complete` | Complete move checklist |

## Flutter UX

- **Apply & lease** action on rent listings
- Step-through sheet: apply → verify → approve → sign → pay deposit → move-in

## Tests

`winga_property.tests` — 17 tests (includes full application → lease → payment flow)

## Program complete

Winga Property Phases 1–6 are delivered. See Phase 6 doc for enterprise ops.
