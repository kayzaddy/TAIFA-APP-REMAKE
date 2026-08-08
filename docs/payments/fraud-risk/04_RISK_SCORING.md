# 04 — Risk Scoring

---

## Executive summary

**Unified risk score** (0–1000) combining trust dimensions, behavioral signals, velocity, location, time, fraud/chargeback history, and rule deltas—mapped to **Approve**, **Review**, **Decline**, **Escalate**.

---

## Business purpose

Consistent decisions across channels; explainable outcomes for merchants and regulators.

---

## Architecture overview

```mermaid
flowchart TB
  subgraph inputs [Trust inputs]
    MT[Merchant trust]
    CT[Customer trust]
    DT[Device trust]
    PST[Payment source trust]
    HIST[Historical activity]
    BEH[Behavioral patterns]
    LOC[Location time velocity]
    FRAUD[Prior fraud CB]
  end
  inputs --> MODEL[Scoring model v1]
  MODEL --> RAW[Raw score]
  RULES[Rule deltas] --> RAW
  ML[ML delta optional] --> RAW
  RAW --> CLAMP[Clamp 0-1000]
  CLAMP --> MAP[Decision thresholds]
```

---

## Input dimensions

| Dimension | Source | Weight (v1 indicative) |
| --- | --- | --- |
| Merchant trust | KYC tier, tenure, chargeback rate | 25% |
| Customer trust | account age, verify level | 20% |
| Device trust | enrollment, attestation | 15% |
| Payment source | token age, issuer country | 15% |
| Behavior | amount vs baseline | 15% |
| Context | geo, time, velocity | 10% |

---

## Output decisions

| Score band | Decision | Orchestration action |
| --- | --- | --- |
| 0–299 | Approve | Continue auth |
| 300–599 | Review | Hold + manual queue |
| 600–799 | Decline | Block |
| 800–1000 | Escalate | Decline + fraud alert + optional case |

Thresholds **configurable** per product; merchant tiers may shift bands.

---

## Risk decision flow

```mermaid
flowchart LR
  S[Score 0-1000] --> T{Thresholds}
  T --> A[Approve]
  T --> R[Review]
  T --> D[Decline]
  T --> E[Escalate]
```

---

## Sequence: score generated

```mermaid
sequenceDiagram
  participant E as Risk Engine
  participant S as Scoring Service
  participant DB as RDS
  E->>S: features vector
  S-->>E: score + components
  E->>DB: risk_score row
  E->>E: emit risk.score.generated
```

---

## Explainability

Persist `score_components` JSON: `{ merchant: 72, velocity: -40, rule_RULE-001: 150 }`.

---

## Reconciliation feed

Elevated recon exception rate on merchant → negative trust delta (async, daily aggregate).

---

## API / DB / events

GET `/risk/scores/{assessment_id}` · `RiskScore` entity · `risk.score.generated`.

---

## Security

Scores may contain sensitive inference—restrict to fraud/finance roles.

---

## Operational considerations

Monitor score distribution drift; quarterly threshold review.

---

## Implementation strategy

v1 weighted formula; v2 calibrated on labeled cases; v3 ML blend.

---

## Future expansion

Chargeback prediction model as pre-emptive score input.

---

## Cross-references

[02_RISK_ENGINE.md](02_RISK_ENGINE.md) · [09_DATABASE_MODEL.md](09_DATABASE_MODEL.md)
