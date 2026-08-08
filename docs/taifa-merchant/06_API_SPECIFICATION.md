# 06 — API Specification

**Taifa Merchant BFF base:** `/api/v1/merchant-app`  
**TNPI/MAP:** via TIP — see [TNPI catalogs](../payments/14_API_CATALOG.md)

---

## Executive summary

**Application APIs** for web/mobile; **payment operations proxy** to TNPI with session auth—not re-specifying TNPI contracts.

---

## Authentication

Bearer JWT from **Taifa Identity**; claims: `merchant_id`, `roles[]`.

---

## Application APIs

### Workspace & onboarding
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/workspace` | Preferences + TNPI status aggregate |
| PUT | `/workspace/settings` | App settings only |
| GET | `/onboarding/checklist` | Merges TNPI + app steps |
| POST | `/onboarding/complete-step` | UI step only |

### Branches / employees / devices
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/branches` | Proxy TNPI Merchant |
| POST | `/branches` | Proxy |
| GET | `/employees` | Proxy |
| POST | `/employees/invite` | Identity invite + TNPI link |
| GET | `/devices` | Proxy |
| POST | `/devices/register` | Proxy MAP enrollment |

### Acceptance
| Method | Path | Notes |
| --- | --- | --- |
| POST | `/acceptance/qr` | → TNPI MAP |
| POST | `/acceptance/softpos/session` | → MAP |
| POST | `/acceptance/payment-links` | → MAP |

### Transactions & money
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/transactions` | TNPI orchestration query |
| GET | `/transactions/{id}` | Detail |
| POST | `/refunds` | TNPI refund |
| GET | `/receipts/{payment_id}` | TNPI receipt + app template |

### Customers
| Method | Path | Notes |
| --- | --- | --- |
| GET/POST | `/customers` | App CRM |
| GET | `/customers/{id}/history` | TNPI tx filter |

### Reports & analytics
| Method | Path | Notes |
| --- | --- | --- |
| GET | `/reports/daily` | Aggregate TNPI + Analytics |
| GET | `/reports/export` | Media presigned |

### AI
| Method | Path | Notes |
| --- | --- | --- |
| POST | `/ai/assistant/chat` | Tools: sales summary, trends |
| GET | `/ai/insights` | Cached insight cards |

### Notifications
| Method | Path | Notes |
| --- | --- | --- |
| PUT | `/notifications/preferences` | Core Notifications |

---

## OpenAPI

`openapi/taifa-merchant-bff-v1.yaml`

---

## Cross-references

[07_PLATFORM_INTEGRATION.md](07_PLATFORM_INTEGRATION.md)
