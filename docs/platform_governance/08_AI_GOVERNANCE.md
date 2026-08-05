# 8. AI Governance Policy

**Owner:** CPO + CISO · AI Platform owner  
**Extends:** [`../governance/AI_GOVERNANCE.md`](../governance/AI_GOVERNANCE.md) · [`../AI_OS_RESPONSIBLE.md`](../AI_OS_RESPONSIBLE.md)

---

## Absolute rules

1. **AI assists only.**  
2. **AI never authorizes financial transactions** (pay, settle, refund, reverse, transfer).  
3. **Human approval** for critical operational/financial decisions.  
4. Prompt governance — no secrets in prompts.  
5. Model versioning + audit trails for production assists.  
6. AI safety review before G3/G7 for AI-facing surfaces.  
7. Bias / quality monitoring for recommendations.  

## Enforcement

API/assist endpoints must reject payment capabilities (HTTP 400).  
Product copy must not imply AI can approve money.  
Violations = Sev-1 product defect + Security review.
