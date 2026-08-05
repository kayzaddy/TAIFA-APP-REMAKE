# Taifa Commerce — Operations Manual (MOS)

**Owner:** Marketplace / Merchant Operations  
**Aligns with:** [`winga_ops/`](winga_ops/00_INDEX.md) for brokerage; this doc for merchant retail ops.

---

## Daily checklist (merchant MOS)

- [ ] Low-stock alerts reviewed  
- [ ] Open POS sessions (stale > shift length?)  
- [ ] Unpaid open orders aging  
- [ ] Paid unfulfilled orders  
- [ ] Failed pays / Idempotency retries  
- [ ] Purchase orders awaiting receive  
- [ ] Winga-published catalog sync anomalies  

---

## Settlement

Merchant payouts use **enterprise settlement** — not MOS balances.  
See [`SETTLEMENT_GUIDE.md`](SETTLEMENT_GUIDE.md).

---

## Incidents

| Issue | Owner |
| --- | --- |
| Stock negative / mismatch | Merchant Success + MOS ops |
| Pay captured, fulfill failed | Settlement + warehouse |
| AI suggesting payment auth | Product — treat as Sev-2 if user-facing |

---

## Warehouse guide (short)

1. Receive against PO or adjust `receive`  
2. Reserve on order create  
3. Issue on fulfill  
4. Count via `count` movement (sets on_hand)

---

## POS guide (short)

1. Open session with float  
2. Create channel=`pos` orders  
3. Pay via platform  
4. Close session with closing cash  

Offline mode: client queue + replay with Idempotency-Key (implementation roadmap).

---

## Inventory guide (short)

Track `on_hand` and `reserved`. Available = on_hand − reserved.  
Never bypass movements for audited stock.
