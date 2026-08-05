# Cross-Border Payments

## Scope

Wallet-to-wallet, merchant, logistics/freight corridors across East & Central Africa with FX conversion and compliance screening.

## Quote flow

```http
POST /api/v1/continental/cross-border/quote
{
  "corridor_code": "tz-ke-wallet",
  "amount_minor": 10000000
}
```

Response includes converted amount, `fx_rate_e8`, fee, and compliance flags. Settlement currency for many corridors is USD.

## FX

- Rates stored as `FxRate.rate_e8` (quote per 1 base × 1e8)
- USD bridge for pairs without a direct quote
- Payments ledger optionally applies continental rates when posting multi-currency books

## Hard rule

Continental quotes are **intents**. Actual movement uses Payments APIs and the double-entry ledger. Reconciliation remains enterprise/payments responsibility.
