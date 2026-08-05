# Taifa Commerce Architecture Guide

**Product:** Taifa Commerce — Merchant Operating System (MOS)  
**Code:** `apps/backend/mos` · **API:** `/api/v1/mos/`  
**Status:** Foundation v1 (catalog, inventory, orders, POS sessions, Winga publish, analytics)

---

## Philosophy

Taifa Commerce is **not** another shopping website.  
It is the **commercial engine** of the Taifa ecosystem: product, inventory, procurement, orders, POS, CRM, suppliers, promotions, documents, multi-branch — while **reusing** shared platform services.

---

## Non-negotiable reuse map

| Capability | Source of truth | MOS role |
| --- | --- | --- |
| Merchant legal / settlement identity | `enterprise.Merchant` | `CommerceMerchant` OneToOne profile only |
| Money / wallet / fees | `payments` ledger + `enterprise.capture_merchant_payment` | Orders call capture; never store balances |
| Brokerage / commissions | `winga` | Optional `publish-winga` → `Offering` |
| Delivery | Taifa Mobility (`trips`) | `SalesOrder.mobility_job_ref` hook |
| Identity / device auth | Payments device tokens | All MOS APIs `IsDevice` |
| AI | Assist endpoints | **Never** authorize payment |
| Governance / RBAC / workflows | `enterprise` + `governance` | Approvals for large POs (extend) |
| Super-App demo bookings | existing `commerce` app | Unchanged — consumer vertical demos |

---

## Bounded context

```
enterprise.Merchant ──1:1── CommerceMerchant (MOS)
        │                      ├── Branch / Staff
        │                      ├── Product / Variant / Category / Brand
        │                      ├── Warehouse / StockItem / StockMovement
        │                      ├── Supplier / PurchaseOrder
        │                      ├── CustomerProfile
        │                      ├── SalesOrder / Lines
        │                      ├── PosSession
        │                      ├── Promotion
        │                      └── CommerceDocument
        │
        └── capture_merchant_payment → payments.journal
```

---

## Module coverage (v1 vs roadmap)

| Module | v1 foundation | Later |
| --- | --- | --- |
| Merchant platform | Bootstrap, profile, branches, staff | Full KYB UX |
| Catalog | Products, kinds, SKU, Winga publish | Variants UI, media CDN |
| Inventory | Warehouses, on_hand/reserved, movements | Serial/batch/expiry flows, valuation reports |
| Procurement | Supplier + PO create | Approval workflow, GRN automation |
| Orders | Create, pay, fulfill, timeline | Returns/exchanges, backorders |
| CRM | Customer profiles | Segments, credit ledger |
| POS | Open/close session | Offline sync, barcode, cash drawer hardware |
| Payments | Enterprise capture + Idempotency-Key | Split tender UX |
| Delivery | mobility_job_ref field | Full Mobility dispatch API |
| Winga | Publish product → Offering | Campaign analytics join |
| Promotions | Promotion model | Engine evaluation at checkout |
| AI copilot | Assist tips + payment block | Forecasting models |
| Analytics | Summary endpoint | Branch/employee/Winga dashboards |
| Documents | Document metadata model | PDF generators |
| Multi-branch | Branch + warehouse FK | Inter-branch transfer SOP |
| Ecommerce storefront | API-ready catalog | Customer storefront app |
| Mobile apps | MOS hub entry | Staff / warehouse apps |
| Security / observability | Device auth + Prometheus counters | Full dashboards |
| Testing | Unit + API tests | Load / offline / POS sims |

---

## Critical flows

### Pay order (ledger-backed)

1. Create order → reserve stock  
2. `POST …/orders/{id}/pay` + `Idempotency-Key`  
3. `PlatformOrchestrator.capture_merchant_payment`  
4. Store `payment_ref` only (server-authored)  
5. Fulfill → release reserve + issue stock  

### Publish to Winga

`POST …/products/{id}/publish-winga` creates/updates `winga.Offering` linked to provider bound to the same `enterprise.Merchant`.

---

## Commands

```bash
cd apps/backend
python manage.py migrate mos
python manage.py seed_mos
python manage.py test mos
```

---

## Experience layer

Flutter journeys: [`COMMERCE_EXPERIENCE.md`](COMMERCE_EXPERIENCE.md) · Hub `/commerce`.

**Operations handbook:** [`commerce_ops/00_INDEX.md`](commerce_ops/00_INDEX.md) — official SOPs for merchant onboarding through certification.

---

## Design rule for future modules

Independently deployable **within** `mos` (or sibling apps that FK `enterprise.Merchant`).  
Never create a second ledger. Never create a second Merchant money identity. Never let AI move money.
