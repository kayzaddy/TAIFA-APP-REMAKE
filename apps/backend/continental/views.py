"""Continental HTTP API — multi-country digital infrastructure."""
from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .adapters import resolve_identity_adapter
from .compliance import country_compliance_summary, evaluate_transaction_limits
from .fx import convert_minor, get_rate_e8, publish_rate
from .models import (
    CountryProfile,
    CrossBorderCorridor,
    DeveloperSandboxCredential,
    LanguagePack,
    PartnerNetworkMember,
    PaymentRailBinding,
)
from .services import (
    ContinentalError,
    continental_blueprint,
    global_ops_center,
    localize,
    quote_cross_border,
    seed_continental,
)


def _ensure():
    if CountryProfile.objects.count() == 0:
        seed_continental()


@extend_schema(tags=["continental"])
class BlueprintView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure()
        return Response(continental_blueprint())


@extend_schema(tags=["continental"], operation_id="continental_countries_list")
class CountryListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure()
        rows = CountryProfile.objects.all().values(
            "code",
            "name",
            "status",
            "default_currency",
            "supported_currencies",
            "languages",
            "default_locale",
            "timezone",
            "data_region",
            "branding",
        )
        return Response({"countries": list(rows)})


@extend_schema(tags=["continental"], operation_id="continental_countries_retrieve")
class CountryDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, country_code: str):
        _ensure()
        try:
            c = CountryProfile.objects.get(code=country_code.upper())
        except CountryProfile.DoesNotExist:
            return Response({"detail": "unknown country"}, status=404)
        rails = list(
            PaymentRailBinding.objects.filter(country=c, active=True).values(
                "rail_code", "display_name", "currencies", "sandbox"
            )
        )
        residency = getattr(c, "residency_policy", None)
        return Response(
            {
                "code": c.code,
                "name": c.name,
                "status": c.status,
                "default_currency": c.default_currency,
                "supported_currencies": c.supported_currencies,
                "languages": c.languages,
                "default_locale": c.default_locale,
                "timezone": c.timezone,
                "data_region": c.data_region,
                "branding": c.branding,
                "payment_rails": rails,
                "residency": {
                    "storage_region": residency.storage_region if residency else None,
                    "allow_cross_border_processing": (
                        residency.allow_cross_border_processing if residency else None
                    ),
                    "retention_days": residency.retention_days if residency else None,
                }
                if residency
                else None,
                "compliance": country_compliance_summary(c.code),
            }
        )


@extend_schema(tags=["continental"])
class OpsCenterView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure()
        return Response(global_ops_center())


@extend_schema(tags=["continental-fx"])
class FxQuoteView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure()
        base = request.query_params.get("base", "USD").upper()
        quote = request.query_params.get("quote", "TZS").upper()
        try:
            rate = get_rate_e8(base=base, quote=quote)
            amount = int(request.query_params.get("amount_minor", "0") or 0)
            converted = None
            if amount:
                converted, _ = convert_minor(
                    amount_minor=amount, from_currency=base, to_currency=quote
                )
        except Exception as exc:
            return Response({"detail": str(exc)}, status=404)
        return Response(
            {
                "base": base,
                "quote": quote,
                "rate_e8": rate,
                "amount_minor": amount or None,
                "converted_minor": converted,
            }
        )

    def post(self, request):
        try:
            row = publish_rate(
                base=str(request.data["base"]),
                quote=str(request.data["quote"]),
                rate_e8=int(request.data["rate_e8"]),
                source=str(request.data.get("source", "api")),
            )
        except (KeyError, ValueError) as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(row.id),
                "base": row.base_currency,
                "quote": row.quote_currency,
                "rate_e8": row.rate_e8,
            },
            status=201,
        )


@extend_schema(tags=["continental"])
class CorridorListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure()
        qs = CrossBorderCorridor.objects.filter(active=True)
        return Response(
            {
                "corridors": list(
                    qs.values(
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
                )
            }
        )


@extend_schema(tags=["continental"])
class CrossBorderQuoteView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        _ensure()
        try:
            intent = quote_cross_border(
                corridor_code=str(request.data["corridor_code"]),
                owner=request.auth.owner,
                amount_minor=int(request.data["amount_minor"]),
            )
        except (KeyError, ValueError, ContinentalError) as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(intent.id),
                "status": intent.status,
                "amount_minor": intent.amount_minor,
                "currency": intent.currency,
                "converted_minor": intent.converted_minor,
                "converted_currency": intent.converted_currency,
                "fx_rate_e8": intent.fx_rate_e8,
                "fee_minor": intent.fee_minor,
                "compliance_flags": intent.compliance_flags,
                "payment_note": (intent.metadata or {}).get("payment_note"),
            },
            status=201,
        )


@extend_schema(tags=["continental"])
class ComplianceEvaluateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        _ensure()
        try:
            result = evaluate_transaction_limits(
                country_code=str(request.data["country_code"]),
                amount_minor=int(request.data["amount_minor"]),
                currency=str(request.data.get("currency", "")),
                daily_total_minor=int(request.data.get("daily_total_minor", 0)),
                txn_count_today=int(request.data.get("txn_count_today", 0)),
            )
        except Exception as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(result)


@extend_schema(tags=["continental"])
class IdentityLookupView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, country_code: str):
        _ensure()
        provider = str(request.data.get("provider_code", "national_id"))
        identifier = str(request.data.get("identifier", ""))
        adapter = resolve_identity_adapter(country_code, provider)
        result = adapter.lookup(
            identifier=identifier,
            identifier_type=str(request.data.get("identifier_type", "national_id")),
        )
        return Response(
            {
                "provider": result.provider,
                "matched": result.matched,
                "reference": result.reference,
                "attributes": result.attributes,
            }
        )


@extend_schema(tags=["continental"])
class LanguagePackView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, locale: str):
        _ensure()
        pack = LanguagePack.objects.filter(locale=locale.split("-")[0], active=True).first()
        if not pack:
            return Response({"detail": "locale not found"}, status=404)
        return Response(
            {
                "locale": pack.locale,
                "name": pack.name,
                "rtl": pack.rtl,
                "strings": pack.strings,
            }
        )


@extend_schema(tags=["continental"])
class TranslateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure()
        locale = request.query_params.get("locale", "en")
        key = request.query_params.get("key", "app.name")
        return Response({"locale": locale, "key": key, "value": localize(locale=locale, key=key)})


@extend_schema(tags=["continental"])
class PartnerListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure()
        return Response(
            {
                "partners": list(
                    PartnerNetworkMember.objects.values(
                        "partner_code",
                        "legal_name",
                        "partner_type",
                        "countries",
                        "domains",
                        "status",
                        "certification_tier",
                    )
                )
            }
        )

    def post(self, request):
        _ensure()
        try:
            partner = PartnerNetworkMember.objects.create(
                partner_code=str(request.data["partner_code"]),
                legal_name=str(request.data["legal_name"]),
                partner_type=str(request.data.get("partner_type", "startup")),
                countries=request.data.get("countries") or [],
                domains=request.data.get("domains") or [],
                contact_email=str(request.data.get("contact_email", "")),
                status="pending",
                certification_tier="sandbox",
            )
            cred, raw = DeveloperSandboxCredential.issue(partner=partner)
        except Exception as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "partner_code": partner.partner_code,
                "status": partner.status,
                "sandbox_api_key": raw,
                "api_key_prefix": cred.api_key_prefix,
                "note": "Store the sandbox key securely; shown once.",
            },
            status=201,
        )


@extend_schema(tags=["continental"])
class SeedView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        return Response(seed_continental())
