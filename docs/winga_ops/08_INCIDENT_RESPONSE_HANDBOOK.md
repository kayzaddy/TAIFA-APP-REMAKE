# 8. Incident Response Handbook — Winga Operations

**Owner:** Head of Marketplace Operations (coord) · Eng Support (platform) · Risk (fraud) · Finance (money)  
**Aligns with:** platform `INCIDENT_RESPONSE.md` / on-call (no replacement — Winga overlay)

---

## Severity

| Sev | Definition | Examples | Page |
| --- | --- | --- | --- |
| Sev-1 Critical | Money wrong, widespread outage, active fraud | Settlement mismatch, pay double-post, pay rail down | Immediate |
| Sev-2 High | Blocks bookings for many | Quote/pay flow broken, confirmation backlog | ≤15 min |
| Sev-3 Medium | Degraded / workaround exists | Slow search, single hotel outage | ≤1h |
| Sev-4 Low | Minor / single user | Copy confusion | Business hours |

---

## Incident types & primary owners

| Type | Primary owner | Partners |
| --- | --- | --- |
| Payment failure | Settlement + Eng Support | Finance |
| Booking / workflow failure | Marketplace Ops | Eng Support |
| Settlement mismatch | Settlement | Finance · Eng |
| Provider complaint (ops) | Provider Success | Support |
| Customer complaint | Customer Success / Support | Risk if dispute |
| Fraud / abuse | Risk & Trust | Finance · Legal |
| AI issue (bad advice / money implication) | Winga Success + Product | Eng (guardrails) |
| Operational outage | Eng Support | Marketplace Ops |

---

## Lifecycle

1. **Detect** — alert, ticket, recon, user report  
2. **Triage** — severity, owner, freeze needed?  
3. **Contain** — PAY_FREEZE / SETTLE_FREEZE / disable actor  
4. **Remediate** — fix per SOP; no ad-hoc ledger edits  
5. **Communicate** — status to affected roles  
6. **Resolve** — verify with evidence  
7. **Postmortem** (Sev-1/2 within 5 business days)  
8. **Preventive action** — tracked to close  

---

## Required fields (every incident)

Severity · Owner · Detected_at · Timeline · Impact (bookings/GMV/users) · Resolution · Postmortem link · Preventive action · Status

---

## Postmortem template

- Summary  
- Impact  
- Timeline  
- Root cause  
- What went well / poorly  
- Action items (owner, due)  
- Metrics to watch  

Never blame individuals; fix systems and playbooks.
