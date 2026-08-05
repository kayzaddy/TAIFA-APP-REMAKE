# Compliance Guide

## Bank of Tanzania (daily)

`GET /api/v1/enterprise/reports/bot-daily`  
Includes transaction stats, ledger recon status, settlements, chargebacks.

## Tax authorities (monthly)

`generate_tax_monthly(year, month)` → P&L + balance sheet payload.

## Auditors

`GET …/reports/auditor-pack` — trial balance, BS, P&L, failure counts.

## AML

`generate_aml_sar_stub(owner, reason)` creates a draft Suspicious Activity Report
shell for investigators (evidence attached externally).

## Controls

- Append-only ledger + domain events
- Maker-checker on large settlements/treasury
- Admin read-only for financial objects (Phase 1)
- Outbox for reliable downstream notification
