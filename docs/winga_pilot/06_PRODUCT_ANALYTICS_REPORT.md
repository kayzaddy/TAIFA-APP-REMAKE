# 6. Product Analytics Report — Hotels Pilot

---

## Instrumentation map

| Signal | Where |
| --- | --- |
| Onboarding complete | `experiencePrefsProvider.onboardingComplete` (client) |
| Opportunity save/apply | Experience prefs |
| Domain browse / deal pay | BrokerageController + REST |
| Assist usage | `POST /api/v1/winga/assist` |
| Aggregate marketplace | `GET /api/v1/winga/analytics/summary` |
| Prometheus | `taifa_winga_*` (`winga/metrics.py`) |

**Gap (Medium):** No first-class product analytics events for funnel drop-off (Discover→Pay). Track manually in pilot weeks 1–2; backlog P-03.

---

## Product metrics (definitions)

| Metric | Definition |
| --- | --- |
| DAU / WAU / MAU | Distinct principals with Winga API or app session |
| Session duration | App foreground time (client telemetry TBD) |
| Task completion | Paid deal / started quote flow |
| Drop-off | Largest step loss in funnel |
| Onboarding completion | Finished `/winga/onboarding` |
| Time to first transaction | Principal → first `payment_ref` |
| Time to first commission | Winga → first `CommissionEvent` settled |
| Feature adoption | % using Opportunities / Assist / Earn settle |

---

## Lab product health

| Check | Result |
| --- | --- |
| Role apps routeable | Hub · Customer · Broker · Provider · Onboarding · Opportunities |
| Journey chrome | Stepper · next-action · trust · payment/commission widgets |
| Money path tests | Pass |
| AI payment auth | Blocked |

**Field DAU/WAU/MAU:** pending cohort launch.

---

## Funnel (target vs monitor)

```
Discover → Quote request → Offer → Accept → Pay → Fulfill → Review → Repeat
   100%        55%          40%     35%    30%     28%      20%     15%
```

Percentages are **targets**, not observed field rates. Replace with measured rates weekly.
