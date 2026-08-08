# 14 — Backlog

---

## Executive summary

MoSCoW backlog for Payment Sources Phase 2.

---

## Business purpose

Sprint planning source of truth.

---

## Must have

| ID | Story | Pts | Sprint |
| --- | --- | --- | --- |
| PSB-001 | PaymentProviderPort interface + registry | 5 | PS-0 |
| PSB-002 | RDS schema + migrations | 8 | PS-0 |
| PSB-003 | Consent API + audit | 8 | PS-1 |
| PSB-004 | Link session + Redis | 5 | PS-1 |
| PSB-005 | M-Pesa adapter link + callback | 13 | PS-1 |
| PSB-006 | List / get payment sources | 5 | PS-2 |
| PSB-007 | Verify + validation endpoints | 5 | PS-2 |
| PSB-008 | Unlink + revoke cascade | 5 | PS-2 |
| PSB-009 | Default + priority preferences | 5 | PS-2 |
| PSB-010 | Event outbox all MVP events | 8 | PS-2 |
| PSB-011 | Airtel adapter | 8 | PS-3 |
| PSB-012 | Provider discovery API | 3 | PS-3 |
| PSB-013 | Provider health monitor | 5 | PS-6 |
| PSB-014 | Mixx / Halo adapter (one) | 8 | PS-3 |
| PSB-015 | Bank OAuth adapter MVP | 8 | PS-4 |
| PSB-016 | Card tokenization integration | 13 | PS-5 |
| PSB-017 | Customer payment profile API | 5 | PS-2 |
| PSB-018 | Legacy wallet API deprecation plan | 3 | PS-7 |
| PSB-019 | Load test link flow | 5 | PS-7 |
| PSB-020 | Phase 2 gate evidence | 3 | PS-7 |

---

## Should have

| ID | Story |
| --- | --- |
| PSB-030 | Recurring permission metadata |
| PSB-031 | Failover preference config |
| PSB-032 | Provider incident banners in app |

---

## Won't have (Phase 2)

| Item | Phase |
| --- | --- |
| POST /payments charge | 3 |
| Settlement | 2 program doc — 4 |
| SoftPOS / QR | 3 acceptance |
| Balance-funded wallet float | Never |

---

## API / events / security / AWS

DoD per [16_DEFINITION_OF_DONE.md](16_DEFINITION_OF_DONE.md).

---

## Implementation strategy

Map to [PHASE2_GATE_PACKAGE.md](PHASE2_GATE_PACKAGE.md) sprints.

---

## Future expansion

Orchestrator integration stories in Phase 3 backlog.

---

## Cross-references

[12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md)
