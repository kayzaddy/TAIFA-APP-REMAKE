# Data Governance

Data is a strategic asset. Canonical money model remains Payments ledger; domains store references, not competing balances.

## Practices

| Practice | Implementation |
| --- | --- |
| Canonical models | [`../DATA_MODEL.md`](../DATA_MODEL.md), OpenAPI schemas |
| Ownership | [`OWNERSHIP.md`](OWNERSHIP.md) Data Owner per domain |
| Classification | public · internal · confidential · restricted (PII/financial) |
| Lineage | Domain events + outbox; payment audit trail |
| Quality | Constraints, append-only ledger, registry verification statuses |
| Lifecycle | Retention via continental residency + compliance profiles |
| MDM / reference | Country, currency, rails, language packs in continental |
| Metadata catalog | Start with OpenAPI + model docstrings; expand to data catalog tool later |

## Backup & recovery

Follow [`../DISASTER_RECOVERY.md`](../DISASTER_RECOVERY.md). Deletion/archival must not break append-only financial history — soft-delete or legal hold as required.
