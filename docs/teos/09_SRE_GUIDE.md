# 09 — Site Reliability Engineering guide

**Owner:** SRE Lead

---

## SLIs / SLOs / SLAs

| Tier | Example SLI | SLO (default) | SLA (external) |
| --- | --- | --- | --- |
| **Critical** (TNPI auth path) | Success rate | 99.95% / 30d | Contract-specific |
| **Core** (BFF APIs) | Availability + latency P95 | 99.9%; P95 &lt; 500ms | Best effort |
| **Batch** | Job completion | 99% within window | Internal |

Error budget policy: freeze non-essential deploys when budget &lt; 10%.

---

## Monitoring

- Metrics: Prometheus / CloudWatch  
- Dashboards per service + golden signals (latency, traffic, errors, saturation)  
- Synthetic checks for public health endpoints

---

## Logging & tracing

- JSON logs; correlation `request_id` / `trace_id`  
- OpenTelemetry export to collector  
- PII redaction at ingest

---

## Alerting

| Severity | Response |
| --- | --- |
| P1 | Page on-call; 15m acknowledge |
| P2 | Ticket; 4h |
| P3 | Next business day |

No alert without runbook link.

---

## Incident response

See [11_INCIDENT_MANAGEMENT.md](11_INCIDENT_MANAGEMENT.md).

---

## Runbooks

Location: `docs/runbooks/` or service `RUNBOOK.md` — deploy, rollback, DB failover, queue backlog.

---

## Capacity planning

Quarterly review: CPU/memory, DB connections, queue depth, TPS forecasts tied to product roadmap.

---

## Disaster recovery

| RPO | RTO | Scope |
| --- | --- | --- |
| 1h (critical DB) | 4h | TNPI, Identity |
| 24h | 24h | Non-critical analytics |

Game days annually.

---

## Business continuity

Multi-AZ default; cross-region DR for payment SoR per TNPI program.

---

## Cross-references

[12_OBSERVABILITY.md](12_OBSERVABILITY.md) · [governance/OPERATIONS.md](../governance/OPERATIONS.md)
