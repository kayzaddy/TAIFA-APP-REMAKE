# 6. Production Readiness Matrix

| Capability | Payments | Winga | Commerce | Mobility | Identity | Overall |
| --- | --- | --- | --- | --- | --- | --- |
| Monitoring | Ready | Ready | Partial (mos metrics) | Ready | Ready | Strong |
| Alerting | Ready | Partial | Partial | Ready | Ready | Strong |
| Logging | Ready | Ready | Ready | Ready | Ready | Strong |
| Scaling plan | Documented | Pilot-scale | Pilot-scale | Documented | Ready | Partial |
| Backup | Platform | Platform | Platform | Platform | Platform | Ready |
| Recovery / DR | Documented; drill evidence TBD | Same | Same | Same | Same | Partial |
| Rollback | Container policy | Same | Same | Same | Same | Ready |
| Incident response | Ready | Overlay ready | Overlay ready | Ready | Ready | Ready |
| Runbooks | Ready | winga_ops | commerce_ops | Ops docs | Ready | Ready |
| Support model | Ready | Pilot staffing TBD | Pilot staffing TBD | Partial | Ready | Partial |
| Documentation | Strong | Strong | Strong | Strong | Strong | Strong |
| Secrets / vault | Env-gated | Env-gated | Env-gated | Env-gated | Env-gated | Env-gated |
| **Launch verdict** | **Conditional** | **Pilot only** | **Pilot only** | **Controlled** | **Conditional** | **No blanket GO** |

See [`../platform_governance/11_PRODUCTION_READINESS.md`](../platform_governance/11_PRODUCTION_READINESS.md).
