# ADR-0001: Enterprise monorepo (taifa-platform)

**Status:** Accepted  
**Date:** 2026-08-06  
**Deciders:** ARB, CTO Office

---

## Context

Taifa ecosystem spans multiple platforms and products. Fragmented repositories increase duplication risk (Identity, TNPI, TIP) and slow cross-cutting changes.

---

## Decision

Adopt **`taifa-platform`** as the single enterprise monorepository layout governing:

- Platforms, products, shared code, SDKs, APIs, infrastructure, automation, and documentation indexes.

Implementation code migrates incrementally per [LEGACY_REPO_MAPPING.md](../engineering/LEGACY_REPO_MAPPING.md).

---

## Consequences

- **Positive:** One CODEOWNERS model, unified CI, clear boundaries  
- **Negative:** Repo size and CI time—mitigate with path filters and affected-target builds  
- **Compliance:** PDL-026 recorded

---

## Related

- [REPOSITORY_TREE.md](../engineering/REPOSITORY_TREE.md)
- PDL-026 in platform decision log
