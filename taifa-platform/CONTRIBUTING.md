# Contributing to taifa-platform

Thank you for contributing to Tanzania's digital operating system. All work must follow **[TPOS](../docs/tpos/00_TPOS_CHARTER.md)** and **[GOVERNANCE](../docs/GOVERNANCE.md)**.

---

## Before you start

1. Read [ARCHITECTURE.md](ARCHITECTURE.md) and [docs/engineering/ENGINEERING_GUIDELINES.md](docs/engineering/ENGINEERING_GUIDELINES.md).  
2. Confirm your change has a **product charter** or **platform ADR** if it crosses boundaries.  
3. Never add payment, identity, or integration logic outside approved platform paths.

---

## Workflow

1. Fork / branch from `main` per [GIT_WORKFLOW.md](docs/engineering/GIT_WORKFLOW.md).  
2. Use [commit conventions](docs/engineering/COMMIT_STANDARDS.md).  
3. Open PR with template; request CODEOWNERS reviewers.  
4. Pass CI quality gates ([automation/ci](automation/ci/README.md)).  
5. Obtain required reviews (Eng + Security for sensitive paths).

---

## Documentation changes

- Architecture / ADRs → `docs/decisions/` or `docs/architecture/`  
- Product docs → `products/{slug}/` per TPOS  
- Runbooks → `docs/runbooks/`

---

## Security

Report vulnerabilities per [SECURITY.md](SECURITY.md)—do not open public issues for security bugs.

---

## Code of conduct

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
