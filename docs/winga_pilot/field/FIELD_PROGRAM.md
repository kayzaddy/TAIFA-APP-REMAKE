# Field Program Runbook — Hotels Dar (6 Weeks)

**Pilot Director owns this document.**  
**Rule:** No simulated bookings. No fabricated metrics. No platform scope expansion.

---

## Phase gates (must pass in order)

| Phase | Name | Exit before next |
| --- | --- | --- |
| 1 | Hotel onboarding | ≥8 hotels field-onboarded (target 10) |
| 2 | Winga onboarding | ≥15 Wingas training-complete (target 20) |
| 3 | Customer acquisition | ≥50 recruited; sources logged |
| 4 | Live operations | First real paid booking |
| 5 | Daily operations | Dashboard filled every calendar day |
| 6 | Field research | Weekly interviews logged (no invention) |
| 7 | Marketplace metrics | Weekly KPI sheet from API + ops log |
| 8 | Operational excellence | SLA scores reviewed weekly |
| 9 | Weekly improvement | UX/docs/training only — no new modules |
| 10 | Pilot certification | Exit criteria scored with evidence |

**Week 0 status:** Phases 1–3 not complete. Do not open Phase 4 publicly until 1–2 done.

---

## Phase 1 — Hotel onboarding checklist

For each hotel:

- [ ] Business verification (KYB) — field
- [ ] Commission agreement signed (bps / peak rules)
- [ ] Room inventory listed
- [ ] Pricing loaded
- [ ] Availability calendar
- [ ] Cancellation policy documented
- [ ] Media uploaded
- [ ] Business profile complete
- [ ] Settlement / payout contact configured
- [ ] Hotel ops contact named
- [ ] Training session attended

Roster scaffold: `seed_winga_pilot_hotels` (10 slots).  
**Field-complete today:** Harbour View only (anchor).

---

## Phase 2 — Winga onboarding checklist

For each Winga:

- [ ] Identity verification (KYC)
- [ ] Platform walkthrough (`/winga/broker`, opportunities)
- [ ] Hotel product knowledge (Harbour View + peers)
- [ ] Sales playbook
- [ ] Negotiation guide
- [ ] Customer service standards
- [ ] AI assistant training (never authorizes payment)
- [ ] Commission explanation (pending / earned / settled)
- [ ] Trust guidelines
- [ ] Onboarding quiz pass

**Field-complete today:** 0 (5 flagged training-ready in scaffold — still need checklist sign-off).

---

## Phase 3 — Customer acquisition

Channels (organic only during validation):

WhatsApp · Facebook · Instagram · local communities · corporate referrals · friends/family · hotel referrals · organic.

Log every customer: `source`, `recruiter`, `date`, `consent`.

Target: 50–100. **Recruited today: 0.**

---

## Phase 4 — Live journey (real money only)

Discover → Contact Winga → Quotation → Negotiation → Acceptance → Payment → Hotel confirmation → Stay → Settlement → Commission payout → Review

Money path (existing): `POST …/deals/{id}/pay` → `POST …/deals/{id}/settle-commission`

---

## Phase 5 — Daily monitor list

Active Wingas · Active hotels · New leads · Quotes · Accepts · Bookings · Payments · Settlements · Commissions · Support · Refunds · Disputes · CSAT signals · Hotel satisfaction signals

Fill [`01_DAILY_OPERATIONS.md`](01_DAILY_OPERATIONS.md) every day.

---

## Phase 6 — Research rule

Interview weekly. **Never invent feedback.** If no interview occurred, write `n=0` and stop.

---

## Phase 9 — Allowed improvements

Low-risk UX copy, training docs, support macros, checklist fixes.  
Forbidden: new backend modules, payment redesign, commission engine redesign.

---

## Freeze rules

- Critical financial defect → freeze new pays until cleared  
- Commission mismatch → freeze settles; escalate finance  
- Hotel not onboarded → cannot receive paid bookings
