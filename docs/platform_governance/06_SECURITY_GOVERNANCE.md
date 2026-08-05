# 6. Security Governance Manual

**Owner:** CISO  
**Extends:** [`../governance/SECURITY_GOVERNANCE.md`](../governance/SECURITY_GOVERNANCE.md) · [`../SECURITY.md`](../SECURITY.md)

---

## Mandatory controls (all platforms)

| Area | Requirement |
| --- | --- |
| Threat modeling | Before G1 |
| Authentication | Device/identity standards |
| Authorization | Least privilege · role reviews |
| Encryption | In transit · at rest per data class |
| Secrets management | No secrets in git |
| Key rotation | Documented cadence |
| Vulnerability management | SLA by severity |
| Penetration testing | Before G7 for money/PII platforms |
| Audit logging | Tamper-evident where required |
| Incident response | Align [`../INCIDENT_RESPONSE.md`](../INCIDENT_RESPONSE.md) |

## Money platforms

Additional: idempotency, ledger integrity, freeze procedures, dual control for reversals.

## Exceptions

Only CISO + CRO; never for “AI may pay.”
