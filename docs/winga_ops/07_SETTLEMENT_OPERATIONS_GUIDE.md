# 7. Settlement Operations Guide

**Owner:** Settlement Ops Lead · **Accountable:** Finance Lead  
**Rule:** No settlement discrepancies remain unresolved at day close without an open incident.

---

## Daily reconciliation

**When:** End of each business day (and after any freeze lift)

### Verify

1. **Payments captured** — deals with `payment_ref` today  
2. **Payments settled** to ledger — txn ids present  
3. **Commission calculated** — events match rules (bps/flat)  
4. **Commission paid/settled** — `CommissionEvent` status settled + `ledger_txn_id`  
5. **Ledger consistency** — ops export vs payments journal  
6. **Refunds** — matched to original pay  
7. **Chargebacks** — Risk + Finance queue  
8. **Reversals** — dual control  
9. **Exceptions** — aged list ≤24h for Critical  

### Sign-off

Settlement Ops signs daily recon. Finance samples weekly.

---

## Exception handling

| Exception | Severity | Action |
| --- | --- | --- |
| Pay without ledger | Critical | Freeze new pays · Eng + Finance |
| Double pay (idempotency fail) | Critical | Freeze · reverse per SOP |
| Commission ≠ rule | Critical | Freeze settles · fix + recompute |
| Settle without pay | Critical | Block · postmortem |
| Delayed settle >SLA | High | Prioritize queue |
| Refund mismatch | High | Finance hold |

Escalation: [`08_INCIDENT_RESPONSE_HANDBOOK.md`](08_INCIDENT_RESPONSE_HANDBOOK.md)

---

## Freeze protocol

Marketplace Ops publishes **PAY_FREEZE** or **SETTLE_FREEZE** in ops channel.  
Lift only after Finance + Settlement + Risk agree in writing.

---

## AI / Winga constraints

- AI must never authorize payment (platform enforced).  
- Wingas must never receive off-ledger commission for Winga deals.  

---

## Tools (existing)

- `POST /api/v1/winga/deals/{id}/pay` (Idempotency-Key)  
- `POST /api/v1/winga/deals/{id}/settle-commission`  
- `GET /api/v1/winga/analytics/summary`  
- Payments ledger / admin exports per platform Settlement Guide  

No redesign of payment or commission engines.
