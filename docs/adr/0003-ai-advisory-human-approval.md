# ADR-0003: AI advisory with human approval for critical actions

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** ARB + AI Governance
- **Tags:** ai security

## Context

AI can improve ops but must not silently move money or bypass compliance.

## Decision

AI OS returns explainable decision envelopes. Capabilities tagged `requires_human_approval` create pending decisions and optional enterprise workflows. AI never mutates the ledger.

## Consequences

- Domains consume shared AI  
- Fraud/AML/credit remain human-gated  
- Stub adapters allowed; live models plug in via registry
