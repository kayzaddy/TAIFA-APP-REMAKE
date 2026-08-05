# Settlement Guide

Merchant settlement pays down `merchant_payable` to the merchant bank account
through the journal — never via Admin or ad-hoc SQL.

## Modes

| Mode | Behaviour |
|------|-----------|
| daily | Batch create for prior day captures |
| instant | Create + execute when below approval threshold |
| scheduled | `scheduled_at` set; beat/worker executes |
| manual | Ops creates settlement explicitly |

## Lifecycle

`draft` → (`pending_approval` if over threshold) → `approved` → `processing` → `completed`  
Cancel allowed before `completed`. Split settlements create child rows (`PARTIAL` parent).

## APIs

- Create: `POST …/merchants/{id}/settlements`
- Execute: `POST …/settlements/{id}/execute`
- Cancel: `POST …/settlements/{id}/cancel`
- Approve: maker-checker via `POST …/approvals/{id}/decide`

## Reconciliation

Match merchant settlement batches to bank statements using provider settlement
ingest (`ingest_settlement_csv`) plus merchant statement exports (`statement_ref`).
