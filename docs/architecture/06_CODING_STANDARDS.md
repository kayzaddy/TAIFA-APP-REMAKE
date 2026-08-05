# 06 — Coding Standards

**Purpose:** Enforce module boundaries and quality in Taifa backend, mobile, and shared packages.  
**Scope:** All application code in the monorepo and extracted services.  
**Principles:** Domain purity, testable ports, consistent naming, reviewable diffs.

---

## Folder structure (backend — target)

```
apps/backend/{app_name}/
  domain/
  application/
  ports/
  adapters/
    in/http/
    in/events/
    out/{partner}/
  migrations/
  tests/
```

**Phase-1:** Legacy Django apps may colocate views/models; new code follows layers; strangle via ADR.

**Mobile:**

```
apps/mobile/lib/features/{module}/
  domain/
  data/
  presentation/
```

---

## Module boundaries

- No `from commerce.models import TourBooking` inside `tourism` domain logic—use `BookingPort`.  
- Lint rule (goal): forbidden import matrix per [01_DOMAIN_GOVERNANCE.md](01_DOMAIN_GOVERNANCE.md).

---

## Dependency injection

- Inject ports into use case handlers (constructor or framework DI).  
- Tests use fakes/mocks at port boundary—not patch ORM globally.

---

## Testing requirements

| Level | Minimum |
| --- | --- |
| Unit | Domain invariants, pure functions |
| Integration | Adapters + DB (testcontainers or dedicated DB) |
| Contract | Pact or OpenAPI-driven between domains |
| E2E | Critical paths per module (Identity login, Pay, Tourism checkout) |

Coverage: no numeric mandate; **critical aggregates must have invariant tests**.

---

## Logging

- Structured JSON logs: `level`, `message`, `correlation_id`, `domain`, `trip_id`/`payment_id` as applicable.  
- No secrets, PAN, full national ID, or health diagnoses in logs.

---

## Error handling

- Domain exceptions → mapped to HTTP problem+json in adapter.  
- Never swallow exceptions on money paths; always log with correlation id.

---

## Naming conventions

| Layer | Style |
| --- | --- |
| Python | PEP 8, `snake_case`, type hints on public APIs |
| Dart | `lowerCamelCase` members, `UpperCamelCase` types |
| Events | [02_EVENT_CATALOG.md](02_EVENT_CATALOG.md) |
| DB | [04_DATABASE_STANDARDS.md](04_DATABASE_STANDARDS.md) |

---

## Code review checklist

- [ ] Primary domain assigned  
- [ ] No cross-domain ORM writes  
- [ ] Idempotency on side-effect POSTs  
- [ ] OpenAPI updated if public API  
- [ ] Events documented if new publisher  
- [ ] Tests for behavior change  
- [ ] Security: authz on new endpoints  

---

## Architecture review checklist (ARB)

- [ ] Context map updated  
- [ ] ADR if boundary exception  
- [ ] Saga/compensation described for multi-domain flows  
- [ ] NFR impact (latency, scale, DR)  
- [ ] Compliance (PII, PCI) flagged  

---

## Cross-references

- [`../governance/ENGINEERING_STANDARDS.md`](../governance/ENGINEERING_STANDARDS.md)  
- [09_DEFINITION_OF_DONE.md](09_DEFINITION_OF_DONE.md)  
- [17_IMPLEMENTATION_GUIDE.md](../tourism/17_IMPLEMENTATION_GUIDE.md) (Tourism example)

---

## Future considerations

- Automated import-linter in CI  
- ArchUnit-style tests for Python (import graph)  
- Standard code generators from OpenAPI for Dart clients
