# ADR-0004: Multi-country via configuration, not product forks

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** ARB (platform)
- **Tags:** architecture continental

## Context

Pan-African expansion must not multiply codebases per country.

## Decision

`continental` holds country profiles, FX, compliance JSON, payment rails, identity adapters, and residency. Adding a country is configuration + adapters.

## Consequences

- Shared core scales across markets  
- Regulatory logic lives in profiles, not `if country ==` product code
