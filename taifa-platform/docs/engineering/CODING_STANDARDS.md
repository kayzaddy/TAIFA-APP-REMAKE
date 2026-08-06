# Coding standards

---

## General

- Formatters enforced in CI (Prettier, Black, `dart format`).  
- Max function complexity: refactor > 15 cyclomatic (guideline).  
- Public APIs documented; internal code self-explanatory.

---

## Naming

| Item | Convention |
| --- | --- |
| Python packages | `snake_case` |
| Dart/TS | `lowerCamelCase` / `PascalCase` types |
| Terraform | `taifa_{env}_{resource}` |
| Events | `taifa.{domain}.{entity}.{action}` |

---

## Error handling

- User-facing: problem+json or product error envelope  
- Never leak stack traces to clients  
- Log with `request_id`

---

## Security coding

- Parameterized queries; no string SQL  
- Validate all external input at BFF boundary  
- No secrets in source

---

## Cross-references

[../../docs/tpos/05_ENGINEERING_STANDARDS.md](../../../docs/tpos/05_ENGINEERING_STANDARDS.md)
