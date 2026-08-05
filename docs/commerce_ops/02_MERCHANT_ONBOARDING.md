# 2. Merchant Onboarding Manual

**Owner:** Head of Merchant Success (A) · Risk (KYB) · Settlement (payout) · Store Ops (POS)  
**Rule:** Merchant **cannot begin live operations** until all **mandatory** steps are complete and signed.

---

## Workflow

```
Registration → KYB → Profile → Branch → Warehouse → Tax → Payment activation
→ Settlement → Staff → Roles → POS → Inventory init → Suppliers
→ Winga (optional) → Mobility (optional) → Go-live → Day-7 / Day-30 follow-up
```

---

## Mandatory checklist

### 1. Business registration
- [ ] Legal entity / trading name  
- [ ] Sector / business type  
- [ ] Decision-maker contact  

### 2. KYB verification
- [ ] Registration docs  
- [ ] Beneficial ownership (as required)  
- [ ] Tax ID  
- [ ] Risk clearance → `enterprise.Merchant` ACTIVE  

### 3. Merchant profile (MOS)
- [ ] `POST /api/v1/mos/bootstrap` (or ops equivalent)  
- [ ] Business type, hours, currency  

### 4. Branch creation
- [ ] HQ branch code/name/address  
- [ ] Additional branches if multi-site  

### 5. Warehouse setup
- [ ] Default warehouse linked to branch  
- [ ] Receiving contact named  

### 6. Tax configuration
- [ ] Tax-inclusive flag  
- [ ] Default tax_bps on products (as applicable)  

### 7. Payment activation
- [ ] Merchant ACTIVE for capture  
- [ ] Test capture in staging (Finance sign-off)  

### 8. Settlement configuration
- [ ] Bank / payout refs  
- [ ] Settlement mode (daily/manual/…)  
- [ ] Finance contact  

### 9. Staff onboarding
- [ ] Owner + ≥1 cashier + warehouse contact (as applicable)  
- [ ] Principals recorded in MOS staff  

### 10. Role assignment
- [ ] Owner / manager / cashier / warehouse / purchaser permissions  

### 11. POS activation
- [ ] Device ready  
- [ ] Opening float policy agreed  
- [ ] Mystery sale test passed (QA)  

### 12. Inventory initialization
- [ ] Opening stock received via movements (not silent edits)  
- [ ] Reorder points set on key SKUs  

### 13. Supplier creation
- [ ] ≥1 primary supplier (or documented “cash market” exception)  

### 14. Winga integration (optional for go-live)
- [ ] Campaign intent Y/N  
- [ ] If Y: sample product published  

### 15. Mobility integration (optional for go-live)
- [ ] Delivery zones / pickup policy documented  

### 16. Go-live checklist (final gate)
- [ ] All mandatory above complete  
- [ ] Merchant Success + Store Ops + Settlement approve  
- [ ] Go-live date published  
- [ ] Staff trained on SOPs  

### 17. Post-launch
- [ ] Day 7: sales + stock accuracy review  
- [ ] Day 30: first Merchant Business Review  

---

## Decision table

| Result | Action |
| --- | --- |
| All mandatory complete | **LIVE** |
| Any mandatory open | **NOT LIVE** |
| Risk reject | **Blocked** |
