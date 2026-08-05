# Golden Django service template

Use this checklist when adding a **new** bounded context. Prefer extending an existing app when the capability fits.

## Checklist

1. App name short, no collision with stdlib (`platform` → avoid)  
2. `AppsConfig` with unique `label`  
3. Mount under `/api/v1/<name>/`  
4. Spectacular tags added  
5. `IsDevice` (+ RBAC) on endpoints  
6. Consume Payments/Identity — do not fork  
7. `/health` contribution via existing probes if critical  
8. Tests + docs + ADR if material  
9. Ownership row in `docs/governance/OWNERSHIP.md`  
10. OpenAPI green in CI  

## Skeleton layout

```text
apps/backend/<service>/
  apps.py
  models.py
  services.py
  views.py
  urls.py
  tests.py
  admin.py
  migrations/
```

## Anti-patterns

- New wallet or password auth  
- Hardcoded country regulation  
- AI that posts ledger entries  
- Undocumented public endpoints  
