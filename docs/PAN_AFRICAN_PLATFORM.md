# Pan-African Digital Infrastructure

Taifa as continental platform: **one shared core**, many national configurations.

## Principle

Adding a country means configuration + adapters + localization — **not** rebuilding Payments, Identity, Mobility, AI OS, or the Ecosystem.

## Launch markets

| Code | Country | Currency | Status |
| --- | --- | --- | --- |
| TZ | Tanzania | TZS | active |
| KE | Kenya | KES | pilot |
| UG | Uganda | UGX | pilot |
| RW | Rwanda | RWF | planned |
| BI | Burundi | BIF | planned |
| ZM | Zambia | ZMW | planned |
| MW | Malawi | MWK | planned |
| CD | DR Congo | CDF | planned |

Plus USD/EUR for settlement and regional merchant flows.

## Control plane

`/api/v1/continental/`

| Surface | Purpose |
| --- | --- |
| `blueprint` | Continental catalog |
| `countries` | National tenants |
| `ops-center` | Global operations view |
| `fx/quote` | FX rates + conversion |
| `corridors` / `cross-border/quote` | Cross-border intents (Payments executes money) |
| `compliance/evaluate` | Configurable AML/KYC/tax rules |
| `identity/{cc}/lookup` | Federated national ID adapters |
| `i18n/*` | Language packs (en, sw, fr, ar RTL, pt) |
| `partners` | Partner network + sandbox keys |

## Shared vs local

| Shared (central) | Local (per country) |
| --- | --- |
| Ledger / Payments engine | Payment rails (M-Pesa, MoMo, …) |
| Device Identity | NIDA / Huduma / NIN adapters |
| AI OS gateway | Locale-aware prompts & models |
| Ecosystem domains | Feature flags, branding, tax rules |
| Workflow / RBAC | Regulator reporting profiles |
| Observability probes | Data residency region |

## Seed

```bash
cd apps/backend
.\.venv\Scripts\python.exe manage.py seed_continental
```

## Docs

- [`CONTINENTAL_ARCHITECTURE.md`](CONTINENTAL_ARCHITECTURE.md)
- [`CROSS_BORDER_PAYMENTS.md`](CROSS_BORDER_PAYMENTS.md)
- [`CONTINENTAL_COMPLIANCE.md`](CONTINENTAL_COMPLIANCE.md)
- [`CONTINENTAL_DEPLOYMENT.md`](CONTINENTAL_DEPLOYMENT.md)
