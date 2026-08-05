# Taifa Platform

**Bounded context:** `platform.*` services implemented in Django/DRF

Hosts Taifa Core capabilities: identity, API gateway middleware, events, notifications, media, configuration, feature flags, audit. Consumes `taifa_kernel` only for shared types.

## Sprint 0

Package root + README per service (added in Sprints 1–5). **Do not implement Identity, Tourism, or Payments here in S0.**

## Layout (target)

```
taifa_platform/
├── identity/           # Sprint 1+ (design only until GO)
├── gateway/            # Correlation, versioning middleware
├── events/             # Outbox, publisher
├── notifications/
├── media/
├── configuration/
├── feature_flags/
└── audit/
```

## Integration

Register Django apps in `config/settings.py` only when a service reaches implementation milestone (post–Sprint 0 full GO).

## Law

- [docs/platform/00_PLATFORM_OVERVIEW.md](../../docs/platform/00_PLATFORM_OVERVIEW.md)
- [docs/architecture/00_ARCHITECTURE_CONSTITUTION.md](../../docs/architecture/00_ARCHITECTURE_CONSTITUTION.md)
