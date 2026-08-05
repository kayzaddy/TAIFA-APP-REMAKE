# 9. Inventory Governance Manual

**Owner:** Inventory Control Lead  

---

## Monitored signals

| Signal | Definition | Cadence |
| --- | --- | --- |
| Inventory accuracy | Counted vs system on_hand | Weekly sample / monthly full |
| Shrinkage | Unexplained loss | Weekly |
| Damaged goods | Quarantine + adjust | Continuous |
| Reserved stock | Sum reserved vs open orders | Daily |
| Stock aging | Days since last movement | Weekly |
| Expiry | FEFO breaches | Daily (tracked SKUs) |
| Batch / serial integrity | Traceability gaps | On receive/issue |
| Warehouse utilization | Capacity proxy | Monthly |
| Inventory health score | Composite (accuracy, low-stock, shrinkage) | Weekly |

## Controls

- All changes via stock movements  
- Dual review for large adjusts  
- Low-stock alerts → Procurement within 24h  
- Health score below threshold → Merchant Success coaching  

## Health score (simple)

Start at 100. Subtract: accuracy miss (−10), open shrinkage (−15), critical out-of-stocks (−5 each, cap −25), recon backlog (−10). Target ≥ 85 for certification.
