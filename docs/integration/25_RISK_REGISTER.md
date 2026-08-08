# 25 — Risk Register

---

| ID | Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- | --- |
| I-R01 | TIP becomes monolith ESB | High | Med | ADR-TIP-001, domain ownership |
| I-R02 | Gateway SPOF | Critical | Low | Multi-AZ, DR, rate limits |
| I-R03 | Partner cert expiry outage | High | Med | 30d alerts, automation |
| I-R04 | Schema breaking change | High | Med | Spectral diff, versioning |
| I-R05 | Webhook SSRF | High | Med | URL validation |
| I-R06 | Migration downtime | High | Med | Strangler, dual-run |
| I-R07 | Event bus cost explosion | Med | Med | Archiving, filtering |
| I-R08 | Mesh complexity | Med | High | Phase TIP-5 only |
| I-R09 | Regulatory data residency | High | Low | af-south-1 policy |
| I-R10 | DevPlatform/TIP overlap | Med | Med | Clear DX vs runtime split |

---

## Cross-references

[TIP_GATE_PACKAGE.md](TIP_GATE_PACKAGE.md)
