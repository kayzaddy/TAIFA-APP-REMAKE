# Taifa Kernel

**Bounded context:** `platform.kernel` (shared primitives only)

Pure Python types and value objects used by **all** Taifa modules. No Django models, no HTTP, no domain-specific imports.

## Sprint 0

Package root only. Specifications:

- Event envelope — [schemas/event-envelope-v1.json](../../docs/platform/schemas/event-envelope-v1.json)
- Money value object — documented in platform backlog PB-001 (spec before code)

## Layout (target)

```
taifa_kernel/
├── events/          # EventEnvelope, EventMetadata
├── money/           # Money, Currency
└── ids/             # Typed IDs (optional)
```

## Rules

- No imports from `tourism`, `payments`, `commerce`, or other domain apps.
- Covered by architecture [07_CODING_STANDARDS](../docs/architecture/07_CODING_STANDARDS.md).
