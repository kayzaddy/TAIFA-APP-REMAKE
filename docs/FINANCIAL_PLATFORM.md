# TAIFA Financial Platform Architecture (Phase 3)

**Status:** Enterprise platform modules live on top of the Phase 1 payment engine
and Phase 2 operations stack.  
**Invariant:** The Payment Engine / ledger posting path is never bypassed.

## Attachment rule

```
Enterprise API / Merchant Portal / Partner API
        ↓
Platform Orchestrator (enterprise.orchestrator)
        ↓
payments.journal  →  payments.ledger  (only money path)
        ↓
DomainEvent + EventOutbox (event bus)
        ↓
Projections / Regulatory reports / Merchant webhooks
```

No module may:

- write `Posting` rows directly
- mutate balances
- edit financial rows in Admin
- call gateway settle outside the payment orchestrator for wallet rails

## Modules delivered

| # | Module | Location |
|---|--------|----------|
| 1 | Merchant Settlement Engine | `enterprise.orchestrator` + `MerchantSettlement` |
| 2 | Treasury Management | `TreasuryBankAccount`, `TreasuryTransfer`, liquidity snapshots |
| 3 | Chargeback Engine | `ChargebackCase` lifecycle + journal reserve/win/lose |
| 4 | Reporting Projections | `*DashboardProjection`, `projections.py` |
| 5 | Financial Reporting | `financial_reports.py` (TB, BS, P&L, cash flow) |
| 6 | Regulatory Reporting | `regulatory.py` (BoT daily, tax monthly, AML SAR, auditor pack) |
| 7 | Merchant Platform | Merchant model, API keys/webhooks models, capture/settlement APIs |
| 8 | Event Platform | `event_bus.py` + `EventOutbox` |
| 9 | Workflow Engine | `workflow.py` + `WorkflowDefinition` |
| 10 | Approval Engine | `approval.py` maker-checker |
| 11 | Rule Engine | `rules.py` + `BusinessRule` |
| 12 | Enterprise Security | `rbac.py` RBAC/ABAC principals & roles |
| 13 | API Platform | `/api/v1/enterprise/*` versioned |
| 14 | Data Platform | projections + regulatory payloads (OLAP-style read models) |
| 15 | Performance | async outbox, projection refresh, indexes (scale path documented) |

## Accounting recipes (journal)

| Event | Journal |
|-------|---------|
| Merchant capture | DR user_wallet / CR merchant_payable (+ fee/tax/commission) |
| Merchant settlement | DR merchant_payable / CR external_bank |
| Chargeback open | DR merchant_payable / CR chargeback_reserve |
| Chargeback won | DR chargeback_reserve / CR merchant_payable |
| Chargeback lost | DR chargeback_reserve / CR provider_settlement |
| Treasury transfer | DR dest bank / CR source bank |

## API map (v1)

Base: `/api/v1/enterprise/`

- `POST merchants/register`
- `POST merchants/{id}/capture` (device auth)
- `POST merchants/{id}/settlements`
- `POST settlements/{id}/execute|cancel`
- `POST approvals/{id}/decide`
- `POST chargebacks` + `…/transition`
- `GET|POST treasury/accounts`, `POST treasury/transfers`
- `GET reports/{trial-balance|balance-sheet|pnl|cash-flow|bot-daily|auditor-pack}`
- `GET dashboards/{finance|executive|liquidity|merchant}`
- `POST events/outbox/drain`

## Guides

- [`MERCHANT_GUIDE.md`](MERCHANT_GUIDE.md)
- [`SETTLEMENT_GUIDE.md`](SETTLEMENT_GUIDE.md)
- [`TREASURY_GUIDE.md`](TREASURY_GUIDE.md)
- [`CHARGEBACK_GUIDE.md`](CHARGEBACK_GUIDE.md)
- [`REPORTING_GUIDE.md`](REPORTING_GUIDE.md)
- [`COMPLIANCE_GUIDE.md`](COMPLIANCE_GUIDE.md)

## Certification

See [`FINANCIAL_PLATFORM_READINESS.md`](FINANCIAL_PLATFORM_READINESS.md).
