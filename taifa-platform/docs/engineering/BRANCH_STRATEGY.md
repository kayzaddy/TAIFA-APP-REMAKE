# Branch strategy

---

## Protected branches

- `main`: require PR, 2 reviews, CI pass, no force push  
- `release/*`: require QA + Release Board approval for merge to main

---

## Long-lived branches

Avoid `develop` unless mobile train requires it; prefer trunk-based + feature flags.

---

## Platform vs product

Platform changes may require ARB ticket in PR title: `[ARB-123]`.

---

## Fork policy

External contributors: fork + PR only; no direct `main` push.

---

## Cross-references

[GIT_WORKFLOW.md](GIT_WORKFLOW.md)
