# Taifa Express — Operations Handbook

## Onboarding

1. Seed or create `ExpressStore` + products.  
2. Link `enterprise.Merchant` when ready for real settlement (foundation uses platform commerce merchant).  
3. Ensure Mobility has delivery bike pricing seeded (`seed_mobility` / national mode pricing).  
4. Fund demo wallets for pilot customers.

## Incidents

| Incident | Playbook |
| --- | --- |
| Merchant reject / OOS | Cancel or substitute; refund via Payments ops |
| No rider | Order stays `ready` / paid; retry `…/deliver` |
| Wrong item | Dispute → Commerce/MAP refund path |
| Lost delivery | Mobility POD + support ticket |

## KPIs (instrument later — do not fabricate)

Daily orders · basket value · acceptance rate · delivery success · ETA accuracy · CSAT · commission revenue

## Support channels

Reuse Notification Platform + existing ops desks (City Ops / Fleet Ops). Express adds order public codes (`xp_…`).
