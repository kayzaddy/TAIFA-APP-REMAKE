"""Governance scorecard — compliance signals without owning business domains."""
from __future__ import annotations

from pathlib import Path

from django.conf import settings


def _repo_root() -> Path:
    # apps/backend/governance/scorecard.py → repo root
    return Path(settings.BASE_DIR).resolve().parent.parent


def _exists(*parts: str) -> bool:
    return (_repo_root().joinpath(*parts)).is_file()


def _count_adrs() -> int:
    adr_dir = _repo_root() / "docs" / "adr"
    if not adr_dir.is_dir():
        return 0
    return len([p for p in adr_dir.glob("*.md") if p.name[0:4].isdigit()])


def build_scorecard() -> dict:
    checks = [
        {
            "id": "gov.hub",
            "dimension": "documentation",
            "name": "Governance hub present",
            "pass": _exists("docs", "GOVERNANCE.md"),
            "weight": 5,
        },
        {
            "id": "gov.adr",
            "dimension": "architecture",
            "name": "Foundational ADRs (≥5)",
            "pass": _count_adrs() >= 5,
            "weight": 10,
            "detail": {"adr_count": _count_adrs()},
        },
        {
            "id": "gov.security_doc",
            "dimension": "security",
            "name": "SECURITY.md present",
            "pass": _exists("docs", "SECURITY.md"),
            "weight": 8,
        },
        {
            "id": "gov.observability_doc",
            "dimension": "observability",
            "name": "OBSERVABILITY.md present",
            "pass": _exists("docs", "OBSERVABILITY.md"),
            "weight": 5,
        },
        {
            "id": "gov.pr_template",
            "dimension": "engineering",
            "name": "PR template present",
            "pass": _exists(".github", "PULL_REQUEST_TEMPLATE.md"),
            "weight": 4,
        },
        {
            "id": "gov.codeowners",
            "dimension": "ownership",
            "name": "CODEOWNERS present",
            "pass": _exists(".github", "CODEOWNERS"),
            "weight": 4,
        },
        {
            "id": "gov.golden_template",
            "dimension": "platform_engineering",
            "name": "Golden Django service template",
            "pass": _exists("templates", "golden-django-service", "README.md"),
            "weight": 3,
        },
        {
            "id": "gov.ci",
            "dimension": "devsecops",
            "name": "CI workflow present",
            "pass": _exists(".github", "workflows", "ci.yml"),
            "weight": 8,
        },
        {
            "id": "gov.payments_app",
            "dimension": "architecture",
            "name": "Payments app installed",
            "pass": "payments.apps.PaymentsConfig" in settings.INSTALLED_APPS
            or "payments" in settings.INSTALLED_APPS,
            "weight": 10,
        },
        {
            "id": "gov.ai_os",
            "dimension": "ai",
            "name": "AI OS installed",
            "pass": any("ai_os" in str(a) for a in settings.INSTALLED_APPS),
            "weight": 6,
        },
        {
            "id": "gov.continental",
            "dimension": "architecture",
            "name": "Continental multi-country installed",
            "pass": any("continental" in str(a) for a in settings.INSTALLED_APPS),
            "weight": 6,
        },
        {
            "id": "gov.ecosystem",
            "dimension": "architecture",
            "name": "Ecosystem platform installed",
            "pass": any("ecosystem" in str(a) for a in settings.INSTALLED_APPS),
            "weight": 6,
        },
        {
            "id": "gov.integrations",
            "dimension": "architecture",
            "name": "Integrations fabric installed",
            "pass": any("integrations" in str(a) for a in settings.INSTALLED_APPS),
            "weight": 8,
        },
        {
            "id": "gov.winga",
            "dimension": "architecture",
            "name": "Winga brokerage platform installed",
            "pass": any("winga" in str(a) for a in settings.INSTALLED_APPS),
            "weight": 8,
        },
        {
            "id": "gov.winga_architecture_doc",
            "dimension": "documentation",
            "name": "Winga architecture guide present",
            "pass": _exists("docs", "WINGA_ARCHITECTURE.md"),
            "weight": 4,
        },
        {
            "id": "gov.integration_catalog",
            "dimension": "documentation",
            "name": "Integration catalog documentation present",
            "pass": _exists("docs", "INTEGRATION_CATALOG.md"),
            "weight": 6,
        },
        {
            "id": "gov.debt_register",
            "dimension": "technical_debt",
            "name": "Technical debt register present",
            "pass": _exists("docs", "governance", "TECHNICAL_DEBT.md"),
            "weight": 4,
        },
        {
            "id": "gov.ownership",
            "dimension": "ownership",
            "name": "Ownership matrix present",
            "pass": _exists("docs", "governance", "OWNERSHIP.md"),
            "weight": 5,
        },
        {
            "id": "gov.ai_responsible",
            "dimension": "ai",
            "name": "Responsible AI doc present",
            "pass": _exists("docs", "AI_OS_RESPONSIBLE.md"),
            "weight": 5,
        },
        {
            "id": "runtime.default_deny",
            "dimension": "security",
            "name": "DRF default permission is IsDevice (deny-by-default)",
            "pass": any(
                "IsDevice" in str(p)
                for p in settings.REST_FRAMEWORK.get("DEFAULT_PERMISSION_CLASSES", [])
            ),
            "weight": 10,
        },
        {
            "id": "runtime.commerce_pay_module",
            "dimension": "architecture",
            "name": "Commerce ledger pay services present (no client money forge)",
            "pass": _exists("apps", "backend", "commerce", "services.py"),
            "weight": 10,
        },
        {
            "id": "runtime.platform_gates",
            "dimension": "security",
            "name": "Platform production system checks module present",
            "pass": _exists("apps", "backend", "config", "production_gates.py"),
            "weight": 8,
        },
        {
            "id": "runtime.outbox_delivery",
            "dimension": "reliability",
            "name": "Outbox delivers webhooks (not mark-only)",
            "pass": "deliver_outbox_row" in (
                (_repo_root() / "apps" / "backend" / "enterprise" / "event_bus.py")
                .read_text(encoding="utf-8", errors="ignore")
                if _exists("apps", "backend", "enterprise", "event_bus.py")
                else ""
            ),
            "weight": 8,
        },
        {
            "id": "runtime.dependabot",
            "dimension": "devsecops",
            "name": "Dependabot configured",
            "pass": _exists(".github", "dependabot.yml"),
            "weight": 6,
        },
        {
            "id": "runtime.cert_report",
            "dimension": "documentation",
            "name": "Production certification / remediation report present",
            "pass": _exists("docs", "PRODUCTION_CERTIFICATION_REPORT.md")
            or _exists("docs", "P0_REMEDIATION_REPORT.md"),
            "weight": 4,
        },
    ]

    earned = sum(c["weight"] for c in checks if c["pass"])
    total = sum(c["weight"] for c in checks)
    score_e4 = int((earned * 10_000) / total) if total else 0

    by_dimension: dict[str, dict] = {}
    for c in checks:
        dim = c["dimension"]
        bucket = by_dimension.setdefault(dim, {"passed": 0, "total": 0, "checks": []})
        bucket["total"] += 1
        if c["pass"]:
            bucket["passed"] += 1
        bucket["checks"].append(
            {"id": c["id"], "name": c["name"], "pass": c["pass"], "weight": c["weight"]}
        )

    boards = [
        {"code": "ARB", "name": "Architecture Review Board", "status": "active"},
        {"code": "API", "name": "API Review Board", "status": "active"},
        {"code": "SEC", "name": "Security Review", "status": "active"},
        {"code": "CAB", "name": "Change Advisory (money/identity)", "status": "active"},
    ]

    failed = [c for c in checks if not c["pass"]]
    return {
        "model_version": "governance-scorecard-v2",
        "score_e4": score_e4,
        "score_percent": round(score_e4 / 100, 2),
        "checks_passed": sum(1 for c in checks if c["pass"]),
        "checks_total": len(checks),
        "dimensions": by_dimension,
        "boards": boards,
        "failed_checks": [
            {"id": c["id"], "name": c["name"], "dimension": c["dimension"]} for c in failed
        ],
        "principles": [
            "Platform before product",
            "Never duplicate payments or identity",
            "Configuration over customization",
            "Security by default",
            "Everything observable",
            "AI advisory with human approval for critical actions",
            "Scorecard encodes runtime controls — not docs alone",
        ],
        "docs_hub": "/docs/GOVERNANCE.md",
        "note": (
            "v2 scorecard includes runtime control evidence (default-deny authZ, "
            "commerce pay module, platform gates, outbox delivery, Dependabot). "
            "A high score is necessary but not sufficient for national certification."
        ),
    }
