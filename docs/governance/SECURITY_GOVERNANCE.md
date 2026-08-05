# Security Governance

Implements Security by Design. Authoritative control inventory: [`../SECURITY.md`](../SECURITY.md).

## Secure SDLC gates

| Stage | Requirement |
| --- | --- |
| Design | Threat model for money/identity/PII flows |
| Build | SAST, dependency scan, secret scan (CI) |
| Test | Unit/integration; security tests for authz |
| Release | Production gates; Security Owner sign-off for ledger/auth |
| Operate | Vulnerability SLAs, pen-test cadence, IR playbooks |

Align with **OWASP ASVS** L2 for internet-facing money APIs.

## Controls

- Device trust + bearer tokens; RBAC/ABAC via enterprise  
- Zero Trust: never trust network location alone  
- Encryption in transit (TLS); secrets in env/KMS  
- Key rotation procedures documented per environment  
- Supply chain: pin dependencies; review new packages  
- Container/image scanning before prod promote  
- Identity federation adapters — no hardcoded national APIs  

## Reviews

Every new production service: security review checklist + ADR if trust boundary changes.

Incident response: [`../INCIDENT_RESPONSE.md`](../INCIDENT_RESPONSE.md).
