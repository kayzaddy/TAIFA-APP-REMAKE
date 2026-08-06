# 18 — Risk Register

---

## Executive summary

GDSP program risks: integration, sovereignty, security, adoption, and platform boundary violations.

---

| ID | Risk | Impact | Likelihood | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- |
| G-R01 | Duplicate Identity/TNPI | Critical | Med | ADR + architecture review | Architecture |
| G-R02 | Agency refuses GaaP | High | Med | Cabinet mandate + MVP value | Program |
| G-R03 | Adapter unreliability | High | High | SLAs, circuit breakers | Integration |
| G-R04 | Data breach citizen PII | Critical | Low | Zero trust, encryption | Security |
| G-R05 | Workflow rigidity | Med | High | Configurable BPMN | Product |
| G-R06 | AI wrong legal advice | High | Med | Disclaimers, human escalate | AI lead |
| G-R07 | Payment reconciliation gap | High | Med | TNPI only path | Finance |
| G-R08 | LGA capacity | High | High | Templates + training | Change mgmt |
| G-R09 | Vendor lock-in | Med | Med | OpenAPI, portable Terraform | Architecture |
| G-R10 | Identity outage stops state | High | Low | Degraded mode policy | SRE |

---

## ADRs

- **ADR-GDSP-001** — Authentication exclusively via Taifa Identity  
- **ADR-GDSP-002** — All government fees via TNPI; GDSP stores references only  
- **ADR-GDSP-003** — Agency remains legal SoR; GDSP is digital case layer  

---

## Cross-references

[GDSP_GATE_PACKAGE.md](GDSP_GATE_PACKAGE.md)
