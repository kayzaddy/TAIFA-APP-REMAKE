# Platform Lifecycle Management

## Releases

- Semantic versioning for APIs and SDKs  
- LTS: document supported API major versions  
- Backward compatibility preferred; breaking changes require ADR + migration guide  
- Feature flags for risky rollouts  
- Release notes in PR / tag description  
- Rollback: previous container image + DB migrate-forward policy (avoid destructive down migrations on ledger)

## Deprecation

1. Mark deprecated in OpenAPI  
2. Announce in docs/changelog  
3. Minimum 90-day sunset  
4. Remove behind ADR  

## Migrations

Data migrations must be expandable and monitored; financial schema changes need ARB + Security.
