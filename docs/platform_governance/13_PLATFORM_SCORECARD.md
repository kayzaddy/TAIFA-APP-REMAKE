# 13. Platform Scorecard Framework

**Owner:** Head of Platform Excellence  
**API:** `GET /api/v1/governance/scorecard` (machine snapshot)  
**Extends:** [`../governance/SCORECARD.md`](../governance/SCORECARD.md)

---

## Dimensions (0–5 each)

| Dimension | 0 | 3 | 5 |
| --- | --- | --- | --- |
| Architecture | None | Reviewed | Certified + debt managed |
| Engineering | Red CI | Green CI | Gates + coverage met |
| Security | Unknown | Controls documented | Audited / pen-tested |
| Experience | None | Journeys live | UX + a11y approved |
| Operations | Ad hoc | Handbook | Drills + SLA met |
| Business | No field proof | Pilot running | Exit criteria met |
| Performance | Untested | Budgets set | Load evidence |
| Reliability | Unknown | Monitored | Error budget healthy |
| Compliance | Unknown | Mapped | Attested |
| Customer Satisfaction | n=0 | Measured | Target met |

**Overall Certification Level:** L0–L7 per Certification Manual.

## Scoring rules

- Lowest money-integrity related dimension caps overall if financial platform  
- Business dimension stays ≤2 without real-user evidence  
- Never invent CSAT/GMV  

## Visual

Executive canvas: `taifa-platform-governance-scorecard.canvas.tsx`
