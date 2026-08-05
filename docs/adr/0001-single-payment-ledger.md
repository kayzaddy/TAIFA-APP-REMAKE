# ADR-0001: Single payment ledger and identity device auth

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** ARB (platform)
- **Tags:** architecture security payments

## Context

Multiple products need money movement and authentication. Duplicating wallets or identity creates systemic risk.

## Decision

Taifa Payments double-entry ledger is the only money SoT. Device-bound bearer auth in payments is the API identity mechanism. Domains store `payment_ref` / principals — they never post competing ledgers.

## Consequences

- All industries integrate via Payments APIs  
- Compliance and audit concentrate on one money core  
- Product teams cannot “just add a balance table”

## Alternatives considered

Per-product wallets — rejected (reconciliation nightmare).
