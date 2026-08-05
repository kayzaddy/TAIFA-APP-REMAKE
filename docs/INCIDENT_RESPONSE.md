# TAIFA Incident Response Guide

Every production incident follows the same loop. No silent failures — if money
or availability is at risk, page on-call.

## Severity

| Sev | Meaning | Response |
|-----|---------|----------|
| SEV-1 | Ledger imbalance, data loss risk, total payment outage | Immediate page; war room |
| SEV-2 | Settlement mismatch, webhook outage, elevated failures | 15 min ack |
| SEV-3 | Degraded latency, single-worker issues | Business hours |

## Loop

1. **Detect** — Alertmanager / customer report / `/depsz` red
2. **Diagnose** — Grafana dashboards + Loki traces (`request_id` / `trace_id`)
3. **Contain** — Freeze risky paths (disable auto-approve, scale workers, block bad IPs)
4. **Recover** — Runbooks in [`RUNBOOKS.md`](RUNBOOKS.md)
5. **Verify** — `/readyz` green, ledger recon OK, settlement exceptions cleared
6. **Postmortem** — Blameless write-up within 5 business days (SEV-1/2)

## Playbooks

### Ledger imbalance

- Alert: `TaifaLedgerGlobalImbalance` / `TaifaLedgerUnbalancedEntries`
- Diagnose: `python manage.py reconcile_ledger --json`
- Contain: stop money writes if breaks grow (maintenance mode / scale to 0 web)
- Recover: compensating journal via Payment Engine only — never Admin edit
- Verify: recon OK gauge = 1

### Settlement mismatch

- Alert: `TaifaProviderSettlementExceptions`
- Diagnose: inspect `ReconciliationException` rows; re-run CSV ingest
- Recover: [`RUNBOOKS.md#provider-reconciliation`](RUNBOOKS.md)

### Webhook outage

- Alert: `TaifaWebhookBacklog`, `TaifaWebhookAuthFailures`
- Diagnose: auth failure reason series; provider status page; IP allow-list drift
- Recover: fix secret/HMAC; replay durable Celery tasks; demo-complete forbidden in prod

### Database outage

- See [`DISASTER_RECOVERY.md#database-failure`](DISASTER_RECOVERY.md)

### Queue / worker failure

- Alert: `TaifaWorkerDown`, `TaifaQueueBacklog`
- Recover: [`RUNBOOKS.md#restart-workers`](RUNBOOKS.md)

### Fraud / risk spike

- Alert: `TaifaRiskDenySpike`
- Contain: tighten limits; review sanctions list; do not disable risk engine

### Security breach

- Rotate secrets/certs ([`RUNBOOKS.md#rotate-secrets`](RUNBOOKS.md))
- Revoke compromised devices
- Preserve audit logs; engage security lead

## Communication

- SEV-1: status page + enterprise customers within 30 minutes
- Internal: `#taifa-payments-alerts` + PagerDuty bridge
