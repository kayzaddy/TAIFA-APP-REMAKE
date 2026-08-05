# Technical Debt Register

| ID | Item | Severity | Owner | Target | Status |
| --- | --- | --- | --- | --- | --- |
| TD-001 | GIS still Haversine; PostGIS planned | M | Mobility | Backlog | open |
| TD-002 | GraphQL not yet available; REST authoritative | L | Platform | Backlog | open |
| TD-003 | Consumer notifications inbox still seed-heavy | M | Platform | Backlog | open |
| TD-004 | Live government/identity adapters mostly stubs | H | Platform + Gov | Per-country | **partial** — HTTP adapters + stub ban; awaiting operator credentials (`TAIFA_*_PROVIDERS_JSON`) |
| TD-005 | AI adapters stub; production LLM/CV wiring | H | AI Platform | Near-term | **partial** — OpenAI-compatible adapter + stub ban; awaiting `TAIFA_AI_PROVIDER_JSON` |
| TD-013 | Simulated Airtel/Selcom/Card rails | H | Payments | Near-term | **partial** — live HTTP gateways; omitted in prod until credentials; `platform.E006` |
| TD-014 | Notifications/maps/object-storage incomplete | M | Platform | Near-term | **partial** — production adapters shipped; providers unconfigured in this env |
| TD-008 | Full SAST/secret/container scan suite in CI | H | DevSecOps | Near-term | partial — Dependabot + pip-audit (advisory) added; CodeQL/Trivy still open |
| TD-009 | Commerce client-forgeable paid state | C | Commerce | 2026-07-18 | **closed** — ledger `/pay` + PATCH reject |
| TD-010 | Outbox mark-only without delivery | C | Enterprise | 2026-07-18 | **closed** — webhook delivery + beat task |
| TD-011 | Prod defaults SQLite/eager Celery/LocMem | C | Platform | 2026-07-18 | **closed** — `platform.E002–E005` system checks |
| TD-012 | DRF default AllowAny | H | Security | 2026-07-18 | **closed** — default `IsDevice` |

Severity: H/M/L. New debt requires ID, owner, and acceptance in PR notes when introduced deliberately.
