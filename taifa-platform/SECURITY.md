# Security Policy

---

## Supported versions

| Branch | Supported |
| --- | --- |
| `main` | ✅ Active development |
| `release/*` | ✅ Production support |
| Other | ❌ |

---

## Reporting a vulnerability

**Do not** open a public GitHub issue for security vulnerabilities.

Email: **security@taifa.go.tz** (placeholder) with:

- Description and impact  
- Steps to reproduce  
- Affected paths / services  

We aim to acknowledge within **3 business days**.

---

## Secure development

- Secrets: AWS Secrets Manager only  
- Dependencies: automated scanning in CI ([automation/quality](automation/quality/README.md))  
- TNPI/PII: follow [docs/tpos/06_SECURITY_STANDARDS.md](../docs/tpos/06_SECURITY_STANDARDS.md)  
- Production access: break-glass via IAM + audit  

---

## Coordinated disclosure

We coordinate with reporters before public disclosure for confirmed issues.
