# 17 — Risk Register

---

## Executive summary

Transport program risks with mitigations—financial risks delegated to TNPI controls.

---

| ID | Risk | Impact | Likelihood | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- |
| T-R01 | Duplicate payment logic in TPP | Critical | Med | ADR + CI boundary scan | Architecture |
| T-R02 | Ticket fraud / sharing | High | High | Dynamic QR, validation rate limits, FRP | Fraud ops |
| T-R03 | Offline sync double-use | High | Med | Nonces + revocation | Engineering |
| T-R04 | Operator merchant mis-link | High | Med | Onboarding checklist | Partner ops |
| T-R05 | Peak overload validation | High | Med | Redis + autoscale | SRE |
| T-R06 | Wrong fare published | Med | Med | Effective-dated routes, approval | Product |
| T-R07 | AI planner wrong fare | High | Low | Human confirm before pay | Product |
| T-R08 | Partial journey failure after pay | High | Med | Booking saga + TNPI refunds | Engineering |
| T-R09 | Regulatory data request | Med | Med | Audit logs, govt read role | Compliance |
| T-R10 | TNPI outage blocks transport | High | Low | Honor active tickets; pause sales | SRE |

---

## Proposed ADR

- **ADR-TPP-001** — TPP never implements payment orchestration, settlement, reconciliation, or fraud scoring; TNPI Core only.

---

## Operational considerations

Monthly risk review per active city.

---

## Future expansion

Cross-border fare disputes (T-R11).

---

## Cross-references

[12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md) · [payments/18_RISK_REGISTER.md](../payments/18_RISK_REGISTER.md)
