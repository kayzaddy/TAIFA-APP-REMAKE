# Release strategy

---

## Versioning

| Artifact | Scheme |
| --- | --- |
| Mobile apps | Semver + build number |
| Services | Semver container tags |
| APIs | URL/header per TIP |
| Repo governance | `platform-repo-v*` tags |

---

## Trains

| Train | Cadence |
| --- | --- |
| Platform | Bi-weekly staging, monthly prod (default) |
| Product | Per TPOS release plan |
| Hotfix | As needed |

---

## Pipeline stages

Build → test → scan → staging → E2E → approval → canary → prod

See [../../automation/cd/README.md](../../automation/cd/README.md).

---

## Rollback

- ECS: previous task definition  
- Feature flags: disable  
- DB: forward-only migrations; reversions via new migration

---

## Release Board

Sign-off required per [../governance/REPOSITORY_GOVERNANCE.md](../governance/REPOSITORY_GOVERNANCE.md).

---

## Cross-references

[../../docs/tpos/08_RELEASE_STANDARDS.md](../../../docs/tpos/08_RELEASE_STANDARDS.md)
