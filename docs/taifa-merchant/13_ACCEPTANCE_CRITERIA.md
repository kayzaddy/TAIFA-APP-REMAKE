# 13 — Acceptance Criteria

---

## Functional

| ID | Criterion |
| --- | --- |
| AC-TM-1 | Owner registers via Identity and creates TNPI merchant |
| AC-TM-2 | KYB status reflects TNPI (no local override) |
| AC-TM-3 | Cashier generates QR; customer pays; tx appears < 30s |
| AC-TM-4 | Manager refunds; TNPI `refund.completed` updates UI |
| AC-TM-5 | Receipt share link opens valid receipt |
| AC-TM-6 | Notification received on payment |
| AC-TM-7 | Employee invite: Identity login scoped to merchant |

---

## Non-functional

| ID | Criterion |
| --- | --- |
| AC-N1 | All APIs via TIP in staging |
| AC-N2 | No payment tables in `taifa_merchant` schema |
| AC-N3 | P95 BFF read dashboard < 800ms |
| AC-N4 | WCAG 2.1 AA critical paths |

---

## SoftPOS (post-MVP wave)

| ID | Criterion |
| --- | --- |
| AC-TM-8 | SoftPOS payment E2E on certified device |

---

## Cross-references

[14_DEFINITION_OF_DONE.md](14_DEFINITION_OF_DONE.md)
