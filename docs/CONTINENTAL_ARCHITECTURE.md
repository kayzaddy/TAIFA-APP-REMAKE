# Continental Architecture

## Multi-tenant national model

Each `CountryProfile` is a national tenant with currency, languages, timezone, data region, branding, and feature flags. Products read the active country context; they never embed `if country == "TZ"` regulatory logic.

## Layers

```text
Super App / Partners / Governments
              │
     /api/v1/continental/   (config + FX + corridors + i18n)
              │
   ┌──────────┼──────────────┬─────────────┐
   ▼          ▼              ▼             ▼
Payments   Identity      Ecosystem      AI OS
(ledger)   (device)      (domains)      (infer)
   ▲          ▲
   │          └── IdentityFederationBinding adapters
   └── PaymentRailBinding + FxRate (optional ledger hook)
```

## Cross-border money

1. Quote corridor → `CrossBorderTransferIntent` (FX + fees + compliance flags)
2. Capture / transfer via **Taifa Payments** (`payment_ref`)
3. Treasury balancing uses enterprise treasury accounts per currency

The continental app never posts journal entries.

## Data sovereignty

`DataResidencyPolicy` per country: storage region, retention, cross-border processing default, encryption profile. Deployment maps `data_region` to Kubernetes clusters / cloud regions.

## Extending to a new country

1. Add `CountryProfile` (+ currencies already in `payments.money.Currency` if needed)
2. Seed compliance templates, payment rails, identity bindings
3. Publish FX rates
4. Open corridors
5. Localize language pack
6. Point adapters via `TAIFA_IDENTITY_ADAPTERS_JSON` / payment gateway registry

No core architecture change.
