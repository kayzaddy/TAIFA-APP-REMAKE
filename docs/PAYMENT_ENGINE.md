# TAIFA Payment Engine — Accounting Architecture

This is the authoritative design for money movement. Product features must not
bypass it. Auditors (central bank, external, security) should be able to trace
every balance change to an immutable, balanced journal entry.

## Single source of truth

| Layer | Role |
|-------|------|
| **Ledger** (`LedgerEntry` + `Posting`) | Source of truth for money. Append-only. |
| **Transaction** | Lifecycle / UX record (status, rail refs). Never holds a balance. |
| **API / views** | Auth, validation, idempotency headers. Never post debits/credits. |
| **Payment Engine** | Orchestrates validation → rail → **journal** → status. |
| **Journal** (`journal.py`) | Only module that builds posting specs for money events. |

Balances are always `Σ(postings)` via `ledger.balance_of`. No endpoint may
mutate a balance field — none exists.

**Control plane:** see [`CORE_BANKING_ARCHITECTURE.md`](CORE_BANKING_ARCHITECTURE.md)
(Orchestrator → Risk → Journal → Ledger → Events/Audit).

**Production readiness (P0):** see [`PRODUCTION_GATE.md`](PRODUCTION_GATE.md).
No money path may mint demo balances, accept unsigned webhooks, or settle
outside the orchestrator when holding real customer funds.

## Chart of accounts (house + user)

| Account type | Normal | Purpose |
|--------------|--------|---------|
| `user_wallet` | Credit | Customer available funds |
| `funds_on_hold` | Credit | Authorized but not yet paid out (withdrawals) |
| `provider_settlement` | Debit | Clearing with MM/bank/card rails |
| `fee_income` | Credit | Platform fees |
| `commission_income` | Credit | Partner commissions (reserved) |
| `merchant_payable` | Credit | Amounts owed to merchants (reserved) |
| `treasury` | Debit | Operating / treasury cash (adjustments) |
| `suspense` | Debit | Temporary / opening / investigation |
| `external_*` | — | Rail counterparts when explicitly modelled |

Natural keys are stable (`user:{owner}:wallet:TZS`, `user:{owner}:hold:TZS`,
`house:provider-settlement:TZS`, …).

## Double-entry invariant

`ledger.post_entry` refuses any unbalanced set of postings (debits ≠ credits
per currency). Reconciliation re-checks every entry and global conservation
daily. Corrections are **never** edits — only compensating journals.

## Money flows (this tranche)

### Top-up (existing)

Success: `DR provider_settlement / CR user_wallet`.

Pending STK: no ledger until success (funds not yet received).

### Transfer / send (existing)

Success: `DR user_wallet / CR provider_settlement` (+ `CR fee_income` if fee).

### Withdrawal (new)

| State | Ledger |
|-------|--------|
| `pending` | None (request only) |
| `approved` | **Hold:** `DR user_wallet / CR funds_on_hold` |
| `rejected` (from pending) | None |
| `rejected` / `failed` (after hold) | **Release:** `DR funds_on_hold / CR user_wallet` |
| `processing` | Hold remains; rail payout in flight |
| `succeeded` | **Settle:** `DR funds_on_hold / CR provider_settlement` |
| `reversed` | Compensating journal reversing the settle (and hold if needed) |

Available balance drops at **approve** (hold), not at request — prevents
oversell while awaiting ops approval.

### Refund (new)

References `parent` succeeded transaction. Supports partial and multiple
refunds; cumulative refunds cannot exceed original principal.

Compensating postings (principal):

- Original **top-up**: `DR user_wallet / CR provider_settlement`
- Original **send / withdrawal**: `DR provider_settlement / CR user_wallet`

Full refund of a fee-bearing send also reverses fee: `DR fee_income / CR user_wallet`.

### Reversal (new)

Creates a new `reversal` transaction + journal that **mirrors** the target
ledger entry (debit↔credit). Marks original `reversed`. Never mutates history.

## Idempotency

- Client `Idempotency-Key` + payload hash (existing) for initiate APIs.
- State transitions use `select_for_update` on the transaction row so concurrent
  approve/settle/refund cannot double-post.
- Journal helpers no-op if a transition’s expected entry kind already exists.
- Webhook processor remains persist-then-process (existing).

## Failure & recovery

| Failure | Outcome |
|---------|---------|
| Crash after hold, before rail | Hold remains; reconcile + ops release or retry process |
| Duplicate webhook | Idempotent settle / fail |
| Rail accept after local fail | Investigation via suspense / manual journal (treasury tranche) |
| Partial refund race | Row lock + sum(child refunds) check |

No silent failures: declined money ops return explicit status; journal rejects
unbalanced specs.

## Reconciliation impact

Daily job already verifies conservation and succeeded↔ledger linkage. After
this tranche it also sees hold / release / refund / reversal entries. Provider
**file** matching (missing/duplicate/amount mismatch) is the next infrastructure
tranche — metrics + Alertmanager rules are in place for ledger breaks now.

## Security

- Device-scoped ownership on all money APIs.
- Hold + `select_for_update` against double-spend on concurrent withdrawals.
- Integer minor units only (no float).
- Append-only ORM + DB triggers (Postgres).
- Webhook IP/secret trust (existing).

## Observability

Prometheus gauges for reconciliation; Alertmanager rules page on
`taifa_ledger_reconciliation_ok == 0` and related money SLIs. Grafana dashboard
JSON is provisioned under `deploy/observability/` for import.

## Explicitly deferred (next engine tranches)

Chargebacks (dispute lifecycle), merchant settlement batches, treasury
adjustments, interest/cashback posting, and provider settlement-file
reconciliation reports. CoA types for merchant/commission/treasury are reserved
so those flows attach to the same journal without schema rewrites.
