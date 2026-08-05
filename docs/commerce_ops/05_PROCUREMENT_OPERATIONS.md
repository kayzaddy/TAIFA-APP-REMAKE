# 5. Procurement Operations Guide

**Owner:** Supply Chain / Procurement Lead  

---

## Process

```
Supplier onboarding → Purchase request → Approval → PO create
→ Goods receiving → Invoice verification → Supplier payment
→ Scorecard → Reorder planning
```

### Supplier onboarding
- [ ] Legal name / contacts / payment terms  
- [ ] Quality & lead-time expectations  
- [ ] Code in MOS suppliers  

### Purchase request → approval
- Thresholds: manager / finance dual control for large POs  
- Reuse enterprise approval patterns where configured  

### PO creation
- Lines · warehouse · totals · reference  
- Status: draft → submitted → approved  

### Goods receiving
- Warehouse posts receive against PO reference  

### Invoice verification
- 3-way match: PO · receive · invoice (ops sheet if PDF)  

### Supplier payment
- Outside MOS money path via Finance / enterprise settlement rules — **never** forge ledger  

### Scorecards (monthly)
- On-time % · quality rejects · price variance · responsiveness  

### Reorder planning
- Trigger: on_hand ≤ reorder_point  
- AI tips allowed; humans approve POs  
