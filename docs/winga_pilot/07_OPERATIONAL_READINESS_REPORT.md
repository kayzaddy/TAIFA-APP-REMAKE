# 7. Operational Readiness Report — Winga Hotels Pilot

**Overall:** **READY FOR CONTROLLED FIELD PILOT** (Conditional GO)  
**Scope:** Winga brokerage money path + Hotels cohort ops  
**Excludes:** Claiming field business-value success

---

## Scorecard

| Domain | Score | Evidence |
| --- | --- | --- |
| Payments collect | PASS (lab) | `collect_deal_payment` + settlement test |
| Commission calculate | PASS | Engine unit tests (%, flat, tiered, multi-level) |
| Commission payout | PASS (lab) | `settle_commissions` → settled + `ledger_txn_id` |
| Workflow transitions | PASS | Default brokerage stages + advance |
| AI financial guard | PASS | Assist rejects payment authorization |
| Notifications | PARTIAL | Platform notifications exist; Winga-specific fatigue rules TBD |
| Documents | PARTIAL | Receipt via payment_ref; formal voucher PDF backlog |
| Disputes / refunds | PARTIAL | Deal stages `disputed`; refund ops via platform payments guide |
| Support process | READY | Playbook in Pilot Ops Report |
| Cohort seed | PASS | `seed_winga_pilot_hotels` |
| Platform observability | PASS | `OPERATIONS_READINESS.md` PASSED |
| HTTP pay/settle API test | GAP | Function-level proven; add APITestCase (High backlog O-01) |

---

## Validation commands

```bash
cd apps/backend
python manage.py test winga -v 1
python manage.py seed_winga
python manage.py seed_winga_pilot_hotels

cd ../mobile
flutter test test/winga/
```

---

## Residual risks (accepted for pilot)

1. Live payment rail credentials must follow `PRODUCTION_GATE.md`.  
2. Hotels multi-property campaign UX is thin — ops configures rules.  
3. Opportunity feed is client catalog until campaign APIs are used for apply.  
4. No fabricated field CSAT — research protocols must be executed.

---

## Certification

**Winga Hotels Lab Gate: PASSED**  
**Winga Hotels Business-Value Gate: NOT STARTED**
