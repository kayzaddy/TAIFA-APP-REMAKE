# Architecture guidelines

---

## Layering

| Layer | May depend on | Must not |
| --- | --- | --- |
| `products/*` | platforms, services, packages, sdk | Duplicate TNPI/Identity/TIP |
| `services/*` | packages, platforms contracts | Import other products |
| `packages/*` | stdlib only | Import services/products |
| `platforms/*` | docs, apis | Contain product UI |

---

## Service boundaries

Map runtime services to approved platforms:

| Service folder | Platform |
| --- | --- |
| `services/identity` | Taifa Core Identity |
| `services/payments` | TNPI (orchestration, etc.) |
| `services/integration` | TIP |
| `services/audit` | Core Audit |

---

## API contracts

- Authoritative OpenAPI in `apis/openapi/`  
- Published through TIP—no shadow public endpoints  
- Breaking changes: 12-month deprecation minimum

---

## Events

- Schemas in `apis/events/`  
- CloudEvents 1.0 envelope  
- Register in TIP catalog

---

## ADRs

New ADRs: `docs/decisions/ADR-{nnnn}-{slug}.md` + entry in platform PDL when cross-cutting.

---

## Cross-references

[../../ARCHITECTURE.md](../../ARCHITECTURE.md)
