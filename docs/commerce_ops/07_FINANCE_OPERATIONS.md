# 7. Finance Operations Handbook

**Owner:** Principal Finance Operations Architect  
**Partners:** Settlement · Risk · Merchant Success  

---

## Daily procedures

1. **Settlement verification** — pending / completed payouts  
2. **Ledger reconciliation** — captures vs MOS paid orders (`payment_ref`)  
3. **Refund approval queue** — dual control above threshold  
4. **Chargeback handling** — per [`CHARGEBACK_GUIDE.md`](../CHARGEBACK_GUIDE.md)  
5. **Cash reconciliation** — store float variances  
6. **Revenue snapshot** — GMV / fees / tax components  
7. **Tax reporting feed** — period extract  
8. **Exception management** — age Critical ≤ same day  
9. **Audit pack** — retain recon sign-offs  

**Rule:** No financial discrepancies remain unresolved at day close without an open incident.

## Forbidden

- Manual balance edits outside journal SOPs  
- Marking orders paid without `payment_ref`  
- AI-initiated captures  
