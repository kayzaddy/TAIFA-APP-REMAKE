# 14. Operational KPI Dictionary

**Owner:** Principal Business Process / OpEx  
**Rule:** Every KPI has definition, source, owner, cadence. Never invent values.

| KPI | Definition | Source | Owner | Cadence |
| --- | --- | --- | --- | --- |
| Sales / GMV | Sum paid order totals | MOS analytics / orders | Store Ops | Daily/Weekly |
| Orders | Count created / paid | MOS | Store Ops | Daily |
| Inventory accuracy | 1 − \|system−count\|/system | Counts | Inventory Control | Weekly |
| Fulfillment rate | Fulfilled on time / paid due | Orders | Warehouse | Daily/Weekly |
| Revenue (platform) | Fees if configured | Finance | Finance | Monthly |
| Profit (merchant) | Gross − COGS − fees (ops sheet) | Finance + Merchant | Merchant Success | Monthly |
| Returns % | Returned / paid | Orders | CS | Weekly |
| Refunds | Count / amount | Settlement | Settlement | Daily |
| Settlement latency | Capture → merchant payout | Enterprise | Settlement | Weekly |
| Support SLA hit % | On-SLA tickets / total | Tickets | Support | Weekly |
| CSAT | Mean 1–5 (report n) | Surveys | CS | Weekly |
| Merchant satisfaction | Pulse 1–5 | MBR | Merchant Success | Monthly |
| Warehouse productivity | Lines fulfilled / labor hour | Ops | Warehouse | Weekly |
| Staff productivity | Sales/hour (cashier) | POS | Store Ops | Weekly |
| Low-stock SKUs | Count ≤ reorder | Stock | Inventory | Daily |
| Open recon exceptions | Unresolved finance items | Recon log | Settlement | Daily |
| Winga contribution | GMV via Winga channel | Winga + MOS | Merchant Success | Weekly |
| Delivery success % | Delivered / dispatched | Mobility | Warehouse | Weekly |

**Null handling:** If no volume, report `0` or `n/a` with note.
