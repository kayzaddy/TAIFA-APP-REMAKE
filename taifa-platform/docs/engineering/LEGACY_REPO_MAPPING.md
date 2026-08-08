# Legacy repository mapping

Maps **current workspace layout** (`TAIFA APP REMAKE`) to canonical **`taifa-platform/`** during migration.

---

## Top-level

| Legacy path | Canonical `taifa-platform` |
| --- | --- |
| `docs/` | `docs/` (+ symlinks/indexes under `taifa-platform/docs/`) |
| `apps/backend/` | `services/` (decompose over time) + `products/*/backend` |
| `apps/mobile/` | `products/super-app/mobile` (future) + `sdk/flutter` |
| `infra/` | `infrastructure/terraform/` |
| `packages/` | `packages/` |
| `.github/` | `.github/` (merge workflows) |
| `taifa_kernel/`, `taifa_platform/` (under backend) | `platforms/taifa-core/` + `packages/core/` |

---

## Documentation hubs

| Legacy | Canonical platform folder |
| --- | --- |
| `docs/platform/` | `platforms/taifa-core/` |
| `docs/payments/` | `platforms/tnpi/` |
| `docs/mobility/` | `platforms/tnmp/` |
| `docs/government/` | `platforms/gdsp/` |
| `docs/integration/` | `platforms/tip/` |
| `docs/taifa-merchant/` | `products/merchant/` (architecture); TPOS → `products/merchant/docs/` |
| `docs/tpos/` | `docs/standards/tpos/` (index) |

---

## Migration rules

1. **No big-bang move** — ARB approves phase moves.  
2. **Docs remain readable** — README indexes point to authoritative path.  
3. **CI path filters** — update when paths move.

---

## Target state (3–5 years)

Single root `taifa-platform/` with optional git submodule mirror for partners—default **one monorepo**.

---

## Cross-references

[REPOSITORY_TREE.md](REPOSITORY_TREE.md)
