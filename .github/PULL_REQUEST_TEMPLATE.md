## Summary

<!-- What changed and why (1–3 bullets). -->

## Primary domain

<!-- Required. Example: `tourism.orchestration`, `finance.ledger`, `platform.events`, docs-only -->

**Primary bounded context:**

## Domain impact

- [ ] Platform foundation only
- [ ] Payments / Finance / Ledger
- [ ] Identity / device auth
- [ ] Commerce / Booking
- [ ] Tourism
- [ ] Mobility
- [ ] Docs / governance / ADR only

## Architecture Definition of Done

_Governed by [`docs/architecture/09_DEFINITION_OF_DONE.md`](docs/architecture/09_DEFINITION_OF_DONE.md). Check all that apply; justify N/A in one line._

### Architecture

- [ ] Architecture reviewed (ARB link or "module-only — delegate name")
- [ ] Domain assigned above
- [ ] ADR linked if boundary/API/event exception ([`docs/architecture/08_ADR_GUIDELINES.md`](docs/architecture/08_ADR_GUIDELINES.md))

### Contracts

- [ ] API/OpenAPI updated ([`docs/architecture/03_API_STANDARDS.md`](docs/architecture/03_API_STANDARDS.md))
- [ ] Events documented in [`docs/architecture/02_EVENT_CATALOG.md`](docs/architecture/02_EVENT_CATALOG.md) (or N/A: ___)
- [ ] Backward compatibility / deprecation headers considered

### Data

- [ ] Migrations only in owning domain schema ([`docs/architecture/04_DATABASE_STANDARDS.md`](docs/architecture/04_DATABASE_STANDARDS.md))
- [ ] No cross-domain ORM writes (verified in review)

### Security

- [ ] Security review per [`docs/architecture/05_SECURITY_STANDARDS.md`](docs/architecture/05_SECURITY_STANDARDS.md) triggers (or N/A: ___)
- [ ] AuthZ tests for new/changed endpoints

### Quality

- [ ] Tests added/updated ([`docs/architecture/06_CODING_STANDARDS.md`](docs/architecture/06_CODING_STANDARDS.md))
- [ ] Contract tests if port integration changed

### Operations

- [ ] Monitoring/metrics for new critical paths (or N/A: ___)
- [ ] Runbook note if on-call impact

### Documentation

- [ ] Module `00_INDEX` or domain doc updated if behavior/API/events changed

## Tourism-only gate (if applicable)

- [ ] Complies with [`docs/tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md`](docs/tourism/CANONICAL_ENTERPRISE_ARCHITECTURE.md) §12
- [ ] No new `tourism_*` tables unless ADR-0001 or new ADR

## Implementation gate reminder

**Business domain features** require **Taifa Core Phase 1** progress per [`docs/platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md`](docs/platform/14_PLATFORM_IMPLEMENTATION_GUIDE.md) and [`docs/platform/earb/07_IMPLEMENTATION_READINESS_REPORT.md`](docs/platform/earb/07_IMPLEMENTATION_READINESS_REPORT.md).

## Risk

<!-- Low / Medium / High — rollback plan if High. -->

## Evidence

<!-- Links to tests, screenshots, staging logs. -->
