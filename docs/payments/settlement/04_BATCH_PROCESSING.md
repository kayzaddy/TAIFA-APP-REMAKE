# 04 — Batch Processing

---

## Executive summary

**Settlement batches**: windows, calendar, cutoffs, aggregation, batch creation, execution scheduling, exception handling.

---

## Business purpose

Efficient PSP payout files and treasury operations.

---

## Architecture

```mermaid
flowchart TB
  WIN[Settlement Window] --> AGG[Aggregate Items]
  AGG --> BATCH[SettlementBatch]
  BATCH --> EXEC[Execute Payouts]
  EXEC --> DONE[settlement.batch.completed]
```

---

## Settlement calendar

| Concept | Definition |
| --- | --- |
| Window | e.g. daily 23:00 EAT cutoff |
| T+1 / T+0 | Payout delay policy per merchant tier |
| Holiday | Skip or early close via calendar service |

---

## Batch state

```mermaid
stateDiagram-v2
  [*] --> open
  open --> closed: cutoff
  closed --> processing: execute
  processing --> completed: all_payouts_ok
  processing --> partial_failed: some_fail
  partial_failed --> processing: retry
  completed --> [*]
```

---

## Sequence: batch close

```mermaid
sequenceDiagram
  participant Cron as Scheduler
  participant B as Batch Service
  participant P as Payout Engine
  Cron->>B: close window
  B-->>Bus: settlement.batch.created
  B->>P: initiate payouts
  P-->>B: results
  B-->>Bus: settlement.completed
```

---

## API / events / DB

[06](06_API_SPECIFICATION.md) · `settlement.batch.*` · [08](08_DATABASE_MODEL.md)

---

## AWS

Step Functions batch pipeline; EventBridge schedule.

---

## Security

Batch totals dual-control sign-off for &gt; threshold.

---

## Operational model

Finance ops dashboard; reopen batch ADR-only.

---

## Implementation strategy

Start daily merchant batch; add vertical batches later.

---

## Future expansion

Real-time micro-batches for instant tier.

---

## Cross-references

[05_PAYOUT_ENGINE.md](05_PAYOUT_ENGINE.md)
