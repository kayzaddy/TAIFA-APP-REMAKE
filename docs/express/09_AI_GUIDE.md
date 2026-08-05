# Taifa Express — AI Guide

## Foundation assistant

Rule-based themes in `express.services.ai_build_basket`:

- breakfast · chapati · dinner · weekly groceries · cleaning · baby  
- Fallback: match product names from inventory tokens  
- Always returns a **disclaimer**: AI never authorizes payments  

Metric: `taifa_express_ai_assists_total`

## Hard boundary

```
AI → basket suggestion only
Human → review → checkout/pay
Payments → capture_merchant_payment
```

Taifa AI gateway must continue to refuse “pay for me” / authorize intents (Super App guard).

## Future (not in foundation)

- Predictive weekly lists  
- Stock shortage prediction  
- Bundle recommendations tied to MOS inventory  
- Fraud signals fed to Payments risk — still never auto-authorize
