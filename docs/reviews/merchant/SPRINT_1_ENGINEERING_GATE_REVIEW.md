# Taifa Merchant — Sprint 1 Engineering Gate Review

| Field | Value |
| --- | --- |
| **Product** | Taifa Merchant |
| **Sprint** | TM-S1 — Merchant Foundation |
| **Review type** | Engineering Review Board (ERB) — pre-merge to `main` |
| **Date** | 2026-08-06 |
| **Reviewers** | ERB (acting roles: CTO, EA, Principal Eng, Security, QA, DevSecOps, DBA, UX Eng) |
| **Artifacts** | [SPRINT1_IMPLEMENTATION.md](../../products/merchant/SPRINT1_IMPLEMENTATION.md) · [26_PRODUCT_BACKLOG.md](../../products/merchant/26_PRODUCT_BACKLOG.md) · [00_PRODUCT_REQUIREMENTS_DOCUMENT.md](../../products/merchant/00_PRODUCT_REQUIREMENTS_DOCUMENT.md) |
| **Code** | `apps/backend/taifa_merchant/` · `apps/mobile/lib/features/taifa_merchant/` |

---

## Executive summary

Sprint 1 delivers a **credible vertical slice** of the Merchant Foundation: JWT-protected BFF endpoints, app-layer schema without payment tables, RBAC matrix, event-driven audit append, Flutter feature module with auth → registration → dashboard → branches/employees/devices, and **three passing API integration tests**. Scope correctly **excludes** QR, SoftPOS, links, settlement, and orchestration.

The implementation is **appropriate for an internal / staging integration branch** but **not** for production pilot or national rollout without remediation. The largest gaps are **platform boundary violations** (parallel local Identity instead of Taifa Identity OIDC), **weak credential storage** (SHA-256 + pepper vs modern KDF), **JWT roles trusted from claims without server-side revalidation**, **incomplete clean architecture** (repository interfaces unused; ORM in application services), **thin test coverage**, **no CI gate**, and **AWS/IaC not implemented** (README only).

**ERB decision:** **PASS WITH CONDITIONS** — merge to `main` is permitted only when **blocking conditions (B1–B6)** are tracked, owned, and scheduled before any **pilot** or **production** gate. Sprint 1 **foundation demo** acceptance for engineering is otherwise met.

---

## Score summary (1–5 scale)

| Category | Score | Weight | Notes |
| --- | ---: | ---: | --- |
| Architecture | **3.2** | High | Layers present; DDD/DI/repositories incomplete |
| Flutter | **3.0** | High | Feature module OK; missing domain, theme, a11y, offline |
| Backend | **3.4** | High | Clear services/APIs; views heavy, logging thin |
| Security | **2.4** | Critical | Dev identity + password hashing + JWT roles |
| AWS / DevSecOps | **2.0** | High | Docs only; no CI, no Terraform |
| Database | **3.8** | Medium | Sensible schema; no RLS/multi-tenant tests |
| API | **3.1** | Medium | REST OK; no pagination, partial OpenAPI |
| QA / Testing | **2.5** | High | Happy-path only; low coverage |
| Performance | **3.0** | Medium | No load test, no query audit |
| UX Engineering | **2.8** | Medium | Functional MVP UI; not PRD polish |
| Documentation | **3.5** | Medium | Sprint doc good; module READMEs light |

**Weighted engineering readiness (staging):** **~3.0 / 5**  
**Production readiness:** **~2.2 / 5** (explicitly out of scope for this gate)

---

## 1. Architecture review

### Strengths

- **Bounded context** isolated in Django app `taifa_merchant` with URL prefix `/api/v1/merchant-app/`, aligned with [06_API_SPECIFICATION.md](../../../taifa-merchant/06_API_SPECIFICATION.md).
- **No payment persistence** in app schema — consistent with ADR-TM-001 and PRD.
- **Layer folders** (`domain/`, `application/`, `infrastructure/`, `presentation/`) communicate intent to a 100-person org.
- **TNPI port** (`TnpiMerchantPort` + `DevTnpiMerchantAdapter`) allows swap-in of TIP client.
- **Domain events** + audit handler demonstrate event-driven pattern for sensitive actions.
- **Flutter feature-first** under `lib/features/taifa_merchant/` with `core/`, `application/`, `presentation/`.

### Gaps and violations

| ID | Finding | Severity |
| --- | --- | --- |
| ARCH-01 | `domain/repositories.py` references **infrastructure** ORM models — dependency rule inverted. | Major |
| ARCH-02 | Repository **Protocol** types are **never implemented**; services use Django ORM directly. | Major |
| ARCH-03 | No **DI container** — views instantiate `AuthService()`, `BranchService()`, etc. per request. | Minor |
| ARCH-04 | **Duplicate Identity** (`MerchantIdentityUser`) conflicts with mission “Use Taifa Identity; do not build separate authentication service.” | **Critical** (platform) |
| ARCH-05 | BFF colocated in monolith payments service — acceptable for Sprint 1; document path to dedicated ECS service (taifa-platform layout). | Minor |
| ARCH-06 | `uuid4` imported unused in `services.py` — small debt. | Minor |

### Scalability / maintainability

- Stateless JWT BFF scales horizontally **if** DB pool and secrets are managed.
- Monolithic Django app will grow; recommend **module boundaries** enforced by import-linter in Sprint 2.
- Technical debt register: see § Technical debt.

**Architecture score: 3.2 / 5**

---

## 2. Flutter review

### Strengths

- **Riverpod** (`hooks_riverpod`) for auth + Dio provider — testable wiring.
- **GoRouter** routes isolated in `merchant_routes.dart`; `/merchant` redirects to merchant login.
- **Secure token storage** via `flutter_secure_storage`.
- **Dio** interceptor attaches Bearer token.
- Material 3 via app-level `TaifaTheme` (inherits from host `MaterialApp`).

### Gaps

| ID | Finding | Severity |
| --- | --- | --- |
| FL-01 | No **domain** layer (entities, repository interfaces) — API client is god-object. | Major |
| FL-02 | Sprint spec cited **Freezed / json_serializable** — not adopted; `Map<String, dynamic>` throughout. | Minor |
| FL-03 | **Offline-ready** claimed in sprint brief — only implicit via Dio errors; no cache/connectivity policy. | Major |
| FL-04 | **Taifa design system** not applied (generic forms; no en/sw). | Major (PRD) |
| FL-05 | **Forgot password / MFA** flows not in UI. | Major |
| FL-06 | Branches screen: FAB pops route without clear create UX; error handling is `toString()`. | Minor |
| FL-07 | No **Semantics** / large text / contrast audit (WCAG PRD NFR). | Major |
| FL-08 | No **widget/integration** tests beyond single login screen smoke test. | Major |

**Flutter score: 3.0 / 5**

---

## 3. Backend review

### Strengths

- **Service classes** encapsulate onboarding, branches, employees, devices, dashboard.
- **DRF serializers** validate input shapes; role choices constrained to enums.
- **MerchantJWTAuthentication** isolated from device-token auth on merchant views.
- **Permission classes** `HasMerchantPermission` + view-level `required_permission`.
- **Transactions** on register/invite/device flows.
- **MerchantAppError** maps to HTTP status in views.

### Gaps

| ID | Finding | Severity |
| --- | --- | --- |
| BE-01 | Views contain **ORM queries** (e.g. `Merchant.objects.get`) — should sit behind repositories. | Minor |
| BE-02 | **Structured logging** (correlation ID) not propagated in merchant app handlers. | Major |
| BE-03 | **Employee invite** does not call Identity/TNPI — invite is DB-only. | Major |
| BE-04 | **Logo / Media** (FR-TM-061) not implemented. | Minor (Could MVP) |
| BE-05 | `complete_mfa_login` accepts **any** MFA code in dev. | **Critical** if MFA enabled in prod |
| BE-06 | No **throttle** scopes on `/auth/signup` and `/auth/login` (global anon throttle only). | Major |
| BE-07 | Duplicate import block in `views.py` (`application.services` twice). | Minor |

**Backend score: 3.4 / 5**

---

## 4. Database review

### Strengths

- Normalized entities: `Merchant` + `MerchantProfile` 1:1; `Branch`, `Employee`, `Device` FK to merchant.
- **Indexes** on `(merchant, status)`, `(merchant, is_active)`, `identity_user_id`, `tnpi_merchant_id`.
- **Unique** `(merchant, code)` for branches, `(merchant, email)` for employees.
- Explicit `db_table` names with `taifa_merchant_*` prefix.
- Initial migration `0001_initial.py` generated and applied in test run.

### Gaps

| ID | Finding | Severity |
| --- | --- | --- |
| DB-01 | **No RLS** or tenant isolation at DB layer (PRD NFR-TM-012). | Major |
| DB-02 | `password_hash` length 128 for hex SHA-256 OK today; not future-proof for Argon2 strings. | Minor |
| DB-03 | No **soft-delete** pattern documented for merchants. | Minor |
| DB-04 | `Employee` created before `Merchant` FK in migration graph — Django resolved; document for ops. | Minor |
| DB-05 | Missing **DB-level check** that `owner` employee matches `owner_identity_user_id`. | Minor |

**Database score: 3.8 / 5**

---

## 5. API review

### Strengths

- Base path `/api/v1/merchant-app/` — versioned.
- RESTful nouns: `branches`, `employees`, `devices`, `merchants/me`, `dashboard`.
- Appropriate status codes: 201 create, 204 logout, 409 duplicate email/merchant.
- Auth endpoints marked `AllowAny` where needed.
- Stub OpenAPI: `apps/backend/openapi/taifa-merchant-bff-sprint1.yaml`.

### Gaps

| ID | Finding | Severity |
| --- | --- | --- |
| API-01 | **No pagination** on list endpoints (PRD-scale lists). | Major |
| API-02 | **No filtering/sorting** query params on transactions (N/A sprint 1) / employees. | Minor |
| API-03 | OpenAPI **not wired** to `drf-spectacular` (no `merchant-app` tag in live schema). | Major |
| API-04 | `POST /merchants/register` response mixes **merchant body + access_token** — non-standard vs other endpoints. | Minor |
| API-05 | Error envelope `{code, detail}` — good; not RFC 7807 problem+json. | Minor |
| API-06 | **DELETE** branch is soft deactivate — document; OK. | — |

**API score: 3.1 / 5**

---

## 6. Security review

### Strengths

- JWT **aud**, **iss**, **exp** validated on decode.
- RBAC matrix codified in `ROLE_PERMISSIONS`.
- Forgot-password returns **202** without enumeration.
- No payment data in schema (reduces PCI scope).
- Audit log on domain events (refund path N/A sprint 1).

### Critical / major findings

| ID | Finding | Severity |
| --- | --- | --- |
| SEC-01 | **Local Identity store** with dev signup/login — not OAuth2/OIDC to Taifa Identity. | **Critical** |
| SEC-02 | Passwords: **SHA-256 + pepper** — insufficient vs OWASP (use Argon2id/bcrypt). | **Critical** |
| SEC-03 | **Roles in JWT** used for authorization without **server-side reload** from `Employee` record. | **Critical** |
| SEC-04 | MFA bypass in `complete_mfa_login`. | **Critical** (if MFA on) |
| SEC-05 | Default `MERCHANT_JWT_SECRET` falls back to `SECRET_KEY`. | Major |
| SEC-06 | No **refresh token** / rotation / revoke list. | Major |
| SEC-07 | No **merchant-app-specific rate limits** on auth. | Major |
| SEC-08 | No **CI security scans** (gitleaks, dependency) for new code. | Major |
| SEC-09 | Tenant isolation: **no test** that user A cannot read merchant B by IDOR. | **Critical** |
| SEC-10 | Input validation present; no **max length** on JSON metadata fields beyond model. | Minor |

**Security score: 2.4 / 5** (acceptable only for **local dev** with synthetic data)

---

## 7. AWS / DevSecOps review

| ID | Finding | Severity |
| --- | --- | --- |
| AWS-01 | `infra/merchant-app/README.md` only — **no Terraform**, no ECS task def in repo. | Major |
| AWS-02 | No **GitHub Actions** job running `taifa_merchant` tests. | **Critical** (merge gate) |
| AWS-03 | Secrets Manager / IAM roles **not codified** for `MERCHANT_JWT_SECRET`. | Major |
| AWS-04 | CloudWatch dashboards/alarms for BFF **not defined**. | Major |
| AWS-05 | Backup/DR for app DB **not differentiated** from main RDS. | Minor |
| AWS-06 | API Gateway vs ALB decision **not implemented**. | Minor (Sprint 2) |

**AWS score: 2.0 / 5**

---

## 8. Testing review

| Area | Present | Missing |
| --- | --- | --- |
| Unit tests | Minimal (implicit via Django) | Service-level unit tests with mocks |
| API integration | 3 tests (happy path) | RBAC deny, IDOR, invalid JWT, 403 cashier refund path |
| Flutter widget | 1 login smoke test | Registration, dashboard, navigation |
| Flutter integration | None | E2E against staging BFF |
| Contract tests | None | TNPI/TIP OpenAPI when integrated |
| Coverage | Not measured | Target ≥70% on `taifa_merchant` for Sprint 2 |

**QA score: 2.5 / 5**

---

## 9. Performance review

- No N+1 audit on dashboard (counts use separate queries — acceptable at small scale).
- No caching on dashboard aggregate (PRD allows TNPI cache later).
- No load test (backlog TMB-026 deferred).
- Flutter: `useFuture` without refresh/pull-to-refresh on lists.

**Performance score: 3.0 / 5** (no regressions observed; not validated under load)

---

## 10. UX engineering review

- **Flow:** Sign up → register business → dashboard is coherent.
- **Navigation:** Side paths to branches/employees/devices; no global shell/tab bar for merchant mode.
- **Consistency:** Does not match Taifa Merchant PRD screen inventory labels (SCR-*).
- **Accessibility:** Not assessed; no semantic labels.
- **Languages:** English only in UI.

**UX score: 2.8 / 5** (engineering pilot OK; not PRD Beta quality)

---

## 11. Documentation review

| Doc | Status |
| --- | --- |
| [SPRINT1_IMPLEMENTATION.md](../../products/merchant/SPRINT1_IMPLEMENTATION.md) | Good |
| [infra/merchant-app/README.md](../../../infra/merchant-app/README.md) | Outline only |
| Module README in `taifa_merchant/` | **Missing** |
| Architecture update in `docs/taifa-merchant/` for Sprint 1 code map | **Missing** |
| Runbook (ops) | **Missing** |
| OpenAPI | Stub file only |

**Documentation score: 3.5 / 5**

---

## Technical debt (registered)

| Debt ID | Description | Pay by |
| --- | --- | --- |
| TD-S1-01 | Replace dev Identity with Taifa Identity OIDC | Sprint 2 (B1) |
| TD-S1-02 | Implement repository adapters; fix domain imports | Sprint 2 |
| TD-S1-03 | Server-side RBAC from DB, not JWT claims alone | Sprint 2 (B2) |
| TD-S1-04 | Argon2 password hashing (if any local creds remain) | Sprint 2 |
| TD-S1-05 | drf-spectacular + full OpenAPI | Sprint 2 |
| TD-S1-06 | Flutter domain layer + typed DTOs | Sprint 2–3 |
| TD-S1-07 | i18n en/sw | MVP gate |
| TD-S1-08 | Extract BFF to deployable unit in `taifa-platform` layout | Roadmap |

---

## Critical issues (must fix before production pilot)

1. **SEC-01** — Integrate **Taifa Identity**; remove or gate `MerchantIdentityUser` behind dev-only flag.  
2. **SEC-02** — Replace password hashing with **Argon2id** (or delegate auth entirely to Identity).  
3. **SEC-03** — Resolve **roles and merchant_id** from database on each request (or short-lived token + server session).  
4. **SEC-09** — Add **IDOR / tenant isolation** tests and fix any leaks.  
5. **AWS-02** — **CI** must run `taifa_merchant` tests on every PR touching paths.  
6. **ARCH-04** — Platform ARB sign-off on Identity deviation or formal **exception** with expiry date.

---

## Major issues (must fix before beta / external merchants)

1. Employee invite → **Identity + TNPI** sync (PRD AC-TM-7).  
2. Auth endpoint **rate limiting** and lockout policy.  
3. **Pagination** on list APIs.  
4. **OpenAPI** published in main schema.  
5. **RLS** or strict queryset scoping tests on every read by `merchant_id`.  
6. Flutter: **forgot password**, **MFA**, **en/sw**, **a11y** pass on auth/dashboard.  
7. **Structured logging** + metrics for BFF.  
8. **MFA** implementation must not accept arbitrary codes.

---

## Minor issues

- Logo upload / Media presign.  
- Repository pattern completion.  
- RFC 7807 errors.  
- Flutter Freezed models.  
- Branch create UX polish.  
- Remove duplicate imports; unused imports.  
- `merchant-app` CODEOWNERS in `taifa-platform/.github/CODEOWNERS` when mirrored.

---

## Recommendations (ERB)

1. **Merge strategy:** Merge Sprint 1 to `main` with feature flag `merchant_foundation_enabled` default **off** in production.  
2. **Sprint 2 gate:** Identity OIDC + TIP TNPI client + CI + security tests are **preconditions** for QR sprint.  
3. **Add** `docs/reviews/merchant/SPRINT_1_REMEDIATION.md` tracking B1–B6 owners (optional PMO).  
4. **Run** import-linter between `taifa_merchant.domain` and `infrastructure`.  
5. **Schedule** pen test **before** MVP pilot (per PRD), not before this merge.

---

## Risk assessment

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| Identity drift from national platform | High | Critical | B1 OIDC integration |
| JWT role escalation | Medium | Critical | B2 server-side RBAC |
| Weak password hashing in dev DB | Medium | High | Dev-only data; B4 hashing |
| Pilot merchants on dev Identity | Low (if gated) | Critical | Feature flag + env separation |
| Monolith coupling | Medium | Medium | Extract BFF service later |
| Insufficient tests allow regressions | High | Major | B3 CI + test matrix |

---

## Definition of Done validation (Sprint 1)

Reference: [SPRINT1_IMPLEMENTATION.md](../../products/merchant/SPRINT1_IMPLEMENTATION.md) and [14_DEFINITION_OF_DONE.md](../../../taifa-merchant/14_DEFINITION_OF_DONE.md) (MVP-oriented; partial apply).

| Criterion | Met? | Evidence |
| --- | --- | --- |
| Auth: signup, login, logout, session | **Yes** | APIs + Flutter |
| Forgot password | **Partial** | API 202 only; no UI/email |
| MFA ready | **Partial** | Flag + stub endpoint; not production-safe |
| Business registration + profile | **Yes** | `merchants/register`, PATCH me |
| Branches CRUD | **Yes** | List/create/patch/deactivate |
| Employees invite / roles / deactivate | **Partial** | No Identity link |
| Devices register/activate/deactivate | **Yes** | APIs tested |
| Dashboard + placeholders | **Yes** | No payments |
| No payment APIs | **Yes** | URL + test |
| JWT auth | **Yes** | Dev issuer |
| RBAC | **Partial** | Matrix exists; JWT trust gap |
| Audit events | **Partial** | Events for some actions; not all sensitive paths |
| Integration tests | **Yes** | 3 tests |
| OpenAPI | **Partial** | Stub YAML |
| Flutter stack | **Partial** | No Freezed; hooks_riverpod OK |
| TNPI boundary | **Yes** | Stub adapter; no pay tables |
| Pen test | **No** | MVP gate |
| Runbook | **No** | — |

**Sprint 1 engineering DoD:** **~75%** — acceptable for **PASS WITH CONDITIONS** to `main`, not for **production pilot**.

---

## Sprint acceptance report

| Epic | Acceptance | Notes |
| --- | --- | --- |
| E1 Authentication | **Conditional** | Dev Identity; MFA/forgot incomplete |
| E2 Merchant registration | **Pass** | TNPI stub id assigned |
| E3 Branch management | **Pass** | |
| E4 Employee management | **Conditional** | Invite not end-to-end with Identity |
| E5 Device management | **Pass** | Registration only, no acceptance |
| E6 Dashboard | **Pass** | Placeholders present |

**Product stories touched:** TM-US-01–05 (partial), 10–12 (partial), 20–21, 30–31 (out of scope), 40 (dashboard counts only).

---

## Blocking conditions for merge to `main` (B1–B6)

| ID | Condition | Owner | Due |
| --- | --- | --- | --- |
| **B1** | Document **Identity deviation** (ADR or PDL) with expiry + Sprint 2 OIDC plan | EA | Before merge |
| **B2** | Add CI job: `python manage.py test taifa_merchant` (+ `flutter test` merchant) | DevSecOps | Before merge |
| **B3** | Add **IDOR test**: user cannot access another `merchant_id` | Backend QA | Before merge |
| **B4** | Gate `MerchantIdentityUser` signup with `settings.MERCHANT_DEV_IDENTITY=True` default True in DEBUG only | Security | Before merge |
| **B5** | **Server-side** merchant membership check: reject if JWT `merchant_id` ≠ employee’s merchant | Backend | Before merge |
| **B6** | Update [00_INDEX.md](../../products/merchant/00_INDEX.md) with link to this review | PMO | Before merge |

*B4/B5 may land as fast-follow PRs within 5 business days if ERB approves merge with linked tickets.*

---

## Go / No-Go decision

### Decision: **PASS WITH CONDITIONS**

### Justification

**Pass** because Sprint 1 achieves the **intended engineering outcome**: a testable foundation that proves monorepo integration, enforces **no payment scope creep**, establishes schema and API surface for branches/employees/devices, and provides a Flutter path for merchant users. Three integration tests pass; architecture direction is understandable to a large team.

**Conditions** because **security and platform alignment are not sufficient** for production or for unchecked exposure to real merchants. Parallel Identity, weak password hashing, JWT role trust, missing tenant-isolation tests, and absent CI are **standard ERB blockers for production** but may be **remediated in parallel** after merge if B1–B6 are enforced.

**Fail** would be warranted if payment logic had been introduced, tenant data leaked in review, or tests did not pass — none apply.

---

### Not approved for

- Production pilot with real merchants  
- National marketing / GA  
- Security Board sign-off  
- Release Board / TNPI production coupling  

### Approved for

- Merge to `main` (with B1–B6)  
- Internal QA and staging demos  
- Sprint 2 planning (Identity, TIP, CI, hardening)  
- Continued development on QR acceptance **only after** B2 + B5 + Identity plan approved by ARB  

---

## Sign-off (record)

| Role | Name | Decision | Date |
| --- | --- | --- | --- |
| CTO / ERB Chair | | PASS WITH CONDITIONS | |
| Enterprise Architect | | | |
| Security | | | |
| QA Lead | | | |
| DevSecOps | | | |

---

## Appendix — File review checklist

| Path | Reviewed |
| --- | --- |
| `apps/backend/taifa_merchant/application/services.py` | Yes |
| `apps/backend/taifa_merchant/presentation/views.py` | Yes |
| `apps/backend/taifa_merchant/presentation/auth.py` | Yes |
| `apps/backend/taifa_merchant/infrastructure/models.py` | Yes |
| `apps/backend/taifa_merchant/infrastructure/identity/jwt_tokens.py` | Yes |
| `apps/backend/taifa_merchant/tests/test_sprint1_foundation.py` | Yes |
| `apps/mobile/lib/features/taifa_merchant/**` | Yes |
| `apps/backend/openapi/taifa-merchant-bff-sprint1.yaml` | Yes |
| `infra/merchant-app/README.md` | Yes |

---

*This document is the authoritative Sprint 1 Engineering Gate Review for Taifa Merchant. Next review: Sprint 2 pre-merge or upon completion of remediation items B1–B6.*
