# 04 — Coding standards

**Owner:** Principal Engineering · **Enforced:** CI linters

---

## General

- Readable > clever; match surrounding code  
- Public APIs documented  
- No secrets, PAN, or MNO keys in source

---

## Naming

| Domain | Convention |
| --- | --- |
| Python | `snake_case`, `PascalCase` types |
| Dart/Flutter | `lowerCamelCase`, `PascalCase` widgets |
| Terraform | `taifa_{env}_{resource}` |
| Events | `taifa.{domain}.{entity}.{action}` |
| REST paths | kebab-case plural nouns |

---

## Backend (Python/Django/FastAPI)

- Type hints on public functions  
- Black + Ruff (or project equivalent)  
- DRF serializers for input validation  
- DB access in repository/service layer (target); no raw SQL strings  
- Parameterized queries only

---

## Flutter

- Feature-first: `lib/features/{feature}/{data,domain,presentation}`  
- Riverpod for state; GoRouter for navigation  
- Prefer `const` constructors; avoid logic in `build`  
- `flutter analyze` clean; format on save  
- Assets and strings externalized for i18n

---

## Error handling

- Map domain errors to HTTP problem shape  
- Log exceptions with context; never return stacks to clients  
- Idempotent workers for webhooks

---

## Logging

Structured fields: `level`, `message`, `request_id`, `merchant_id` (if applicable), `service`.

---

## Cross-references

[taifa-platform CODING_STANDARDS](../../taifa-platform/docs/engineering/CODING_STANDARDS.md) · [tpos/05_ENGINEERING_STANDARDS.md](../tpos/05_ENGINEERING_STANDARDS.md)
