# 3. Store Operations Manual

**Owner:** Head of Operations / Store Ops  
**Audience:** Store managers · cashiers  

---

## Morning opening checklist

- [ ] Premises secure / alarms clear  
- [ ] Staff attendance logged  
- [ ] Cash drawer / float verified vs policy  
- [ ] POS session opened (`/commerce/pos` or API)  
- [ ] Inventory spot check (3–5 SKUs)  
- [ ] Outstanding unpaid orders reviewed  
- [ ] Platform alerts / freeze status checked  

## During day

- [ ] Monitor sales vs plan  
- [ ] Shift changes: close prior POS session · open new  
- [ ] Discount / void approvals per role  
- [ ] Exception log (price overrides, no-sales, voids)  

## Daily closing

- [ ] Last sale completed or parked  
- [ ] POS session closed with closing cash  
- [ ] Cash reconciliation vs system tenders  
- [ ] Variance > threshold → Finance exception  
- [ ] Unfulfilled paid orders handed to warehouse  
- [ ] Store performance snapshot (GMV, orders, voids)  
- [ ] Exception report filed if any Sev-2+  

## Order lifecycle (store view)

| Stage | Owner | SLA | Escalate |
| --- | --- | --- | --- |
| Draft → Confirmed | Cashier / Staff | Immediate | Store manager |
| Reserved | System + cashier | On create | Inventory Control |
| Paid | Customer + Payments | ≤ 5 min at POS | Settlement / Support |
| Picking → Packing | Warehouse | ≤ 2h (same-day) | Warehouse manager |
| Dispatched → Delivered | Mobility / pickup | Per zone SLA | Mobility ops |
| Completed | Store / CS | After confirm | Merchant Success |
| Returned / Refunded | CS + Settlement | Per policy | Finance |
| Cancelled | Store manager | Before pay preferred | Risk if abuse |

Next action always visible on Merchant Desk / POS.
