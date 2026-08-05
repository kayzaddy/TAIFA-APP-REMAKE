# Taifa Enterprise Repository Structure

**Status:** Target layout for Sprint 0 — **preserve existing domain apps**; grow platform paths alongside them.  
**Authority:** [SPRINT_0_ENGINEERING_PLAN.md](SPRINT_0_ENGINEERING_PLAN.md) · [14_PLATFORM_IMPLEMENTATION_GUIDE.md](14_PLATFORM_IMPLEMENTATION_GUIDE.md)

---

## Design principles

1. **Separation of concerns** — Applications, platform services, shared packages, infrastructure, and documentation are distinct top-level areas.  
2. **No big-bang moves in S0** — Existing `apps/backend/tourism`, `payments`, etc. stay in place; new Core code uses `taifa_*` packages.  
3. **Module-agnostic** — Nothing under `taifa_kernel/`, `taifa_platform/`, or `infra/` may import Tourism/Pay-specific logic.  
4. **Monorepo** — One repo; path-based CI and CODEOWNERS enforce boundaries.

---

## Top-level map

```
/
├── apps/                      # APPLICATIONS — deployable runtimes
├── packages/                  # SHARED PACKAGES — SDKs, contracts
├── infra/                     # INFRASTRUCTURE — Terraform, policies
├── docs/                      # DOCUMENTATION — law, domain packs, runbooks
├── scripts/                   # SCRIPTS — repo-wide automation (target)
├── templates/                 # Scaffolding for new modules
├── .github/                   # GitHub standards (workflows, CODEOWNERS)
└── README.md
```

---

## Applications (`apps/`)

| Path | Role | Sprint 0 |
| --- | --- | --- |
| `apps/backend/` | Django API monolith (DRF, Channels) | Active — add platform packages below |
| `apps/mobile/` | Flutter client (super-app shell) | Active — `lib/platform/` for Core SDK |
| `apps/admin/` | Future ops console | Not created in S0 |
| `apps/merchant/` | Future merchant portal | Not created in S0 |

### Backend layout (current + target)

```
apps/backend/
├── config/                 # Django settings, URLs, ASGI
├── taifa_kernel/           # PLATFORM — pure shared types (EventEnvelope, Money)
├── taifa_platform/         # PLATFORM — identity, events, audit, flags (stubs in S0)
├── governance/             # Cross-cutting Django apps (existing)
├── ecosystem/              # Module catalog (existing)
├── tourism/                # DOMAIN — frozen for features in Phase 1
├── payments/               # DOMAIN — frozen
├── commerce/               # DOMAIN
├── …                       # Other domain apps (mobility, ai_os, …)
├── deploy/                 # App-specific deploy helpers (migrate to infra/ over time)
├── scripts/                # Backend-only scripts (candidate move → /scripts)
├── Dockerfile
├── requirements.txt
└── manage.py
```

**Rule:** New platform capabilities → `taifa_platform/<service>/`. New vertical features → existing or new Django app under `apps/backend/<domain>/` only after domain gate lifts.

### Mobile layout (target emphasis)

```
apps/mobile/lib/
├── app/                    # Router, theme, shell
├── platform/               # Core client SDK (auth headers, correlation) — expand post-S2
├── shared/                 # Design system
└── features/               # Vertical UI modules (tourism, wallet, …)
```

---

## Platform services (`taifa_platform/`)

Logical services (folders appear over Sprints 1–5):

| Folder | Platform doc |
| --- | --- |
| `identity/` | [01_IDENTITY_PLATFORM.md](01_IDENTITY_PLATFORM.md) — **no impl in S0** |
| `gateway/` | [02_API_GATEWAY_PLATFORM.md](02_API_GATEWAY_PLATFORM.md) |
| `events/` | [03_EVENT_PLATFORM.md](03_EVENT_PLATFORM.md) |
| `notifications/` | [04_NOTIFICATION_PLATFORM.md](04_NOTIFICATION_PLATFORM.md) |
| `media/` | [05_MEDIA_PLATFORM.md](05_MEDIA_PLATFORM.md) |
| `configuration/` | [07_CONFIGURATION_PLATFORM.md](07_CONFIGURATION_PLATFORM.md) |
| `feature_flags/` | [08_FEATURE_FLAGS_PLATFORM.md](08_FEATURE_FLAGS_PLATFORM.md) |
| `audit/` | [09_AUDIT_PLATFORM.md](09_AUDIT_PLATFORM.md) |

---

## Shared packages (`packages/`)

| Path | Purpose |
| --- | --- |
| `packages/sdk-python/` | HTTP/event helpers for external integrators |
| `packages/sdk-flutter/` | Mobile shared types |
| `packages/sdk-javascript/` | Web/embed SDK |
| `packages/openapi/` | **Target** — aggregated OpenAPI specs (S2) |
| `packages/schemas/` | **Target** — JSON Schema (event envelope already in `docs/platform/schemas/`) |

Promote stable contracts from `docs/platform/schemas/` into `packages/schemas/` when CI codegen is ready.

---

## Infrastructure (`infra/`)

See [infra/README.md](../../infra/README.md).

```
infra/
├── modules/          # Reusable Terraform modules
├── envs/             # dev | test | staging | prod roots
└── global/           # Org-wide: state backend, OIDC
```

**Testing:** IaC validation only in S0 for module wiring; full applies follow AWS account provisioning.

---

## Documentation (`docs/`)

| Area | Contents |
| --- | --- |
| `docs/architecture/` | Constitution, events, API, DoD — **canonical law** |
| `docs/platform/` | Taifa Core `00–17`, Sprint 0 plan, runbooks |
| `docs/platform/earb/` | Enterprise architecture board archive |
| `docs/platform/evidence/` | Audits, account register, release notes |
| `docs/tourism/`, `docs/tap_pay/`, … | Domain packs (architecture; not Sprint 0 work) |
| `docs/governance/` | Security and program governance |

---

## Scripts (`scripts/`)

**Target** (create as jobs are automated):

| Script | Purpose |
| --- | --- |
| `scripts/bootstrap-dev.sh` | Local venv + migrate |
| `scripts/validate-openapi.sh` | CI helper |
| `scripts/terraform-plan-all.sh` | Plan all envs (read-only) |

Until migrated, use `apps/backend/scripts/`.

---

## Testing

| Location | Scope |
| --- | --- |
| `apps/backend/**/tests/` | Django unit/integration |
| `apps/mobile/test/` | Flutter tests |
| `infra/envs/test/` | AWS account for CI integration (not unit tests) |
| **Target** `tests/platform/` | Cross-cutting platform contract tests (S5, PB-015) |

---

## What not to do in Sprint 0

- Move or rename domain Django apps without an ADR.  
- Add Tourism checkout, Identity OIDC, or Payment provider code.  
- Collapse `docs/` into code comments — law stays in `docs/architecture` and `docs/platform`.

---

## Cross-references

- [SPRINT_0_ENGINEERING_PLAN.md](SPRINT_0_ENGINEERING_PLAN.md)  
- [13_INFRASTRUCTURE_PLATFORM.md](13_INFRASTRUCTURE_PLATFORM.md)
