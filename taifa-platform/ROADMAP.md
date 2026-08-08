# Roadmap — taifa-platform repository

Aligns with [Product Portfolio & Delivery Roadmap](../docs/TAIFA_PRODUCT_PORTFOLIO_AND_DELIVERY_ROADMAP.md) and [TPOS rollout](../docs/tpos/20_ROADMAP.md).

---

## 2026 Q4 — Monorepo foundation

- [x] Enterprise architecture packs  
- [ ] `taifa-platform/` tree + governance docs (this initiative)  
- [ ] CODEOWNERS + branch protection templates  
- [ ] CI quality gates (lint, IaC validate)  
- [ ] Legacy mapping complete ([LEGACY_REPO_MAPPING.md](docs/engineering/LEGACY_REPO_MAPPING.md))

## 2027 H1 — Platform implementation paths

- Populate `services/` per Core + TIP + TNPI boundaries  
- `sdk/` publish pipeline (Flutter, Node first)  
- `design-system/tokens` v1  

## 2027 H2 — Product engineering at scale

- `products/merchant/` TPOS doc pack + apps linkage  
- `testing/e2e` national sandbox harness  
- Partner examples under `examples/`

## 2028+ — National scale

- Multi-account infra fully under `infrastructure/`  
- Regional expansion folders under `products/future/`  
- Optional repo split **only** via ARB decision (default: stay monorepo)

---

## Versioning

Repository releases tagged `platform-repo-v{major}.{minor}.{patch}` for governance milestones—not product semver.
