# 8. Settlement Operations Guide

**Owner:** Settlement Ops Lead · **Accountable:** Finance  
**Aligns with:** [`SETTLEMENT_GUIDE.md`](../SETTLEMENT_GUIDE.md) · enterprise settlement APIs  

---

## Daily recon

1. List MOS orders with `paid=true` today  
2. Match each `payment_ref` to ledger transaction  
3. Merchant payable movements vs fee/tax/commission  
4. Settlements executed / scheduled  
5. Refunds / reversals linked to originals  
6. Exceptions aged and owned  

## Freeze

`PAY_FREEZE` / `SETTLE_FREEZE` declared by Store Ops / Marketplace Ops with Finance confirm.  
Lift only on written clearance.

## Winga commissions

If merchant publishes to Winga: commission settle follows Winga settlement SOPs — do not double-pay off-ledger.
