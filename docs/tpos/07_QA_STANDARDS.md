# 07 — QA Standards

---

## Executive summary

Standardized **QA pyramid**: unit, integration, performance, security, accessibility, regression, UAT.

---

## Test types

| Type | Owner | When | Tooling (indicative) |
| --- | --- | --- | --- |
| **Unit** | Engineering | Every PR | jest/pytest/flutter test |
| **Integration** | Engineering | PR + nightly | API contract vs TNPI sandbox |
| **Performance** | QA + Eng | Pre-release | k6, load profiles in `16_TEST_PLAN.md` |
| **Security** | Security + QA | Pre-pilot | DAST, dependency scan |
| **Accessibility** | QA + Design | Pre-beta | axe, manual WCAG |
| **Regression** | QA | Release candidate | Automated suite |
| **UAT** | Product + pilot users | Pilot | Scripted scenarios in `16_TEST_PLAN.md` |

---

## Acceptance criteria

- All user stories have **Given/When/Then** in backlog  
- MVP exit: zero Sev-1/2 open; Sev-3 triaged

---

## Platform testing

- **Contract tests** against TIP/TNPI sandbox mandatory for payment products  
- **No mocking TNPI** in production release pipeline—staging E2E required

---

## Cross-references

[16_TEST_PLAN template](13_TEMPLATES.md) · [08_RELEASE_STANDARDS.md](08_RELEASE_STANDARDS.md)
