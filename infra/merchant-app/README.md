# Taifa Merchant App — AWS deployment (Sprint 1–2)

**Target:** ECS Fargate + RDS PostgreSQL + API Gateway (or ALB) + S3 (logos) + Secrets Manager + CloudWatch.

**Sprint 2:** Apply migration `taifa_merchant.0002_sprint2_workspace` before rolling BFF; no payment/TNPI routes.

**Sprint 3:** Apply `taifa_merchant.0003_sprint3_payments`; configure TNPI/TIP base URL for production MAP client (dev uses in-process stub).

## Components

| Resource | Purpose |
| --- | --- |
| `aws_ecs_service.merchant_bff` | Django BFF container |
| `aws_db_instance.merchant` | RDS PostgreSQL (`taifa_merchant` schema) |
| `aws_secretsmanager_secret.merchant_jwt` | `MERCHANT_JWT_SECRET` |
| `aws_s3_bucket.merchant_media` | Business logos (future presign) |
| `aws_apigatewayv2_api` or ALB | Public HTTPS |
| CloudWatch log group | `/taifa/merchant-bff` |

## Deploy steps

1. Build image from `apps/backend/Dockerfile` (include `taifa_merchant` app).  
2. Run migrations: `python manage.py migrate taifa_merchant`.  
3. Set `DATABASE_URL`, `MERCHANT_JWT_SECRET`, `TAIFA_IDENTITY_JWKS_URL`.  
4. Health check: `GET /healthz` on parent service.

Wire Terraform modules under `infra/` in a follow-up IaC sprint; this README satisfies Sprint 1 planning gate.
