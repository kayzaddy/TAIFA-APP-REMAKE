"""Configurable compliance evaluation — rules from ComplianceProfile JSON."""
from __future__ import annotations

from .models import ComplianceProfile, CountryProfile


class ComplianceError(Exception):
    pass


def evaluate_transaction_limits(
    *,
    country_code: str,
    amount_minor: int,
    currency: str,
    daily_total_minor: int = 0,
    txn_count_today: int = 0,
) -> dict:
    country = CountryProfile.objects.get(code=country_code.upper())
    profiles = ComplianceProfile.objects.filter(country=country, active=True)
    flags = []
    aml = profiles.filter(category="aml").order_by("-version").first()
    if aml:
        rules = aml.rules or {}
        threshold = int(rules.get("daily_cash_threshold_minor") or 0)
        velocity = int(rules.get("suspicious_velocity_txns") or 0)
        if threshold and (daily_total_minor + amount_minor) >= threshold:
            flags.append(
                {
                    "code": "aml_daily_threshold",
                    "severity": "high",
                    "authority": aml.reporting_authority,
                    "profile": aml.code,
                }
            )
        if velocity and txn_count_today >= velocity:
            flags.append(
                {
                    "code": "aml_velocity",
                    "severity": "medium",
                    "authority": aml.reporting_authority,
                    "profile": aml.code,
                }
            )
    privacy = profiles.filter(category="privacy").order_by("-version").first()
    residency_ok = True
    if privacy and (privacy.rules or {}).get("cross_border_default") is False:
        residency_ok = bool((privacy.rules or {}).get("allow_listed_corridors", True))
    return {
        "country": country.code,
        "currency": currency,
        "flags": flags,
        "requires_review": any(f["severity"] == "high" for f in flags),
        "residency_ok": residency_ok,
        "profiles_applied": list(profiles.values_list("code", flat=True)),
    }


def country_compliance_summary(country_code: str) -> dict:
    country = CountryProfile.objects.get(code=country_code.upper())
    rows = ComplianceProfile.objects.filter(country=country, active=True).order_by(
        "category", "-version"
    )
    return {
        "country": country.code,
        "profiles": [
            {
                "code": p.code,
                "name": p.name,
                "category": p.category,
                "version": p.version,
                "authority": p.reporting_authority,
                "rules": p.rules,
            }
            for p in rows
        ],
    }
