# 18 — Risk Register

---

## Executive summary

TNMP program risks—including organizational, technical, and payment-boundary risks.

---

| ID | Risk | Impact | Likelihood | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- |
| M-R01 | Payment logic duplicated in TNMP | Critical | Med | ADR + CI + TPP-only path | Architecture |
| M-R02 | TPP/TNMP boundary confusion | High | Med | Context map, clear APIs | Product |
| M-R03 | Telematics spoofing | High | Med | Device certs, anomaly | Security |
| M-R04 | Gov data over-exposure | Critical | Low | Anonymization, ABAC | Compliance |
| M-R05 | Operator adoption failure | High | Med | MVP co-design, LATRA | Program |
| M-R06 | AI unsafe routing | High | Med | Human confirm, guardrails | AI lead |
| M-R07 | Peak load position ingest | High | Med | Kinesis, autoscale | SRE |
| M-R08 | Vendor lock-in maps | Med | Med | Abstract map provider | Architecture |
| M-R09 | Cross-city data model drift | Med | High | GTFS standards | Engineering |
| M-R10 | TNPI outage blocks sales | High | Low | TPP honor active tickets | Ops |

---

## ADR

**ADR-TNMP-001** — TNMP never implements TNPI capabilities; all payments via TPP.

---

## Cross-references

[TNMP_GATE_PACKAGE.md](TNMP_GATE_PACKAGE.md)
