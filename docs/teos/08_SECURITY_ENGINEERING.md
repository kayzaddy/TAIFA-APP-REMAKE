# 08 — Security engineering

**Owner:** Security Council · **CISO office**

---

## Secure SDLC

| Phase | Activity |
| --- | --- |
| Design | Threat model (STRIDE lite) |
| Build | SAST, dependency scan, secret scan |
| Test | DAST staging; RBAC tests |
| Release | Pen test for pilot/GA (payments) |
| Operate | SOC monitoring, incident response |

---

## Threat modeling

Required for: auth, payments touchpoints, PII, admin, new public APIs.

Template in [16_CHECKLISTS.md](16_CHECKLISTS.md#threat-model).

---

## OWASP Top 10

Address in design review: injection, broken auth, sensitive data exposure, XXE, broken access control, misconfig, XSS, insecure deserialization, known vulns, insufficient logging.

---

## PCI DSS alignment

- No PAN in merchant/product apps — TNPI MAP / certified SoftPOS only  
- Segment card environments per TNPI architecture  
- ASV scans on in-scope components (TNPI program)

---

## Secrets & encryption

| Item | Standard |
| --- | --- |
| Secrets | AWS Secrets Manager; rotation |
| Transit | TLS 1.2+ |
| At rest | RDS encryption, S3 SSE-KMS |
| Git | No secrets; gitleaks in CI |

---

## IAM & RBAC

- Least privilege IAM roles per service  
- Product RBAC server-side enforced  
- No shared prod credentials

---

## Audit logging

Append-only audit for refunds, role changes, admin actions; Core Audit platform.

---

## Security testing

- SAST on every PR  
- Annual pen test minimum for payment pilot  
- Bug bounty (future) via responsible disclosure [SECURITY.md](../SECURITY.md)

---

## Compliance reviews

BOT, PDPA, sector rules via Legal before marketing claims.

---

## Security gate (G-SEC)

| Condition | Required |
| --- | --- |
| Pilot with PII/payments | Threat model + scan clean + sign-off |
| Production TNPI paths | Pen test remediated (critical/high) |

---

## Cross-references

[governance/SECURITY_GOVERNANCE.md](../governance/SECURITY_GOVERNANCE.md) · [INCIDENT_RESPONSE.md](../INCIDENT_RESPONSE.md)
