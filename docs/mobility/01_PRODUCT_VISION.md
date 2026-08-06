# 01 — Product Vision

---

## Executive summary

**TNMP** is Tanzania’s **20-year national mobility platform**: one digital nervous system for public and private transport, tourism, government fleets, emergencies, and future autonomous/EV/smart-city infrastructure—**payments exclusively through [TPP](../transport/00_PLATFORM_OVERVIEW.md) → TNPI**.

---

## Business purpose

Unify mobility data and operations nationwide; enable cashless adoption, safety, planning, and regional integration without fragmenting payment infrastructure.

---

## Architecture overview

```mermaid
flowchart TB
  subgraph vision [2030+ vision]
    SMART[Smart city sensors]
    EV[EV charging mesh]
    AUTO[Autonomous shuttles]
  end
  subgraph tnmp [TNMP today forward]
    OPS[Operations ITS]
    AI[AI assistant]
    GOV[Gov intelligence]
  end
  vision -.-> tnmp
  tnmp --> TPP[TPP]
  TPP --> TNPI[TNPI]
```

---

## Vision statement

**One platform for every journey—planned, paid, operated, and governed with trust.**

---

## Strategic pillars

| Pillar | Outcome |
| --- | --- |
| **Connected** | Real-time fleet & passenger awareness |
| **Inclusive** | Accessibility-first planning |
| **Cashless** | TNPI-mediated fares (TPP) |
| **Transparent** | Govt analytics & LATRA oversight |
| **Intelligent** | AI planning & predictive ops |
| **Regional** | East Africa interoperability (future) |

---

## Capability model (detailed)

Passenger · Operator · Fleet · Driver · Vehicle · Route/Stop/Station · Trip/Journey · AI planner · RT tracking · Schedules · Ticketing *(TPP)* · Subscriptions *(TPP/TNPI)* · Analytics · Govt dashboards · Incidents · Emergency · Accessibility · Inspection · Lost & found · Support.

---

## Domain model

```mermaid
erDiagram
  PASSENGER ||--o{ JOURNEY : takes
  JOURNEY ||--o{ TRIP_LEG : contains
  OPERATOR ||--o{ FLEET : owns
  FLEET ||--o{ VEHICLE : has
  VEHICLE ||--o{ TRIP : executes
  ROUTE ||--o{ TRIP : follows
  TRIP ||--o| TICKET_REF : paid_via_TPP
```

---

## Payments (delegation)

| Need | Call |
| --- | --- |
| Buy ticket / pass | TPP APIs → TNPI |
| Corporate / govt subsidy | TNPI metadata + TPP products |
| Revenue dashboard | TNPI settlement read via TPP/portal |

---

## Sequence: passenger day

```mermaid
sequenceDiagram
  participant U as User
  participant N as TNMP
  participant A as AI assistant
  participant T as TPP
  U->>A: Plan trip NL
  A->>N: journey options
  U->>T: confirm pay via TPP
  T->>TNPI: payment
  N->>N: track vehicle RT
  N-->>U: live trip + ticket ref
```

---

## Security considerations

National-scale PII; role separation — [11_SECURITY_MODEL.md](11_SECURITY_MODEL.md).

---

## AWS

Multi-region ready architecture — [12_AWS_ARCHITECTURE.md](12_AWS_ARCHITECTURE.md).

---

## Implementation strategy

MVP → national → smart city — [14_ROADMAP.md](14_ROADMAP.md).

---

## Future expansion

Drone corridors · V2X · cross-border East Africa pass.

---

## Cross-references

[TNMP_GATE_PACKAGE.md](TNMP_GATE_PACKAGE.md)
