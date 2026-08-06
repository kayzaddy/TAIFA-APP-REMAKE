# 15 — Acceptance Criteria

---

## Executive summary

Testable criteria for Merchant Platform Phase 1 completion and **authorization to start TNPI Phase 2 (Payment Sources Platform)**.

---

## Business purpose

Objective gate for Architecture Board, Security, and Product.

---

## Functional acceptance

| ID | Criterion |
| --- | --- |
| AC-F1 | Merchant can register, submit KYB, be approved, and reach `active` in staging |
| AC-F2 | Head office + ≥10 branches created; hierarchy query &lt; 200ms p95 |
| AC-F3 | Employee invited, role assigned, login accesses only scoped branch |
| AC-F4 | Device registered, activated, revoked; events emitted |
| AC-F5 | Settlement account metadata stored; verify workflow documented |
| AC-F6 | API key and webhook registered; secret not retrievable after create |
| AC-F7 | Merchant portal shows profile, branches, devices, employees (no live payments) |
| AC-F8 | Ops can search merchants and view audit trail |

---

## Non-functional acceptance

| ID | Criterion |
| --- | --- |
| AC-N1 | Merchant API 99.9% availability in staging over 30 days |
| AC-N2 | All state-changing APIs idempotent where specified |
| AC-N3 | 100% merchant mutations audited |
| AC-N4 | DR drill: RDS restore documented and tested once |

---

## Security acceptance

| ID | Criterion |
| --- | --- |
| AC-S1 | Threat model signed |
| AC-S2 | No P1 open vulnerabilities on merchant service |
| AC-S3 | RBAC denial tests pass for cashier vs developer |
| AC-S4 | Documents encrypted at rest (KMS) |

---

## Compliance acceptance

| ID | Criterion |
| --- | --- |
| AC-C1 | KYB policy document approved |
| AC-C2 | Data retention schedule published |
| AC-C3 | PCI Phase 1 scope document (no CDE) signed |

---

## Architecture acceptance

| ID | Criterion |
| --- | --- |
| AC-A1 | OpenAPI `tnpi-merchant-v1` published |
| AC-A2 | All [08_EVENT_CATALOG.md](08_EVENT_CATALOG.md) events implemented for MVP paths |
| AC-A3 | No direct payment processing code in merchant service |

---

## Exit criteria → Phase 2 (Payment Sources Platform)

Phase 2 may start when **all** of:

1. AC-F1–F8, AC-N1–N4, AC-S1–S4, AC-C1–C3, AC-A1–A3 **passed** in staging sign-off.  
2. [PHASE1_GATE_PACKAGE.md](PHASE1_GATE_PACKAGE.md) signed by Platform Lead, TNPI Product, Security.  
3. Taifa Core **Identity + Event bus** production-ready in staging (Core MS-S1/S3).  
4. ≥ **5 pilot merchants** onboarded end-to-end (can be synthetic in staging for gate; real pilot parallel).  
5. Risk register [17_RISK_REGISTER.md](17_RISK_REGISTER.md) — no open **P1** without accepted mitigation.  
6. Orchestration/wallet/SoftPOS/QR **repos and routes** not deployed to prod.

---

## AWS / implementation

Evidence in `docs/payments/merchant/evidence/` (create during implementation).

---

## Future expansion

Phase 2 acceptance criteria drafted before gate meeting.

---

## Cross-references

[16_DEFINITION_OF_DONE.md](16_DEFINITION_OF_DONE.md)
