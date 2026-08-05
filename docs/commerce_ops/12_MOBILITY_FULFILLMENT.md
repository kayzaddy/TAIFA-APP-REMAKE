# 12. Mobility Fulfillment Guide

**Owner:** Warehouse Ops (A) · Mobility ops partner · Customer Success  

---

## Coordinate

| Step | Owner | Notes |
| --- | --- | --- |
| Pickup scheduling | Warehouse | After pack ready |
| Driver assignment | Mobility | Shared trips platform |
| Tracking / ETA | Mobility | Customer notifications |
| Proof of delivery | Driver / Mobility | Attach to order metadata / ref |
| Failed delivery | Warehouse + CS | Retry / return-to-stock |
| Returns | Warehouse | Inspect + movement |
| Analytics | Management | Delivery success %, latency |

## Order field

`SalesOrder.mobility_job_ref` stores the Mobility reference — do not invent a second delivery ledger.

## SLA examples (tune per city)

| Zone | Dispatch after pack | Deliver |
| --- | --- | --- |
| Local CBD | ≤ 30 min | ≤ 2 h |
| Metro | ≤ 1 h | ≤ 4 h |
