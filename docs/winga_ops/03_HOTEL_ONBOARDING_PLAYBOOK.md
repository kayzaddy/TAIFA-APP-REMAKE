# 3. Hotel Onboarding Playbook

**Owner:** Head of Provider Success (A) · Risk & Trust (KYB) · Settlement (payout config)  
**Rule:** Hotel **may not go live** until every item is complete and signed.

---

## Workflow overview

```
Lead qualification → KYB → Docs → Commission agreement → Inventory → Pricing
→ Availability → Cancellation → Settlement config → Identity → Training
→ Go-live checklist → Post-launch follow-up (Day 7 / Day 30)
```

---

## Stage checklist

### 1. Lead qualification
- [ ] Legal entity identified  
- [ ] Location in active pilot/ops zone  
- [ ] Minimum room inventory / capacity  
- [ ] Decision-maker contact named  
- [ ] No active sanctions / fraud flags (Risk)

### 2. KYB verification
- [ ] Business registration  
- [ ] Beneficial ownership (as required)  
- [ ] Tax ID / TIN  
- [ ] Physical address verified  
- [ ] Status → `verified` only after Risk sign-off  

### 3. Business documentation
- [ ] Trading name vs legal name recorded  
- [ ] Operating hours  
- [ ] Media (exterior/rooms) uploaded  
- [ ] Contact matrix (ops, finance, GM)

### 4. Commission agreement
- [ ] Default bps agreed  
- [ ] Peak/campaign rules (if any) documented  
- [ ] Signed agreement on file  
- [ ] Rule configured in platform (ops/eng support — no engine redesign)

### 5. Inventory setup
- [ ] Offerings created (room types / packages)  
- [ ] Attributes complete (nights, occupancy, amenities)

### 6. Pricing validation
- [ ] Price_minor matches hotel rate sheet  
- [ ] Currency correct  
- [ ] Compare-at / packages validated by Provider Success

### 7. Availability setup
- [ ] Calendar / blackout dates documented  
- [ ] Process for sold-outs agreed

### 8. Cancellation policy
- [ ] Written policy attached to offerings/metadata  
- [ ] Wingas trained on policy language

### 9. Payment settlement configuration
- [ ] Payout destination verified (Finance)  
- [ ] Settlement contact named  
- [ ] Test reconciliation path understood

### 10. Identity verification (signatories)
- [ ] Authorized signatory ID  
- [ ] Ops contact ID (as required)

### 11. Provider training
- [ ] Platform walkthrough completed  
- [ ] SLA & confirmation training  
- [ ] Dispute / refund awareness  
- [ ] Quiz / attestation signed

### 12. Go-live checklist (final gate)
- [ ] All stages 1–11 complete  
- [ ] Mystery inquiry test passed (QA)  
- [ ] Marketplace Ops approval  
- [ ] `onboarding_complete` / field flag set in ops tracker  
- [ ] Go-live date published to Winga Success

### 13. Post-launch follow-up
- [ ] Day 7: lead response audit  
- [ ] Day 30: MBR #1  
- [ ] Issues logged → continuous improvement

---

## Go-live decision

| Result | Action |
| --- | --- |
| All boxes complete | **LIVE** — may receive paid bookings |
| Any box open | **NOT LIVE** — remain pending |
| Risk reject | **Blocked** — do not configure inventory |

Ops tracker is source of truth (not seed roster alone).
