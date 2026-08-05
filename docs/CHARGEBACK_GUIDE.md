# Chargeback Guide

Full dispute lifecycle with ledger entries at money-moving stages.

## Stages

opened → evidence_requested → evidence_submitted → representment → won | lost  
lost → reversed (status event; compensating journals via platform as needed)

## Accounting

| Stage | Journal |
|-------|---------|
| opened | DR merchant_payable / CR chargeback_reserve |
| won | DR chargeback_reserve / CR merchant_payable |
| lost | DR chargeback_reserve / CR provider_settlement |

## APIs

- Open: `POST /api/v1/enterprise/chargebacks`
- Transition: `POST /api/v1/enterprise/chargebacks/{id}/transition`

Every transition appends `ChargebackEvent` and emits domain + outbox events.
