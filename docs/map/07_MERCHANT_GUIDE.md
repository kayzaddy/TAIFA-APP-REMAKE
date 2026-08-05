# 7. Merchant Guide

## Bootstrap

```http
POST /api/v1/map/bootstrap
{ "code": "my-shop", "legal_name": "My Shop Ltd" }
```

Creates/activates `enterprise.Merchant` + `AcceptanceProfile` (QR identity, methods, branding).

## Day-to-day

| Action | Where |
| --- | --- |
| Issue QR | Merchant console `/map/merchant` or API |
| Create link / invoice | Same |
| View analytics | `GET .../analytics` |
| Configure methods / branding | `PATCH .../profile` |

## App

Menu → **Accept (MAP)** → Merchant console or Customer pay.
