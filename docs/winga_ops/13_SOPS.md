# 13. Standard Operating Procedures (SOPs)

**Owner:** Head of Operational Excellence  
**Format:** SOP-WINGA-XXX  

---

## SOP-WINGA-001 — Daily marketplace open
**Trigger:** Start of business day  
**Owner:** Marketplace Ops  
**Steps:** Complete handbook daily checklist → post status in ops channel → escalate Sev-1/2.  
**Done when:** Checklist signed.

## SOP-WINGA-002 — Hotel go-live
**Trigger:** Onboarding checklist complete  
**Owner:** Provider Success  
**Steps:** Verify playbook stages → QA mystery inquiry → Marketplace Ops approve → set live flag → notify Winga Success.  
**Done when:** Hotel may accept paid bookings.

## SOP-WINGA-003 — Winga certification
**Trigger:** Training modules complete  
**Owner:** Winga Success  
**Steps:** Verify KYC → score assessment → ethics attestation → certify → add to active roster.  
**Done when:** Winga may originate paid deals.

## SOP-WINGA-004 — Deal payment assist
**Trigger:** Customer cannot pay  
**Owner:** Support → Settlement  
**Steps:** Verify deal stage accepted → guide platform pay → never take card data in chat → escalate failures to Settlement/Eng.  
**Done when:** Pay success or incident opened.

## SOP-WINGA-005 — Commission settle
**Trigger:** Paid + fulfillment confirmed (or policy trigger)  
**Owner:** Settlement  
**Steps:** Confirm pay ledger → run settle-commission → verify event settled + ledger_txn_id → update daily recon.  
**Done when:** Winga wallet impact visible / event settled.

## SOP-WINGA-006 — Daily settlement reconciliation
**See:** Settlement Operations Guide.  
**Done when:** Exceptions = 0 or Sev-1 incident open.

## SOP-WINGA-007 — Refund / reversal
**Trigger:** Approved refund  
**Owner:** Settlement + Finance  
**Steps:** Dual control → reverse per payments SOP → link to deal → notify customer → recon.  
**Forbidden:** Manual balance edits without Finance.

## SOP-WINGA-008 — Dispute handling
**Trigger:** Dispute stage / complaint  
**Owner:** Risk + CS  
**Steps:** Freeze related settle if money at risk → collect evidence → decide → document → close.  

## SOP-WINGA-009 — PAY_FREEZE / SETTLE_FREEZE
**Trigger:** Sev-1 money integrity  
**Owner:** Marketplace Ops (declare) · Finance (confirm)  
**Steps:** Announce → stop new pays/settles → incident bridge → lift only on written clearance.  

## SOP-WINGA-010 — Inactive Winga coaching
**Trigger:** No activity 14 days  
**Owner:** Winga Success  
**Steps:** Outreach → training refresh → opportunity match → or graceful pause.  

## SOP-WINGA-011 — Mystery customer test
**Trigger:** Weekly QA / pre go-live  
**Owner:** OpEx QA  
**Steps:** Run scripted booking attempt → score friction → file findings → no fake paid money in prod without Finance approval (use staging when possible).  

## SOP-WINGA-012 — Weekly ops report publish
**Owner:** Marketplace Ops  
**Steps:** Fill template → attach KPI evidence → review with COO → archive.  

## SOP-WINGA-013 — Research interview logging
**Owner:** Field Ops / UX Research  
**Steps:** Consent → notes → tag themes → **if none conducted, record n=0**. Never invent quotes.  

## SOP-WINGA-014 — Continuous improvement ticket
**Trigger:** Any recurring issue  
**Owner:** OpEx  
**Steps:** Observe→Measure→Root cause→Improve→Validate→Standardize→Document → link to playbook version bump.
