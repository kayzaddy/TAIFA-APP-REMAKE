# Platform Governance Scorecard

Executive view of engineering discipline. Live API: `GET /api/v1/governance/scorecard`.

## Dimensions

| Dimension | Signals |
| --- | --- |
| Architecture compliance | ADRs present; no duplicate money/identity |
| Security compliance | Production gates; SECURITY.md controls |
| API compliance | OpenAPI CI; versioning |
| Documentation coverage | Domain docs + governance hub |
| Technical debt | Open debt items by severity |
| Platform health | `/readyz`, domain ops centers |
| SLO compliance | Targets in continental/AI/national ops |
| DORA-ish | Deploy frequency, CFR, MTTD, MTTR (track in ops tooling) |
| Availability | Probe success / error budgets |
| Cost | AI token estimates; infra budgets |

## Cadence

Weekly: ops health  
Monthly: ARB + scorecard review  
Quarterly: debt + security + DR exercise
