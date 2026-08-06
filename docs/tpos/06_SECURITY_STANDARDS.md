# 06 — Security Standards

---

## Executive summary

Every product includes **threat model**, **security review**, RBAC, audit, encryption, privacy, compliance, risk assessment—before pilot.

---

## Required artifacts (`14_SECURITY_MODEL.md`)

| Artifact | Content |
| --- | --- |
| Threat model | STRIDE or similar; data flow diagram |
| RBAC/ABAC | Roles mapped to Identity claims |
| Audit | Events to Core Audit platform |
| Encryption | TLS, at-rest KMS for product SoR |
| Privacy | DPIA-lite for PII; retention |
| Compliance | BoT, TCRA, sector rules as applicable |
| Risk assessment | Link `23_RISK_REGISTER.md` |

---

## Security review gates

| Gate | When | Board |
| --- | --- | --- |
| Design review | Technical design complete | Security Board |
| Pre-pilot | Pen test or automated scan | Security Board |
| Annual | Production products | Security Board |

---

## Product rules

- No PAN, no national ID in logs  
- MFA for high-risk actions (refunds, payouts view, gov approvals)  
- Dependency scanning in CI  
- SAST on PRs for product services

---

## Cross-references

[10_PRODUCT_GOVERNANCE.md](10_PRODUCT_GOVERNANCE.md) · [14_CHECKLISTS.md](14_CHECKLISTS.md)
