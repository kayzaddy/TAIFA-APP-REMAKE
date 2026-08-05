# ADR-0002: REST `/api/v1` + OpenAPI as public contract

- **Status:** accepted
- **Date:** 2026-07-18
- **Deciders:** ARB (platform)
- **Tags:** api

## Context

Partners and mobile clients need a stable contract. Multiple API styles risk inconsistency.

## Decision

Public HTTP APIs use REST under `/api/v1/` with OpenAPI (drf-spectacular). CI fails on schema warnings. GraphQL/gRPC may be added later without replacing REST authz rules.

## Consequences

- SDK generation and partner docs stay coherent  
- Breaking changes require major version + ADR
