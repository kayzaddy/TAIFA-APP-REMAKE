# Deployable services

**Owner:** Per-service CODEOWNERS  
**Purpose:** Runtime microservices mapped to national platforms.

| Service | Platform |
| --- | --- |
| `identity/` | Identity |
| `payments/` | TNPI |
| `integration/` | TIP |
| `audit/` | Core Audit |
| `notifications/`, `maps/`, `search/`, `media/`, `analytics/` | Shared platform capabilities |

No product-specific BFFs here—place under `products/{slug}/backend/` when needed.
