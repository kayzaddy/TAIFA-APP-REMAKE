# 4. Warehouse Operations Manual

**Owner:** Principal Warehouse Operations Manager  
**Audience:** Warehouse staff · inventory control  

---

## Core procedures

### Receiving
1. Match PO / delivery note  
2. Quantity check  
3. Quality inspection (damage, expiry)  
4. Post `receive` stock movement  
5. Put-away to bin/location (document if no WMS bins yet)  

### Put-away
- Label · location · FIFO/FEFO for expiry-tracked SKUs  

### Transfers
- `transfer_out` source → `transfer_in` destination with same reference  

### Picking / packing
1. Paid order queue  
2. Pick against reserved qty  
3. Pack · label · readiness for dispatch/pickup  
4. `fulfill` (releases reserve + issues)  

### Cycle counting
- `count` movement sets on_hand  
- Variance → Inventory Control within 24h  

### Damage / expiry
- Quarantine · adjust · note batch/serial  
- Never silent delete  

### Returns
- Inspect · `return` movement if restockable · else scrap adjust  

### Reconciliation
- Daily: reserved vs open orders  
- Weekly: count sample ≥ N SKUs  

## SLAs

| Activity | Target |
| --- | --- |
| Receive posting | Same day of physical receipt |
| Pick start after pay | ≤ 30 min (business hours) |
| Fulfill paid same-day order | ≤ 2 hours |
| Count variance report | ≤ 24 hours |
