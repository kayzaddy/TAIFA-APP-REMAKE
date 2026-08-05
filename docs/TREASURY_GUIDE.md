# Treasury Guide

Treasury manages float across bank accounts without bypassing the ledger.

## Accounts

`TreasuryBankAccount` maps to journal `external_bank:{ledger_bank_code}` or
`treasury` house account.

Kinds: operating, settlement, reserve, float, provider.

## Transfers

`POST /api/v1/enterprise/treasury/transfers`  
Large amounts require maker-checker (`approval_threshold_minor`).

Journal: DR destination / CR source (`post_treasury_transfer`).

## Liquidity

`GET /api/v1/enterprise/dashboards/liquidity` refreshes a `LiquiditySnapshot`
(treasury, provider settlement, merchant payable, reserves).

## Forecasting

Use successive liquidity snapshots + settlement schedules for cash positioning.
Multi-bank support is first-class via multiple `TreasuryBankAccount` rows.
