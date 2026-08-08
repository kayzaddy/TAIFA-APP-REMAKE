# Shared libraries

**Owner:** Design Systems + Platform Engineering  
**Purpose:** Cross-product UI, types, hooks, and utilities—no business-domain SoR.

| Subfolder | Use |
| --- | --- |
| `ui/`, `components/` | Presentational building blocks |
| `themes/`, `constants/` | TDS-aligned tokens |
| `models/`, `types/` | Shared DTOs (non-platform) |
| `security/`, `analytics/` | Client-side helpers only |

Platform logic stays in `platforms/` and `services/`.
