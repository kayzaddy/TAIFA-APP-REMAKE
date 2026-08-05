# 1. Pilot Operations Report — Hotels Vertical

**Pilot code:** `hotels-v1`  
**Owner:** Pilot Operations Director  
**Window:** 6 weeks field (recommended) after Conditional GO  

---

## 1. Why Hotels first

| Criterion | Hotels |
| --- | --- |
| Existing domain seed | `hotels` @ 1000 bps default |
| Experience narrative | Harbour View opportunity + offerings already in mobile catalog |
| Deal size | Clear AOV (room nights / packages) |
| Fulfillment | Observable (check-in / voucher) |
| Commission clarity | Percentage of booking value |
| Repeat usage | Corporate + leisure return trips |

Other verticals deferred until Hotels exit criteria pass.

---

## 2. Objectives (must all be true)

1. Customers discover and pay for hotel stays via Winga without staff hand-holding after week 2.  
2. Wingas earn settled commissions on closed deals.  
3. Providers see qualified leads convert to revenue.  
4. Taifa ledger settles payments and commissions with zero critical financial defects.

---

## 3. Operating model

```
Customer → Winga → Harbour View (Provider)
                ↓
         Quote / Negotiate / Accept
                ↓
         POST /deals/{id}/pay  (Idempotency-Key)
                ↓
         Fulfillment (stay)
                ↓
         POST /deals/{id}/settle-commission
                ↓
         Winga wallet credit (ledger)
```

**AI never authorizes payment.** Ops escalates disputes; finance reconciles ledger refs.

---

## 4. Weekly cadence

| Day | Ritual |
| --- | --- |
| Mon | Cohort health review (GMV, commissions, open disputes) |
| Wed | Winga office hours (30 min) |
| Fri | Provider lead-quality sync |
| Continuous | Ticket triage · Critical ≤4h · High ≤1 business day |

---

## 5. Issue classification

| Severity | Definition | Example |
| --- | --- | --- |
| Critical | Money wrong, double pay, settle fail, data loss | Commission credited twice |
| High | Blocks transaction completion | Pay 5xx with funds held |
| Medium | Friction, workaround exists | Confusing quote expiry UX |
| Low | Polish / nice-to-have | Copy tweak |

Loop: root cause → fix → test → deploy → re-validate. No speculative features.

---

## 6. Support playbook (Hotels)

| Topic | First response |
| --- | --- |
| “Where is my booking?” | Deal stage + payment_ref + provider confirmation |
| “I was charged twice” | Idempotency-Key + ledger txn lookup · never reverse manually without finance |
| “Commission missing” | Deal stage must be paid; run settle; check CommissionEvent status |
| “AI told me to pay” | Expected: assist cannot authorize; escalate product if copy implies otherwise |

---

## 7. Lab dry-run results

| Check | Evidence | Pass |
| --- | --- | --- |
| Pay + settle | `WingaSettlementTests.test_pay_and_settle_commission` | ✓ |
| Commission math | percentage / flat / tiered / multi-level tests | ✓ |
| AI money guard | `test_assist_blocks_payment_authorization` | ✓ |
| Mobile offline path | `deal pay then commission settle` | ✓ |
| Pilot cohort seed | `seed_winga_pilot_hotels` → 1P · 3O · 12W · 12% rule | ✓ |

Field GMV / CSAT / retention: **not yet measured** — instruments ready (`GET /api/v1/winga/analytics/summary`).

---

## 8. Risks & mitigations

| Risk | Mitigation |
| --- | --- |
| Low Winga liquidity | Pre-verify 12 Wingas; weekly lead contests |
| Provider lead spam | Verification + reputation; ops quality review |
| Payment rail outage | Platform PRODUCTION_GATE; pause new pays if Critical |
| Scope creep | Single vertical lock until blueprint exit |
