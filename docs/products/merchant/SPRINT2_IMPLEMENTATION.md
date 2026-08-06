# Taifa Merchant — Sprint 2 Implementation

**Sprint:** Merchant Workspace (operational prep for Sprint 3 payment acceptance)  
**Status:** Implemented  
**TEOS / TPOS:** Compliant — no payment processing, SoftPOS, QR, links, or transactions

---

## Sprint goal

Registered merchants get a full **operational workspace**: profile, branches, employees, devices, settings, notifications, and an enriched dashboard with Sprint 3 placeholders only.

---

## Backend (`apps/backend/taifa_merchant`)

| Layer | Additions |
| --- | --- |
| **Domain** | `EmployeeStatus.SUSPENDED`, device types `android_phone` / `android_tablet`, RBAC `settings:*`, `notification:*` |
| **Infrastructure** | `MerchantSettings`, `NotificationPreference`, `MerchantNotification`, `DeviceAssignment`, `BranchStatistics`, `EmployeePermission`, `MerchantActivity`; profile/branch `operating_hours`, `documents`, `description` |
| **Application** | `workspace_services.py` — profile, settings, notifications, operational dashboard, branch dashboard, suspend, device assign |
| **Presentation** | `workspace_views.py` + URL routes under `/api/v1/merchant-app/` |
| **Migration** | `0002_sprint2_workspace` |

### API surface (Sprint 2)

| Method | Path |
| --- | --- |
| GET/PATCH | `/business-profile` |
| GET/PATCH | `/settings` |
| GET | `/notifications` |
| PATCH | `/notifications/preferences` |
| POST | `/notifications/{id}/read` |
| GET | `/activities` |
| GET | `/dashboard` (enriched) |
| GET | `/dashboard/operational` |
| GET | `/branches/{id}/dashboard` |
| POST | `/employees/{id}/suspend` |
| GET | `/devices/{id}` |
| POST | `/devices/{id}/assign` |

OpenAPI: extend `apps/backend/openapi/taifa-merchant-bff-sprint2.yaml` (from sprint1 baseline).

---

## Flutter (`apps/mobile/lib/features/taifa_merchant`)

| Area | Path |
| --- | --- |
| Models (Freezed) | `data/models/merchant_workspace_models.dart` |
| Providers | `application/merchant_workspace_providers.dart` |
| Workspace shell | `presentation/shell/merchant_workspace_shell.dart` |
| Dashboard | `presentation/dashboard/merchant_dashboard_screen.dart` |
| Profile / Settings / Notifications | `presentation/profile|settings|notifications/` |
| Shared widgets | `presentation/widgets/` |
| Routes | `merchant_routes.dart` — `ShellRoute` for main workspace tabs |

---

## Tests

| Suite | Location |
| --- | --- |
| Sprint 1 regression | `tests/test_sprint1_foundation.py` |
| Sprint 2 workspace | `tests/test_sprint2_workspace.py` |

Run:

```bash
cd apps/backend && python manage.py test taifa_merchant.tests
cd apps/mobile && flutter analyze lib/features/taifa_merchant
```

---

## Definition of done (Sprint 2)

- [x] Merchant dashboard operational (summary, timeline, notifications, placeholders)
- [x] Business profile editable
- [x] Branch / employee / device flows extended (branch dashboard, suspend, assign)
- [x] Merchant settings & notification preferences
- [x] APIs documented (this pack + OpenAPI)
- [x] Unit/integration tests pass (8 backend tests)
- [ ] AWS deployment — follow `infra/merchant-app/README.md` (ECS Fargate + RDS; no payment paths)

---

## Deployment (AWS)

1. Build container from `apps/backend` with `taifa_merchant` migrations applied on RDS PostgreSQL.  
2. Store JWT secret in **Secrets Manager**; wire **CloudWatch** logs/metrics.  
3. **S3** for logo keys (`logo_s3_key` on profile; upload flow Sprint 3).  
4. **API Gateway** → ALB → ECS Fargate service (BFF).  
5. No TNPI/MAP routes in this sprint.

---

## Engineering notes

- **Payment preferences** are configuration only (`payment_preferences.sprint3_ready`); no TNPI orchestration.  
- **Device assignment** prepares branch/employee binding for future device auth.  
- **AuditLog** + **MerchantActivity** dual-write on domain events for compliance and UX timeline.
