# Merchant Guide

Merchants acquire payments through Taifa without a parallel ledger.

**Retail / MOS operations** (catalog, inventory, POS, orders): see [`COMMERCE_MERCHANT_GUIDE.md`](COMMERCE_MERCHANT_GUIDE.md) and [`COMMERCE_ARCHITECTURE.md`](COMMERCE_ARCHITECTURE.md).

## Onboarding

1. `POST /api/v1/enterprise/merchants/register` with `code`, `legal_name`, optional `sector`, `fee_bps`.
2. Optional workflow `merchant_onboarding` (KYC → risk → activate) via workflow engine.
3. Configure API keys / webhook endpoints (models ready; rotate secrets via ops runbook).

## Accepting payments

`POST /api/v1/enterprise/merchants/{id}/capture` with device auth + `Idempotency-Key`.

Accounting: customer wallet debited; `merchant_payable` credited; fee/tax/commission posted via rule engine.

## Settlements & statements

See [`SETTLEMENT_GUIDE.md`](SETTLEMENT_GUIDE.md). Statements: `MerchantStatement` projection after period close.

## Chargebacks / refunds

Chargebacks: [`CHARGEBACK_GUIDE.md`](CHARGEBACK_GUIDE.md). Customer refunds remain on the Payment Orchestrator refund path.
