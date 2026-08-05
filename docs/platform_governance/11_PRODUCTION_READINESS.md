# 11. Production Readiness Checklist

**Owner:** SRE · COO · CISO  
**Extends:** [`../PRODUCTION_GATE.md`](../PRODUCTION_GATE.md) · [`../DEPLOYMENT.md`](../DEPLOYMENT.md) · [`../DISASTER_RECOVERY.md`](../DISASTER_RECOVERY.md)

---

## Before Gate G8 / launch

- [ ] Monitoring (RED/USE + business KPIs)  
- [ ] Alerting (pages on Sev-1)  
- [ ] Logging (structured, redacted)  
- [ ] Scaling plan / limits  
- [ ] Backup verified  
- [ ] Recovery drill / RTO-RPO  
- [ ] Rollback plan tested  
- [ ] Incident response staffed  
- [ ] Runbooks linked  
- [ ] Support model live  
- [ ] Documentation current  
- [ ] Secrets in vault (not repo)  
- [ ] Feature flags / freeze switches known  
- [ ] Executive approval recorded  

Money platforms: also ledger recon dry-run + PAY/SETTLE freeze drill.
