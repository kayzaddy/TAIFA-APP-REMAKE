# 13. Incident Response Handbook — Commerce

**Owner:** Head of Operations (coord) · Eng Support (platform) · Finance (money) · Risk (fraud)  
**Aligns with:** platform incident docs · Winga incident overlay  

---

## Severity

| Sev | Definition | Examples |
| --- | --- | --- |
| Sev-1 | Money wrong, widespread outage, active fraud | Settlement mismatch, POS down all stores, double capture |
| Sev-2 | Blocks sales for many | Pay failures, warehouse system down |
| Sev-3 | Degraded / workaround | Single branch POS, slow sync |
| Sev-4 | Minor | Copy / training |

## Playbooks (summary)

| Type | Primary | Contain |
| --- | --- | --- |
| POS failure | Store Ops + Eng | Failover device / manual park then replay with Idempotency-Key |
| Payment failure | Settlement + Eng | PAY_FREEZE if integrity risk |
| Settlement mismatch | Settlement + Finance | SETTLE_FREEZE |
| Inventory mismatch | Inventory Control + Warehouse | Freeze fulfill for SKU |
| Warehouse outage | Warehouse | Divert to alternate / delay SLA comms |
| Supplier delay | Procurement | Expedite / substitute |
| Delivery failure | Warehouse + Mobility + CS | Retry / return |
| Customer complaint | CS | Per CS playbook |
| Fraud | Risk | Suspend actor · preserve evidence |
| Security | Risk + Eng | Rotate keys · notify |

## Required fields

Severity · Owner · Detected_at · Timeline · Impact · Resolution · Root cause · Preventive action · Status  

Sev-1/2 postmortem within 5 business days.
