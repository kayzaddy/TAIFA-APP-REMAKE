# 01 — Product Vision

---

## Executive summary

The **Payment Orchestration Platform** is TNPI Phase 3: enterprise-grade coordination of every Taifa payment—millions of transactions, multi-rail, multi-vertical—through one state machine, router, and saga layer.

---

## Business purpose

Vertical modules must not embed PSP logic. One orchestrator ensures consistency, auditability, and national scale.

---

## Architecture overview

```mermaid
flowchart TB
  subgraph channels [Channels Phase 4+]
    API[E-Com API]
    TOUR[Tourism Checkout]
    MOB[Mobility Fare]
    GOV[Government Bill]
  end
  subgraph orch [Orchestration Platform]
    GW[Payment Orchestration API]
    SM[State Machine]
    RT[Smart Router]
    WF[Workflow Engine]
    SG[Saga Coordinator]
    WH[Webhook Dispatcher]
  end
  subgraph deps [Dependencies]
    MER[Merchant Platform]
    SRC[Payment Sources]
    PSP[PSP Execution Adapters]
  end
  channels --> GW
  GW --> SM --> RT
  SM --> WF --> SG
  GW --> MER & SRC
  RT --> PSP
  SG --> WH
```

---

## Product vision

**Every payment, one engine—reliable, observable, fair to every rail.**

---

## Vertical coverage (consumers)

Taifa Tourism · Mobility · Trade · Commerce · Government · Health · Education · future products—all call `POST /payments` with channel metadata.

---

## Sequence: tourism checkout

```mermaid
sequenceDiagram
  participant T as Tourism Orchestration
  participant O as Payment Orchestration
  participant S as Payment Sources
  participant P as PSP Adapter
  T->>O: create payment {merchant_id, amount, source_id}
  O->>S: validate payment_source
  O->>P: authorize/charge
  P-->>O: pending|completed
  O-->>T: payment_id + status
```

---

## API / events / database / AWS / security

See docs 07–12.

---

## Operational considerations

SLO: 99.95% orchestration API; p95 latency &lt; 500ms excluding PSP.

---

## Implementation strategy

Strangler from `apps/backend/payments/` router behind `tnpi.orchestration` flag.

---

## Future expansion

AI routing; real-time fraud ML; cross-border orchestration.

---

## Cross-references

[PHASE3_GATE_PACKAGE.md](PHASE3_GATE_PACKAGE.md)
