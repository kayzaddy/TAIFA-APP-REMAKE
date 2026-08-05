# DevSecOps Governance

## Pipeline requirements (every deployable)

1. Static analysis / lint  
2. Dependency vulnerability scan  
3. Secret scan  
4. Container/image scan (when containerized)  
5. Unit tests  
6. Integration tests (critical paths)  
7. Contract tests (OpenAPI / money APIs)  
8. Performance smoke (as applicable)  
9. Security tests (authz regression)  
10. Infrastructure validation (compose/k8s manifests)  
11. Approval gates (prod: human for ledger/identity)  
12. Deploy  
13. Smoke (`/healthz`, `/readyz`)  
14. Rollback plan validated  

Current CI baseline: [`.github/workflows/ci.yml`](../../.github/workflows/ci.yml) — extend gates as scanners are added; do not remove payment production gates.

## Environments

dev → staging → prod. No hotfixes that skip staging for money paths without Change Advisory exception.
