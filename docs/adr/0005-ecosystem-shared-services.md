# ADR-0005: Ecosystem domains consume shared platform services

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** ARB (platform)
- **Tags:** architecture ecosystem

## Context

Taifa hosts many industries. Rebuilding auth/payments/notifications per industry causes drift.

## Decision

Ecosystem catalog declares domains and required shared services. Super App modules enable services per principal. New industries register in catalog and call shared APIs.

## Consequences

- Modular products, shared foundation  
- ARB rejects duplicate platform capabilities
