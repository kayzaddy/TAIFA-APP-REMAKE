# 7. Data Governance Framework

**Owner:** CDO  
**Extends:** [`../governance/DATA_GOVERNANCE.md`](../governance/DATA_GOVERNANCE.md) · [`../governance/PRIVACY_COMPLIANCE.md`](../governance/PRIVACY_COMPLIANCE.md)

---

## Define for every platform

| Topic | Owner names |
| --- | --- |
| Data ownership | Domain owner |
| Classification | Public / Internal / Confidential / Restricted |
| Metadata standards | Schema + OpenAPI |
| Retention | Per class |
| Backup | RPO/RTO documented |
| Recovery objectives | DR drill evidence for G8 |
| Privacy controls | Consent / minimization |
| Data lineage | Critical flows mapped |
| Master data | Merchant, principal, product IDs — single sources |

## Money data

Ledger is system of record for balances. Domain tables may reference `payment_ref` only.
