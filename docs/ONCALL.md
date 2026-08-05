# TAIFA On-Call Guide

## Expectations

- Ack SEV-1 within 5 minutes, SEV-2 within 15 minutes.
- Follow [`INCIDENT_RESPONSE.md`](INCIDENT_RESPONSE.md); page secondary if stuck > 30 minutes.
- Never edit ledger/transactions in Django Admin.
- Never enable demo funding / demo STK in production.

## Tools

| Tool | URL / path |
|------|------------|
| Grafana | `:3000` (Executive + Operations first) |
| Prometheus | `:9090` |
| Alertmanager | `:9093` |
| Probes | `/healthz` `/readyz` `/startupz` `/depsz` |
| Runbooks | [`RUNBOOKS.md`](RUNBOOKS.md) |

## Handoff checklist

- [ ] Open incidents + severity
- [ ] Active change freezes
- [ ] Backup marker fresh (`taifa_backup_last_success_timestamp_seconds`)
- [ ] Known provider outages
- [ ] Secret rotations in progress

## After-hours changes

Production config changes require dual control (on-call + secondary) for:
risk unlimited flags, webhook secrets, demo flags, schema migrations.
