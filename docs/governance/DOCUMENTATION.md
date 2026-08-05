# Documentation Governance

Documentation is mandatory and version-controlled in `docs/`.

## Required doc types

| Type | When |
| --- | --- |
| Architecture | New/changed bounded context |
| ADR | Material decision |
| API | Public endpoints |
| Runbooks / playbooks | On-call actions |
| Security | Trust boundary change |
| Deployment / recovery | Ops path change |
| Engineering standards | Process change |

## Rules

- Docs land in the same PR as behavior when possible  
- Link; do not fork conflicting truths  
- Superseded docs marked and point to replacement  

Hub: [`../GOVERNANCE.md`](../GOVERNANCE.md).
