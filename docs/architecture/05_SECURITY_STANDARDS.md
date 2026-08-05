# 05 — Security Standards

**Purpose:** Platform-wide security governance for Taifa services and data.  
**Scope:** All domains, infrastructure, mobile clients, and partner integrations.  
**Principles:** Zero trust, least privilege, encryption everywhere, auditable actions.

---

## Identity & access

| Standard | Application |
| --- | --- |
| **OAuth 2.0** | Authorization code + PKCE (mobile/public); client credentials (service/partner) |
| **OIDC** | ID tokens for profile claims; validate `iss`, `aud`, `exp` |
| **JWT** | Short-lived access tokens; refresh rotation; no sensitive claims in JWT without encryption |
| **RBAC** | Role definitions in Identity; enforced at API and admin UI |
| **ABAC** | Owner checks on citizen resources (`trip`, `wallet`, health record) |
| **Zero trust** | Verify every request; no flat VPC trust |

---

## Encryption

| Layer | Requirement |
| --- | --- |
| Transit | TLS 1.2+ everywhere; certificate pinning optional high-security mobile |
| At rest | RDS, S3, EBS encrypted with **AWS KMS** CMK |
| Application | Field-level encryption for national ID, passport refs (Government/Identity vault) |
| Secrets | **AWS Secrets Manager**; never in git |

---

## Audit logging

- Immutable **Audit** service for: authentication, authorization failures, money movement, data export, admin actions.  
- Include: `actor`, `action`, `resource`, `correlation_id`, `ip`, `outcome`.  
- Retention per regulation (financial ≥ 7 years metadata).

---

## Compliance alignment

| Framework | Taifa stance |
| --- | --- |
| **PCI DSS** | Card data only via certified Pay flows; no PAN in app DBs |
| **ISO 27001** | Control mapping in security governance handbook; annual review |
| National privacy | Consent, purpose limitation, data residency ADRs |

Detail: [`../governance/SECURITY_GOVERNANCE.md`](../governance/SECURITY_GOVERNANCE.md), [`../governance/PRIVACY_COMPLIANCE.md`](../governance/PRIVACY_COMPLIANCE.md).

---

## Security reviews & threat modeling

| Trigger | Required |
| --- | --- |
| New public API surface | Lightweight STRIDE |
| Money, Identity, Health, Children | Full threat model + Security Review sign-off |
| Partner webhook ingress | mTLS, HMAC, replay protection |
| AI tools with PII | AI Governance review |

---

## AWS security services

WAF, Shield, GuardDuty, Security Hub, KMS, IAM Access Analyzer, CloudTrail (organization trail), Config rules.

---

## Decision table

| Scenario | Decision |
| --- | --- |
| Partner calls Taifa | OAuth + scoped scopes + rate limit |
| Taifa calls partner | Secrets Manager creds + egress allowlist |
| Debug in production | No PII in logs; structured redaction |
| Shared DB for speed | **Rejected** — use API/event |

---

## Cross-references

- [00_ARCHITECTURE_CONSTITUTION.md](00_ARCHITECTURE_CONSTITUTION.md)  
- [03_API_STANDARDS.md](03_API_STANDARDS.md)  
- [`../SECURITY.md`](../SECURITY.md)  
- Tourism: [`../tourism/14_SECURITY_ARCHITECTURE.md`](../tourism/14_SECURITY_ARCHITECTURE.md)

---

## Future considerations

- Hardware security module integration for national ID  
- Continuous compliance scanning (SOC2 automation)  
- Bug bounty program scope definition
