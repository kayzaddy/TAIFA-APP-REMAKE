# 14 — Backlog (Merchant Platform)

**Prioritization:** MoSCoW · **Estimates:** story points (relative)

---

## Executive summary

Product backlog for Phase 1 implementation sprints—merchant ecosystem only.

---

## Business purpose

Single queue for Platform + TNPI merchant squad.

---

## Must have

| ID | Story | Pts | Sprint |
| --- | --- | --- | --- |
| MB-001 | Merchant aggregate + draft registration API | 5 | MP-1 |
| MB-002 | Onboarding state machine + events | 8 | MP-1 |
| MB-003 | Document upload presign + S3 | 5 | MP-1 |
| MB-004 | KYB review queue (internal) | 5 | MP-1 |
| MB-005 | Approve / reject / activate | 5 | MP-1 |
| MB-006 | Branch CRUD + hierarchy | 8 | MP-2 |
| MB-007 | Employee invite + Identity link | 8 | MP-2 |
| MB-008 | RBAC catalog + assignments | 8 | MP-2 |
| MB-009 | Settlement account metadata + verify stub | 5 | MP-3 |
| MB-010 | Device register / activate / revoke | 8 | MP-3 |
| MB-011 | Device heartbeat + health | 3 | MP-3 |
| MB-012 | API key create / revoke | 5 | MP-4 |
| MB-013 | Webhook endpoint CRUD | 5 | MP-4 |
| MB-014 | Merchant search (ops) | 5 | MP-4 |
| MB-015 | Audit integration Core | 5 | MP-2 |
| MB-016 | Event outbox + EventBridge | 8 | MP-2 |
| MB-017 | Merchant portal profile + branches UI | 8 | MP-5 |
| MB-018 | Dashboard shell (no payments tab data) | 5 | MP-5 |
| MB-019 | Load test 10k branches query | 5 | MP-6 |
| MB-020 | Phase 1 gate evidence pack | 3 | MP-6 |

---

## Should have

| ID | Story |
| --- | --- |
| MB-030 | Custom roles |
| MB-031 | Merchant branding upload |
| MB-032 | Notification templates onboarding |
| MB-033 | Analytics onboarding funnel |
| MB-034 | Contract record entity |

---

## Could have

| ID | Story |
| --- | --- |
| MB-040 | BRELA API adapter |
| MB-041 | Bulk branch CSV import |
| MB-042 | Department org units |

---

## Won't have (Phase 1)

| Item | Phase |
| --- | --- |
| Payment orchestration | 2 |
| Wallet link execution | 2 |
| SoftPOS charge | 3 |
| QR pay | 3 |
| Settlement batches | 2 |

---

## Architecture / security / AWS

Stories must include updates to [07](07_API_SPECIFICATION.md), [08](08_EVENT_CATALOG.md), [09](09_DATABASE_MODEL.md) as DoD.

---

## Implementation strategy

Groom weekly; tie to [12_IMPLEMENTATION_GUIDE.md](12_IMPLEMENTATION_GUIDE.md) stages.

---

## Future expansion

Backlog grooming for Phase 2 read-only payment widgets.

---

## Cross-references

[PHASE1_GATE_PACKAGE.md](PHASE1_GATE_PACKAGE.md) § Sprint breakdown
