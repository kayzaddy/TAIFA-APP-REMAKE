# 14 — Engineering governance

**Owner:** CTO · **Effective:** Mandatory for all Taifa engineering

---

## Councils

| Council | Chair | Mandate |
| --- | --- | --- |
| **Engineering Council** | VP Engineering | Standards, TEOS adoption, escalations |
| **Architecture Council (ARB)** | Chief Architect | ADRs, duplication, contracts |
| **Security Council** | CISO / Security Lead | G-SEC, risk register |
| **Release Board** | Release Manager | Trains, CAB, hotfixes |
| **QA Council** | QA Lead | G-QA, coverage waivers |
| **Platform Council** | Platform Eng Lead | Core, TNPI, TIP, shared IaC |

---

## RACI (selected activities)

| Activity | Squad | EM | ARB | Security | QA | SRE | Release Board |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Technical design | R | A | C | C | I | I | I |
| ADR approval | C | I | A | C | I | I | I |
| EGR | R | A | C | C | C | I | I |
| PAR | C | C | I | I | C | I | A |
| G-SEC sign-off | C | C | I | A | C | I | I |
| G-QA sign-off | R | A | I | I | A | I | I |
| Prod deploy | R | A | I | C* | I | C | A |
| Incident IC | C | C | I | C | I | A | I |
| TEOS change | C | C | C | C | C | C | A (Eng Council) |

R = Responsible, A = Accountable, C = Consulted, I = Informed. *Security A for payment/auth paths.

---

## Escalation

1. Squad → EM  
2. EM → Engineering Council  
3. Cross-platform → ARB + Platform Council  
4. Risk → Security Council → CTO

---

## TEOS change control

Proposals via PR to `docs/teos/`; Engineering Council approves; PDL entry for material changes.

---

## Cross-references

[00_TEOS_CHARTER.md](00_TEOS_CHARTER.md) · [docs/GOVERNANCE.md](../GOVERNANCE.md)
