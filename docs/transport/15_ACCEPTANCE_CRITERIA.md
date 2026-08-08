# 15 — Acceptance Criteria

---

## Executive summary

Wave-gated acceptance; Wave 1 MVP minimum for first production city.

---

## Wave 0

| ID | Criterion |
| --- | --- |
| AC-T0-1 | Sandbox `payment.completed` activates ticket |
| AC-T0-2 | No wallet balance table in TPP schema |
| AC-T0-3 | `merchant_id` on operator record |

---

## Wave 1 MVP (production pilot)

| ID | Criterion |
| --- | --- |
| AC-T1-1 | Passenger buys BRT QR ticket via app |
| AC-T1-2 | Validation accepts/rejects correctly |
| AC-T1-3 | Dala dala SoftPOS validation via MAP |
| AC-T1-4 | Settlement split visible in TNPI operator report |
| AC-T1-5 | Transport metadata on 100% payments |
| AC-T1-6 | FRP assess invoked by orchestration (observe decline) |

---

## Wave 2+

| ID | Criterion |
| --- | --- |
| AC-T2-1 | Offline validation 24h without central DB |
| AC-T2-2 | Pass renewal triggers TNPI payment |
| AC-T3-1 | Rail OD ticket E2E |
| AC-T4-1 | Air segment ticket + refund path |
| AC-T5-1 | Multimodal journey one payment three legs |

---

## Non-functional

| ID | Criterion |
| --- | --- |
| AC-N1 | Validation p99 &lt; 300ms Wave 1 |
| AC-N2 | Idempotent payment webhook handling |
| AC-N3 | Operator A cannot read Operator B tickets |

---

## Cross-references

[16_DEFINITION_OF_DONE.md](16_DEFINITION_OF_DONE.md)
