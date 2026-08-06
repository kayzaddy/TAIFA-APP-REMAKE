# Commit standards

---

## Format (Conventional Commits)

```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

---

## Types

| Type | Use |
| --- | --- |
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Tooling, deps |
| `refactor` | No behavior change |
| `test` | Tests |
| `ci` | CI/CD |
| `infra` | Terraform/k8s |

---

## Scopes (examples)

`merchant`, `tnpi`, `tip`, `core`, `mobile`, `terraform`, `repo`

---

## Breaking changes

Footer: `BREAKING CHANGE: description`

---

## Cross-references

[RELEASE_STRATEGY.md](RELEASE_STRATEGY.md)
