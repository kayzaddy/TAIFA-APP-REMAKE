# 12 — Observability

---

## Executive summary

Financial monitoring, match rate, exception metrics, provider health, latency, alerts, KPI dashboards.

---

## Business purpose

Detect recon degradation before treasury impact.

---

## Metrics

| Metric | Description |
| --- | --- |
| `recon.match_rate` | Auto match % |
| `recon.exceptions.open` | Gauge by type |
| `recon.job.duration` | Histogram |
| `recon.amount_unmatched` | Sum currency |
| `recon.provider.file.late` | Counter |
| `financial.close.duration` | Histogram |

---

## Dashboards

Finance ops · Treasury · Executive match rate · Provider SLA.

---

## Alerts

Match rate &lt; 95%; exceptions &gt; SLA; job failed; file missing.

---

## Architecture / API / security

Correlation with `reconciliation_job_id`.

---

## Operational considerations

Weekly KPI review with treasury.

---

## Implementation strategy

Align Core monitoring platform.

---

## Future expansion

Anomaly detection on exception spikes.

---

## Cross-references

[orchestration/12_OBSERVABILITY.md](../orchestration/12_OBSERVABILITY.md)
