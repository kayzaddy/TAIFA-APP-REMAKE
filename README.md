# TAIFA — The Digital Operating System of Tanzania

> One App. One Nation. Everything Connected.

TAIFA is a national super-app ecosystem — wallet & payments, mobility, food,
government services, tourism, housing, health, education, jobs and an AI
assistant — engineered to scale from **100 users to 10M+** without an
architectural rewrite.

This repository is a **monorepo**. The canonical enterprise layout is **[`taifa-platform/`](taifa-platform/README.md)** (PDL-026). Legacy paths (`apps/`, `infra/`, root `docs/`) migrate incrementally—see [taifa-platform/docs/engineering/LEGACY_REPO_MAPPING.md](taifa-platform/docs/engineering/LEGACY_REPO_MAPPING.md).

Platform domains are architecturally complete;
ongoing work follows **enterprise governance** — [`docs/GOVERNANCE.md`](docs/GOVERNANCE.md) · **[TPOS (Product Engineering)](docs/tpos/00_TPOS_CHARTER.md)** · **[TEOS (Engineering)](docs/teos/00_TEOS_CHARTER.md)** · **[Product portfolio & delivery roadmap](docs/TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md)** · **[Taifa Core Phase 1](docs/platform/00_PLATFORM_OVERVIEW.md)** · [Architecture Constitution](docs/architecture/README.md).

---

## Repository layout

```
TAIFA APP REMAKE/
├─ taifa-platform/         # Enterprise monorepo layout (SSOT target) — PDL-026
├─ apps/
│  ├─ mobile/              # Flutter super-app
│  └─ backend/             # Django API + domain apps + taifa_kernel / taifa_platform
├─ packages/               # Shared SDKs (Python, Flutter, JS)
├─ infra/                  # Terraform modules, envs (dev/test/staging/prod)
├─ .github/workflows/      # CI, IaC validate
├─ docs/
│  ├─ architecture/        # Platform constitution & ADRs
│  ├─ platform/            # Taifa Core 00–17, Sprint 0 engineering plan
│  └─ tourism/             # Domain packs (architecture)
└─ README.md
```

**Sprint 0 contract:** [docs/platform/SPRINT_0_ENGINEERING_PLAN.md](docs/platform/SPRINT_0_ENGINEERING_PLAN.md) · [REPOSITORY_STRUCTURE.md](docs/platform/REPOSITORY_STRUCTURE.md)

Planned: `apps/admin`, `scripts/` (repo-wide automation).

---

## Prerequisites

| Tool    | Version used |
|---------|--------------|
| Flutter | stable (Dart 3.12+) |
| Android Studio / Xcode | for device builds |

---

## Run the mobile app

```bash
cd apps/mobile
flutter pub get
flutter run           # pick a device, or:
flutter run -d chrome # web preview
```

### Quality gates

```bash
cd apps/mobile
flutter analyze       # static analysis (0 issues expected)
flutter test          # widget/unit tests
```

---

## Design source of truth

The canonical visual specification is `TAIFA_Mockups.html` (investor-grade
deck + ~19 native screen mockups). Every token in `lib/app/theme/` is extracted
directly from its **P4 — Brand DNA / Design System** section. See
[`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).

## Where things are going

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full 20-phase plan and
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the scaling architecture.
