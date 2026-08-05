# Quality Engineering

## Minimum bars

| Layer | Expectation |
| --- | --- |
| Unit | Domain logic & money math covered |
| Integration | API + DB for critical flows |
| Contract | OpenAPI / Spectacular CI |
| Performance | Budgets in [`../PERFORMANCE.md`](../PERFORMANCE.md) |
| Security | Authz tests; production gates |
| Chaos / DR | Exercises per [`../DISASTER_RECOVERY.md`](../DISASTER_RECOVERY.md) |
| Accessibility | Mobile UI follows design system contrast/tap targets |
| Load | Staging load for payments & dispatch before scale events |
| Reliability | SLOs monitored; error budgets reviewed |

## Quality gates

PRs that break `manage.py test` / `flutter analyze` / OpenAPI must not merge. Money path regressions are release blockers.
