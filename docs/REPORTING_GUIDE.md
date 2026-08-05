# Reporting Guide

**Rule:** dashboards never query hot ledger joins for page loads.

## Projections (read models)

| Dashboard | Endpoint / model |
|-----------|------------------|
| Merchant | `dashboards/merchant?code=` |
| Finance | `dashboards/finance` |
| Executive | `dashboards/executive` |
| Liquidity / Treasury | `dashboards/liquidity` |

Refreshed after money-moving platform operations.

## Formal financial statements

`GET /api/v1/enterprise/reports/{trial-balance|balance-sheet|pnl|cash-flow}`

Generated from the ledger on demand; store payloads for audit packs.

## Regulatory

See [`COMPLIANCE_GUIDE.md`](COMPLIANCE_GUIDE.md).
