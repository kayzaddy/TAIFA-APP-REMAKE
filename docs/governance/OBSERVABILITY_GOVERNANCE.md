# Observability Governance

Every service must expose:

- Structured logs with request IDs  
- Distributed traces (OTEL when configured)  
- Metrics (Prometheus)  
- Liveness / readiness (/startup, /deps as applicable)  
- Business KPIs where meaningful (trips completed, payment success)  
- SLIs/SLOs and alerts  
- Dashboards and incident timelines  

Authoritative how-to: [`../OBSERVABILITY.md`](../OBSERVABILITY.md), [`../OPERATIONS.md`](../OPERATIONS.md).

Continental / AI OS / National ops centers are **domain dashboards**; they complement, not replace, platform probes.
