# 3. Winga Research Report — Hotels Pilot

**Status:** Protocol ready · Field interviews **0 / 12 target**  
**Seed roster:** 12 verified hotels Wingas (`pilot:winga-hotels-01` … `12`)

---

## Research questions

1. Can a Winga earn first commission within 14 days?  
2. Is the desk (CRM / opportunities / Earn) usable daily?  
3. Does AI coaching change behavior without moving money?  
4. What operational pain blocks deal close?

---

## Method

| Method | n | Timing |
| --- | --- | --- |
| Onboarding diary (7 days) | 12 | Week 1 |
| Weekly 1:1 (20 min) | 12 | Weeks 1–6 |
| Shadow one live negotiation | 5 | Weeks 2–4 |
| Commission clarity quiz | 12 | After first settle |

### Interview script (Wingas)

1. How did you get your last lead?  
2. Show me your pending vs settled commission — is it clear?  
3. What took the most taps yesterday?  
4. Did AI suggestions help or distract?  
5. What would make you recommend Winga to another broker?

---

## Lab findings

| Area | Evidence | Finding |
| --- | --- | --- |
| Income path | Settlement test: 10_000 commission on 100_000 deal | Math + ledger settle works |
| Hotels rate | `hotels-pilot-peak` @ 1200 bps | Campaign override ready |
| Desk UX | Next-action → CRM / Earn / opportunities | Guidance present |
| Transparency | `WingaCommissionBreakdown` widget + tests | Status/rate/share visible |
| AI | Assist blocks `authorize_payment` | Guard holds |
| Opportunities | Client catalog (Hotels trending) | Engage before real campaign API |

**Hypothesis:** Median time-to-first-commission ≤ 14 days for active Wingas (≥3 sessions/week).

---

## Metrics (field)

Leads · conversion · negotiation success · deals closed · commission earned/settled · TTFC · DAU · relationship count · AI usefulness (1–5) · pain themes.

**Field values:** pending.

---

## Training needs (ops)

- KYC verification checklist  
- How to apply to Harbour View opportunity  
- Quote → accept → customer pay → settle sequence  
- Never promise AI can “approve payment”
