# 07 — Configuration Platform

**Bounded context:** `platform.config`  
**Phase 1:** Secrets, feature flags, environment config

---

## Purpose & business value

**12-factor** config with **Secrets Manager**, **feature flags**, and optional **tenant overrides**—no secrets in git; dynamic toggles without redeploy for non-critical flags.

---

## Responsibilities

| Layer | Tool |
| --- | --- |
| Static env | ECS task env from IaC |
| Secrets | AWS Secrets Manager + KMS |
| Feature flags | `platform_feature_flag` table or AWS AppConfig |
| Tenant config | `tenant_id` scoped JSON (future gov/edu) |

---

## APIs

GET `/platform/config/flags` (authenticated) · internal only for secret resolution.

---

## Events

`platform.config.flag.changed`

---

## Security

Least IAM for task roles; audit flag changes.

---

## AWS

**Secrets Manager** · **AppConfig** (optional) · **SSM Parameter Store** (non-secret)

---

## Roadmap

UI for ops flag management · per-market `market_code` config
