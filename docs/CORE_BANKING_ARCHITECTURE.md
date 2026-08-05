# TAIFA Core Banking Architecture

**Audience:** Bank of Tanzania auditors, external financial auditors, security
reviewers, and Taifa engineering.  
**Standard:** Stripe / Visa / M-Pesa / Temenos-class correctness — not MVP speed.

This document is the **target** control plane. `PAYMENT_ENGINE.md` remains the
accounting recipe book. Where they differ, this file wins on *structure*;
`PAYMENT_ENGINE.md` wins on *journal math*.

---

## Non-negotiables

1. **Ledger is the only source of truth for money.** No balance columns. No admin
   “fix balance”. No SQL updates to postings.
2. **Every monetary event posts immutable double-entry journals** via one Journal
   Engine (`journal.py` → `ledger.post_entry`).
3. **History is append-only.** Corrections = compensating journals only.
4. **Every money API is idempotent** (client key + payload hash + row locks).
5. **If accounting cannot stay correct, reject the transaction.**

**Production gate (P0 real-funds blockers):** [`PRODUCTION_GATE.md`](PRODUCTION_GATE.md).

**Operations gate (Phase 2):** [`OPERATIONS_READINESS.md`](OPERATIONS_READINESS.md) —
monitoring, alerting, OTel tracing, JSON logs, HA/DR, runbooks.

---

## Target control plane

```
External API
    → API Gateway (auth, throttle, WAF)
    → Payment Orchestrator          # coordinates only
    → Risk Engine                   # allow | deny | review (before money moves)
    → Business Validation           # funds, schema, state machine
    → Journal Engine                # posting recipes only
    → Ledger                        # append-only entries + postings
    → Settlement Engine             # rail I/O (gateways)
    → Domain Events                 # business history (not money)
    → Audit Log                     # who / when / where
    → Notification / Reporting projections
```

| Component | Owns | Must not |
|-----------|------|----------|
| Orchestrator | Sequencing, idempotency entry | SQL ledger math, balances |
| Risk Engine | Fraud / AML / velocity / limits | Post journals |
| Journal Engine | Balanced posting recipes | HTTP, rails |
| Ledger | Persistence + conservation | Business workflow |
| Settlement | Provider I/O | Invent balances |
| Domain Events | What happened (business) | Replace the ledger |
| Audit | Who did it | Store money amounts as truth |

---

## Gap analysis (current → target)

| Capability | Status |
|------------|--------|
| Append-only double-entry ledger | ✅ Live |
| Journal recipes (top-up, transfer, WD, refund, reverse) | ✅ Live |
| Daily conservation reconcile + metrics | ✅ Live |
| Alertmanager / Grafana artifacts | ✅ Checked in (secrets = ops) |
| Formal payment state machine | ✅ This tranche |
| Domain event store | ✅ This tranche |
| Separate audit log | ✅ This tranche |
| Risk engine (velocity / limits / sanctions) | ✅ This tranche |
| Payment Orchestrator (risk → engine → events/audit) | ✅ This tranche |
| Expanded CoA + posting FX metadata | ✅ This tranche |
| Provider settlement-file reconcile | ✅ Live (Phase 1) |
| Chargebacks / merchant settlement batches | ✅ Live (Phase 3 `enterprise` app) |
| Reporting projections (no hot-ledger BI) | ✅ Live (Phase 3) |
| Multi-region DR / chaos suite | ✅ Runbooks + drills (Phase 2); multi-region deploy = infra |
| Distributed tracing (OTel) | ✅ Live (Phase 2, opt-in endpoint) |
| Ops monitoring / alerting / JSON logs / HA | ✅ Live (Phase 2) |
| Rules / approvals / workflows / RBAC | ✅ Live (Phase 3) |

---

## Chart of accounts (production)

Accounts are typed; natural keys remain stable. New types are additive — existing
`user_wallet` / `provider_settlement` / `funds_on_hold` keep working.

**Assets:** treasury, provider_settlement, settlement_pending, cash_in_transit,
wallet_clearing  
**Liabilities:** user_wallet, funds_on_hold, merchant_payable, tax_payable,
provider_payable, fees_payable  
**Revenue:** fee_income, commission_income, fx_gain  
**Expenses:** fx_loss, chargeback_expense, fraud_loss  
**Reserves:** chargeback_reserve, liquidity_reserve  
**Suspense:** suspense, unknown_credits, unknown_debits  

---

## Payment state machine

Canonical statuses on `Transaction.status`:

`pending → approved → processing → succeeded`  
Failure / terminal: `rejected | failed | cancelled | reversed`

Illegal transitions raise `InvalidTransition` and write an audit row. See
`payments/state_machine.py`.

Mapping to industry terms: approved ≈ authorized; succeeded ≈ settled/completed.

---

## Domain events vs ledger

| Store | Answers |
|-------|---------|
| Ledger | What happened to **money**? |
| Domain events | What happened to the **payment**? |
| Audit log | **Who** caused the change? |

Events are append-only and never mutate. They reference `transaction_id` when
applicable.

---

## Risk before money

The Risk Engine runs **before** hold/settle postings on outbound money
(transfer, withdrawal, refund of top-up). Decisions: `allow`, `deny`,
`review` (treated as deny for automated rails until an ops path exists).

Rules (configurable via settings): per-txn limit, daily debit limit, velocity,
sanctions owner list.

---

## Next enterprise tranches (ordered)

1. Merchant portal SPA + full OpenAPI for `/api/v1/enterprise`  
2. Sector rule packs (gov, healthcare, insurance) as configuration  
3. Chargeback reverse compensating journal automation  
4. Reporting warehouse CDC from outbox → OLAP store  
5. Live multi-region active/passive  

Core platform modules (settlement, treasury, chargeback, projections, rules,
approvals, workflows, RBAC) are live — see [`FINANCIAL_PLATFORM.md`](FINANCIAL_PLATFORM.md).

No product feature may skip ahead of accounting correctness on that list.
