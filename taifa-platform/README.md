# taifa-platform

**The official enterprise monorepository for the Taifa Digital Ecosystem.**

Single source of truth for platforms, products, shared libraries, infrastructure, SDKs, documentation, design system, automation, and engineering standards—designed to scale for **20+ years**.

---

## Status

| Phase | State |
| --- | --- |
| Enterprise architecture | ✅ Approved |
| Platforms (Core, TNPI, TNMP, GDSP, TIP) | ✅ Documented |
| Product Operating System (TPOS) | ✅ Mandatory |
| Engineering Operating System (TEOS) | ✅ Mandatory |
| Monorepo structure | ✅ This repository layout |
| Application implementation | Per product gates |

---

## Quick links

| Resource | Path |
| --- | --- |
| Architecture overview | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Repository tree | [docs/engineering/REPOSITORY_TREE.md](docs/engineering/REPOSITORY_TREE.md) |
| Engineering guidelines | [docs/engineering/ENGINEERING_GUIDELINES.md](docs/engineering/ENGINEERING_GUIDELINES.md) |
| Contribution | [CONTRIBUTING.md](CONTRIBUTING.md) |
| Security | [SECURITY.md](SECURITY.md) |
| Roadmap | [ROADMAP.md](ROADMAP.md) |
| Legacy repo mapping | [docs/engineering/LEGACY_REPO_MAPPING.md](docs/engineering/LEGACY_REPO_MAPPING.md) |

**Governance (enterprise docs):** [`../docs/GOVERNANCE.md`](../docs/GOVERNANCE.md) · [TPOS](../docs/tpos/00_TPOS_CHARTER.md) · [TEOS](../docs/teos/00_TEOS_CHARTER.md) · [Portfolio](../docs/TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md)

---

## Top-level layout

```
taifa-platform/
├── README.md
├── ARCHITECTURE.md
├── ROADMAP.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── CHANGELOG.md
├── LICENSE
├── docs/
├── platforms/
├── products/
├── shared/
├── sdk/
├── design-system/
├── apis/
├── packages/
├── services/
├── infrastructure/
├── automation/
├── testing/
├── scripts/
├── configs/
├── examples/
├── templates/
├── tools/
└── .github/
```

See [docs/engineering/REPOSITORY_TREE.md](docs/engineering/REPOSITORY_TREE.md) for full tree, ownership, and responsibilities.

---

## Golden rules

1. **Platforms** implement national capability; **products** consume platforms (TPOS).  
2. **No duplication** of Identity, TNPI, TIP, GDSP, TNMP in products.  
3. **Docs-as-code** — architecture and ADRs live under `docs/`.  
4. **Path ownership** — CODEOWNERS per area; ARB for cross-cutting changes.  
5. **No secrets in git** — use AWS Secrets Manager / CI OIDC.

---

## License

See [LICENSE](LICENSE). Proprietary — Taifa / authorized partners.
