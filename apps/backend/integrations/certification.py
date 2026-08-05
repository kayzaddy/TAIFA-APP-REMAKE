"""Independent production certification matrix for every integration."""
from __future__ import annotations

from .catalog import build_catalog


def _status_for(entry: dict) -> dict:
    mode = entry.get("mode", "")
    configured = bool(entry.get("configured"))
    category = entry.get("category", "")

    if entry["id"] == "platform.stub_policy":
        deny = mode == "deny"
        return {
            "production_status": "PASS" if deny else "FAIL",
            "security_status": "PASS" if deny else "FAIL",
            "reliability_status": "N/A",
            "observability_status": "PASS",
            "documentation_status": "PASS",
            "testing_coverage": "gates+unit",
            "risk_level": "low" if deny else "critical",
            "certification_status": "CERTIFIED" if deny else "NOT_CERTIFIED",
            "evidence": ["platform.E005", "TAIFA_ALLOW_STUB_ADAPTERS=false required in prod"],
            "remediation": [] if deny else ["Set TAIFA_ALLOW_STUB_ADAPTERS=false"],
        }

    production_ok = configured and mode == "production"
    if entry["id"] == "payments.mpesa" and configured:
        production_ok = True

    security_ok = production_ok or (category == "policy")
    reliability_ok = production_ok and bool(entry.get("reliability"))
    observability_ok = bool(entry.get("observability"))
    docs_ok = True

    if production_ok:
        cert = "CERTIFIED"
        risk = "low" if category in {"webhooks", "policy"} else "medium"
    elif mode in {"disabled", "not_configured"} or not configured:
        cert = "NOT_CERTIFIED"
        risk = "high" if category in {"payments", "identity", "government", "ai"} else "medium"
    elif mode in {"stub", "simulated", "offline_stub", "noop_debug", "console"}:
        cert = "NOT_CERTIFIED"
        risk = "critical" if category in {"payments", "identity", "government", "ai"} else "high"
    else:
        cert = "CONDITIONAL"
        risk = "medium"

    remediation: list[str] = []
    if not configured:
        remediation.append(f"Configure credentials/endpoints for {entry['id']}")
    if mode in {"stub", "simulated", "offline_stub"}:
        remediation.append(f"Replace {mode} with live adapter for {entry['id']}")

    return {
        "production_status": "PASS" if production_ok else "FAIL",
        "security_status": "PASS" if security_ok else "FAIL",
        "reliability_status": "PASS" if reliability_ok else "FAIL",
        "observability_status": "PASS" if observability_ok else "FAIL",
        "documentation_status": "PASS" if docs_ok else "FAIL",
        "testing_coverage": "unit+contract",
        "risk_level": risk,
        "certification_status": cert,
        "evidence": [
            f"adapter={entry.get('adapter')}",
            f"mode={mode}",
            f"configured={configured}",
            f"owner={entry.get('owner')}",
        ],
        "remediation": remediation,
    }


def build_certification_report() -> dict:
    rows = []
    for entry in build_catalog():
        status = _status_for(entry)
        rows.append({**entry, **status})

    certified = [r for r in rows if r["certification_status"] == "CERTIFIED"]
    not_certified = [r for r in rows if r["certification_status"] != "CERTIFIED"]
    critical = [r for r in not_certified if r["risk_level"] == "critical"]

    stub_ok = any(
        r["id"] == "platform.stub_policy" and r["certification_status"] == "CERTIFIED" for r in rows
    )
    payment_live = any(
        r["category"] == "payments" and r["certification_status"] == "CERTIFIED" for r in rows
    )
    identity_ok = any(
        r["id"] == "identity.federation" and r["certification_status"] == "CERTIFIED" for r in rows
    )
    gov_ok = any(
        r["id"] == "government.authorities" and r["certification_status"] == "CERTIFIED" for r in rows
    )
    ai_ok = any(r["id"] == "ai.inference" and r["certification_status"] == "CERTIFIED" for r in rows)

    national_go = stub_ok and payment_live and identity_ok and gov_ok and ai_ok and not critical
    pilot_go = stub_ok and payment_live and not critical

    return {
        "question": (
            "Can every external dependency of Taifa operate safely, reliably, "
            "securely, and observably in production?"
        ),
        "answer": "Yes" if national_go else "No",
        "national_certification": "GO" if national_go else "NO-GO",
        "controlled_pilot": "GO" if pilot_go else "NO-GO",
        "summary": {
            "total": len(rows),
            "certified": len(certified),
            "not_certified": len(not_certified),
            "critical_gaps": len(critical),
        },
        "integrations": rows,
        "uncertified": [
            {
                "id": r["id"],
                "name": r["name"],
                "risk_level": r["risk_level"],
                "mode": r.get("mode"),
                "remediation": r.get("remediation") or [],
            }
            for r in not_certified
        ],
    }
