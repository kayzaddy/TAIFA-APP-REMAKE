# Taifa Commerce Experience Layer

**Scope:** Flutter Merchant Operating System journeys  
**Backend:** Existing `/api/v1/mos/*` — no redesign  
**Money:** Taifa Payments / ledger only · AI never authorizes payment  

---

## Routes

| Route | Experience |
| --- | --- |
| `/commerce` | Role hub |
| `/commerce/onboarding` | Role → first success |
| `/commerce/desk` | Merchant owner/manager desk |
| `/commerce/pos` | Cashier POS |
| `/commerce/warehouse` | Warehouse receive / fulfill |
| `/commerce/procurement` | Suppliers & POs |
| `/commerce/shop` | Customer browse / cart / track |
| `/commerce/management` | Executive analytics |

---

## Design kit

`presentation/widgets/commerce_kit.dart` — money, status chips, next-action, order timeline, product tiles, payment transparency, stats, empty states.

---

## Data

- Offline: `SeedMosRepository`  
- Remote: `RestMosRepository` → `/api/v1/mos/*` with seed soft-fallback  
- Controller: `mosControllerProvider`  

---

## Journeys

**POS:** Open shift → search/favorites → cart → Charge (create+pay) → receipt ref  
**Warehouse:** Low-stock next-action → receive → fulfill paid queue  
**Desk:** Health scorecards → unpaid/low-stock next-action → Winga publish  
**Customer:** Browse → wishlist → cart → pay → timeline track  
**Management:** GMV · Winga · Mobility link · AI tips  

---

## Tests

```bash
cd apps/mobile
flutter test test/commerce_mos/
```

**Operations:** [`commerce_ops/00_INDEX.md`](commerce_ops/00_INDEX.md)
