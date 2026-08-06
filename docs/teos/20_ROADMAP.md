# 20 — TEOS roadmap

**Owner:** Engineering Council · **Horizon:** 12 months from approval

---

## Vision

Every Taifa squad operates on a single engineering OS: predictable delivery, safe releases, measurable reliability, and zero duplicate platform builds.

---

## Q1 — Foundation

| Initiative | Outcome |
| --- | --- |
| TEOS v1 published | This document set mandatory |
| PR + CI baseline | All active repos: lint, test, gitleaks |
| Gate templates | EGR/PAR used on Merchant pilot |
| ADR hygiene | ARB weekly; index in `docs/adr/` |
| Identity ADR | Close Merchant EGR B1 |

---

## Q2 — Quality & security

| Initiative | Outcome |
| --- | --- |
| Contract tests | OpenAPI diff in CI for BFFs |
| G-SEC automation | SAST + dependency gates blocking |
| Coverage reporting | Delta coverage on PRs |
| Threat models | Auth + payment touchpoints catalogued |
| Staging E2E | Critical journeys automated |

---

## Q3 — SRE & release

| Initiative | Outcome |
| --- | --- |
| SLOs live | Core BFFs + TNPI edge |
| Release train | Bi-weekly with Release Board |
| Runbooks | 100% paging alerts linked |
| Game day | One DR exercise |
| DORA dashboard | Engineering Council monthly |

---

## Q4 — Scale

| Initiative | Outcome |
| --- | --- |
| Technology radar | Published Adopt/Trial/Hold |
| Platform Council | Shared IaC modules versioned |
| Pen test cycle | Annual + pilot gates |
| TEOS v1.1 | Feedback from all product lines |

---

## Technology radar (initial)

| Adopt | Trial | Hold |
| --- | --- | --- |
| Flutter, Riverpod, GoRouter | Pact contract testing | Custom payment SDKs in products |
| Django/DRF BFF | Cross-region active-active | Long-lived develop branches |
| Terraform, GitHub Actions | Feature flag SaaS | Secrets in env files |
| OpenAPI 3, OIDC | | Duplicate Identity |

Refresh quarterly.

---

## Success metrics

See [13_METRICS_AND_KPIS.md](13_METRICS_AND_KPIS.md): deployment frequency, lead time, CFR, MTTR, sprint predictability.

---

## Cross-references

[00_TEOS_CHARTER.md](00_TEOS_CHARTER.md) · [14_GOVERNANCE.md](14_GOVERNANCE.md)
