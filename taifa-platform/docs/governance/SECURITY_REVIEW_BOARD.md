# Security Review Board

**Mandate:** Secure SDLC, production clearance for high-risk paths, incident lessons learned.

---

## Scope

- `infrastructure/security`, IAM, secrets
- TNPI, Identity, GDSP changes
- Third-party dependency exceptions
- Pen test remediation sign-off

---

## Gates

| Gate | Requirement |
| --- | --- |
| Pilot | Threat model + STRIDE summary |
| Production | Security scan clean + CAB if required |

---

## Cross-references

[`../../../docs/governance/SECURITY_GOVERNANCE.md`](../../../docs/governance/SECURITY_GOVERNANCE.md) · [DEVSECOPS.md](DEVSECOPS.md)
