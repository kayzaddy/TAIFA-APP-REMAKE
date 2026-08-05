"""Continental services — seed, corridors, localization, ops center."""
from __future__ import annotations

from django.db import transaction
from django.utils import timezone

from . import catalog
from .compliance import evaluate_transaction_limits
from .fx import convert_minor, publish_rate
from .models import (
    ComplianceProfile,
    CountryProfile,
    CrossBorderCorridor,
    CrossBorderTransferIntent,
    DataResidencyPolicy,
    IdentityFederationBinding,
    LanguagePack,
    PartnerNetworkMember,
    PaymentRailBinding,
    RegionalOpsMetric,
)


class ContinentalError(Exception):
    pass


@transaction.atomic
def seed_continental() -> dict:
    countries = 0
    by_code: dict[str, CountryProfile] = {}
    for row in catalog.COUNTRIES:
        obj, _ = CountryProfile.objects.update_or_create(
            code=row["code"],
            defaults={
                "name": row["name"],
                "official_name": row["official_name"],
                "status": row["status"],
                "default_currency": row["default_currency"],
                "supported_currencies": row["supported_currencies"],
                "languages": row["languages"],
                "default_locale": row["default_locale"],
                "timezone": row["timezone"],
                "data_region": row["data_region"],
                "calling_code": row["calling_code"],
                "branding": row["branding"],
                "feature_flags": {"ai_os": True, "mobility": True, "payments": True},
            },
        )
        by_code[row["code"]] = obj
        DataResidencyPolicy.objects.update_or_create(
            country=obj,
            defaults={
                "storage_region": row["data_region"],
                "allow_cross_border_processing": False,
                "retention_days": 2555,
                "backup_region": row["data_region"] + "-dr",
                "encryption_profile": "aes-256-gcm",
                "rules": {"sovereignty": "national_default"},
            },
        )
        countries += 1

    compliance = 0
    for code, country in by_code.items():
        for tmpl in catalog.COMPLIANCE_TEMPLATES:
            ComplianceProfile.objects.update_or_create(
                country=country,
                code=tmpl["code"],
                version=1,
                defaults={
                    "name": tmpl["name"],
                    "category": tmpl["category"],
                    "rules": tmpl["rules"],
                    "reporting_authority": f"{code}-regulator",
                    "active": True,
                    "effective_from": timezone.localdate(),
                },
            )
            compliance += 1

    rails = 0
    for code, items in catalog.PAYMENT_RAILS.items():
        country = by_code[code]
        for rail_code, name, currencies in items:
            PaymentRailBinding.objects.update_or_create(
                country=country,
                rail_code=rail_code,
                defaults={
                    "display_name": name,
                    "currencies": currencies,
                    "adapter_path": "",
                    "sandbox": True,
                    "active": True,
                },
            )
            rails += 1

    identity = 0
    for code, items in catalog.IDENTITY_PROVIDERS.items():
        country = by_code[code]
        for provider_code, provider_type, _label in items:
            IdentityFederationBinding.objects.update_or_create(
                country=country,
                provider_code=provider_code,
                defaults={
                    "provider_type": provider_type,
                    "adapter_path": "continental.adapters.StubIdentityAdapter",
                    "active": True,
                    "config": {"label": _label},
                },
            )
            identity += 1

    languages = 0
    for pack in catalog.LANGUAGE_PACKS:
        LanguagePack.objects.update_or_create(
            locale=pack["locale"],
            defaults={
                "name": pack["name"],
                "rtl": pack["rtl"],
                "strings": pack["strings"],
                "active": True,
            },
        )
        languages += 1

    fx = 0
    for cur, rate in catalog.FX_VS_USD.items():
        publish_rate(base="USD", quote=cur, rate_e8=rate, source="seed", valid_hours=24 * 30)
        fx += 1

    corridors = 0
    for code, name, origin, dest, ctype, oc, dc, sc, fee in catalog.CORRIDORS:
        CrossBorderCorridor.objects.update_or_create(
            code=code,
            defaults={
                "name": name,
                "origin_country": by_code[origin],
                "destination_country": by_code[dest],
                "corridor_type": ctype,
                "origin_currency": oc,
                "destination_currency": dc,
                "settlement_currency": sc,
                "fee_bps": fee,
                "active": True,
                "routing": {"priority": ["wallet", "settlement_usd"]},
            },
        )
        corridors += 1

    partners = 0
    for row in catalog.PARTNERS:
        PartnerNetworkMember.objects.update_or_create(
            partner_code=row["partner_code"],
            defaults={
                "legal_name": row["legal_name"],
                "partner_type": row["partner_type"],
                "countries": row["countries"],
                "domains": row["domains"],
                "status": row["status"],
                "certification_tier": row["certification_tier"],
                "certified_at": timezone.now() if row["status"] == "certified" else None,
            },
        )
        partners += 1

    return {
        "countries": countries,
        "compliance_profiles": compliance,
        "payment_rails": rails,
        "identity_bindings": identity,
        "language_packs": languages,
        "fx_rates": fx,
        "corridors": corridors,
        "partners": partners,
    }


def continental_blueprint() -> dict:
    countries = list(
        CountryProfile.objects.values(
            "code",
            "name",
            "status",
            "default_currency",
            "supported_currencies",
            "languages",
            "default_locale",
            "timezone",
            "data_region",
            "calling_code",
            "branding",
        )
    )
    return {
        "vision": "One Platform. Many Countries. Shared Infrastructure. Local Compliance.",
        "countries": countries,
        "currencies": sorted(
            {c for row in countries for c in (row.get("supported_currencies") or [])}
        ),
        "languages": list(
            LanguagePack.objects.filter(active=True).values("locale", "name", "rtl")
        ),
        "corridors": list(
            CrossBorderCorridor.objects.filter(active=True).values(
                "code",
                "name",
                "corridor_type",
                "origin_currency",
                "destination_currency",
                "settlement_currency",
                "fee_bps",
                "origin_country__code",
                "destination_country__code",
            )
        ),
        "open_platform": {
            "rest": "/api/v1/",
            "openapi": "/api/schema",
            "sandbox": "/api/v1/continental/partners/",
            "webhooks": "/api/v1/ecosystem/webhooks/",
            "sdks": ["python", "javascript", "flutter"],
            "graphql": "planned — REST authoritative in v1",
            "certification": ["sandbox", "gold"],
        },
        "certifications_target": [
            "ISO 27001",
            "SOC 2",
            "PCI DSS",
            "ISO 22301",
            "ISO 20022 compatibility",
        ],
        "model_version": "continental-blueprint-v1",
    }


def quote_cross_border(
    *,
    corridor_code: str,
    owner: str,
    amount_minor: int,
) -> CrossBorderTransferIntent:
    try:
        corridor = CrossBorderCorridor.objects.select_related(
            "origin_country", "destination_country"
        ).get(code=corridor_code, active=True)
    except CrossBorderCorridor.DoesNotExist as exc:
        raise ContinentalError(f"unknown corridor: {corridor_code}") from exc
    if amount_minor < 1:
        raise ContinentalError("amount_minor must be positive")

    converted, rate = convert_minor(
        amount_minor=amount_minor,
        from_currency=corridor.origin_currency,
        to_currency=corridor.destination_currency,
    )
    fee = max(corridor.min_fee_minor, amount_minor * corridor.fee_bps // 10_000)
    compliance = evaluate_transaction_limits(
        country_code=corridor.origin_country.code,
        amount_minor=amount_minor,
        currency=corridor.origin_currency,
    )
    intent = CrossBorderTransferIntent.objects.create(
        corridor=corridor,
        owner_principal=owner,
        amount_minor=amount_minor,
        currency=corridor.origin_currency,
        converted_minor=converted,
        converted_currency=corridor.destination_currency,
        fx_rate_e8=rate,
        fee_minor=fee,
        status="quoted",
        compliance_flags=compliance.get("flags") or [],
        metadata={
            "settlement_currency": corridor.settlement_currency,
            "requires_review": compliance.get("requires_review"),
            "payment_note": "Execute settlement via Taifa Payments using payment_ref after capture.",
        },
    )
    return intent


def localize(*, locale: str, key: str, default: str = "") -> str:
    pack = LanguagePack.objects.filter(locale=locale.split("-")[0], active=True).first()
    if not pack:
        pack = LanguagePack.objects.filter(locale="en", active=True).first()
    if not pack:
        return default or key
    return (pack.strings or {}).get(key, default or key)


def global_ops_center() -> dict:
    countries = list(CountryProfile.objects.all())
    today = timezone.localdate()
    metrics = list(
        RegionalOpsMetric.objects.filter(date=today).values(
            "country_code", "domain_code", "kpi_code", "value_e2"
        )
    )
    return {
        "generated_at": timezone.now().isoformat(),
        "countries": [
            {
                "code": c.code,
                "name": c.name,
                "status": c.status,
                "currency": c.default_currency,
                "data_region": c.data_region,
                "locale": c.default_locale,
            }
            for c in countries
        ],
        "active_countries": sum(1 for c in countries if c.status == "active"),
        "pilot_countries": sum(1 for c in countries if c.status == "pilot"),
        "corridors_active": CrossBorderCorridor.objects.filter(active=True).count(),
        "partners_certified": PartnerNetworkMember.objects.filter(status="certified").count(),
        "today_kpis": metrics,
        "slos": {
            "api_availability_target_e4": 9990,
            "payments_p99_ms": 800,
            "fx_quote_freshness_hours": 24,
        },
        "model_version": "continental-ops-center-v1",
    }
