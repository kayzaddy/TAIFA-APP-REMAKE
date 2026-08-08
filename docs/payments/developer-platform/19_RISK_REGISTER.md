# 19 — Risk Register

---

## Executive summary

Program risks for TNPI Phase 8 Developer Platform.

---

| ID | Risk | Impact | Likelihood | Mitigation | Owner |
| --- | --- | --- | --- | --- | --- |
| DP-R01 | API key leakage | Critical | Med | Hash storage, rotation, education | Security |
| DP-R02 | Gateway bypasses domain auth | Critical | Low | Single public entry, architecture review | Architecture |
| DP-R03 | Sandbox data bleed to prod | Critical | Low | Separate stage/account | SRE |
| DP-R04 | Webhook SSRF / abuse URL | High | Med | URL validation, blocklists | Engineering |
| DP-R05 | DDoS on public API | High | Med | WAF, Shield, rate limits | SRE |
| DP-R06 | Breaking change partner outage | High | Med | Versioning, sunset policy | Product |
| DP-R07 | Logic duplication in gateway | Med | High | Proxy-only ADR, code review | Engineering |
| DP-R08 | Uncertified partner in prod | High | Med | Approval + certification gates | Partner Ops |
| DP-R09 | OpenAPI drift from upstream | Med | High | CI contract tests | Engineering |
| DP-R10 | Partner support overload | Med | Med | Docs, SDKs, tiered support | DX |

---

## Proposed ADRs

- **ADR-TNPI-DP-001** — Developer Platform is proxy/control plane only; no payment/settlement/recon/fraud business logic  
- **ADR-TNPI-DP-002** — All external TNPI traffic enters via Developer Platform API Gateway in production  
- **ADR-TNPI-DP-003** — Production access requires `application.approved` + certification track completion

---

## Operational considerations

Quarterly tabletop: revoked keys, mass webhook failure.

---

## Future expansion

Bug bounty program (DP-R11).

---

## Cross-references

[PHASE8_GATE_PACKAGE.md](PHASE8_GATE_PACKAGE.md) · [fraud-risk/18_RISK_REGISTER.md](../fraud-risk/18_RISK_REGISTER.md)
