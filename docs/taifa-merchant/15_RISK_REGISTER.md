# 15 — Risk Register

---

| ID | Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- | --- |
| TM-R01 | Duplicate TNPI payment logic | Critical | Med | ADR-TM-001, CI boundary |
| TM-R02 | TNPI Merchant API drift | High | Med | Contract tests |
| TM-R03 | Onboarding abandonment | High | Med | UX research, save progress |
| TM-R04 | SoftPOS PCI scope creep | High | Med | MAP handles card data |
| TM-R05 | Fraud on merchant accounts | High | Med | Identity MFA, FRP via TNPI |
| TM-R06 | Webhook delay UX | Med | Med | Polling fallback |
| TM-R07 | AI misleading advice | Med | Med | Disclaimers, no auto money moves |
| TM-R08 | Multi-tenant data leak | Critical | Low | RLS tests |
| TM-R09 | Partner MNO outage | High | Med | Status comms via TNPI |

---

## Cross-references

[TAIFA_MERCHANT_GATE_PACKAGE.md](TAIFA_MERCHANT_GATE_PACKAGE.md)
