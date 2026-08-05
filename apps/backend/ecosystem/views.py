"""Digital Ecosystem Platform HTTP API."""
from __future__ import annotations

from decimal import Decimal, InvalidOperation

from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .ai import invoke_ai
from .models import (
    AgricultureFarm,
    AgricultureListing,
    EcosystemWorkflowBinding,
    IndustryDomain,
    PartnerApplication,
    SharedService,
    WebhookSubscription,
)
from .services import (
    PlatformError,
    create_agriculture_listing,
    ecosystem_blueprint,
    list_enabled_modules,
    observability_snapshot,
    register_farm,
    seed_ecosystem_catalog,
    set_module_enabled,
    start_ecosystem_workflow,
)
from enterprise import workflow as enterprise_workflow


@extend_schema(tags=["platform"])
class EcosystemBlueprintView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        if SharedService.objects.count() == 0:
            seed_ecosystem_catalog()
        return Response(ecosystem_blueprint())


@extend_schema(tags=["platform"])
class SharedServiceListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        if SharedService.objects.count() == 0:
            seed_ecosystem_catalog()
        rows = SharedService.objects.all().values(
            "code", "name", "status", "api_base", "description", "owner_team"
        )
        return Response({"services": list(rows)})


@extend_schema(tags=["platform"])
class DomainListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        if IndustryDomain.objects.count() == 0:
            seed_ecosystem_catalog()
        rows = IndustryDomain.objects.all().values(
            "code",
            "name",
            "status",
            "route",
            "api_base",
            "required_services",
            "capabilities",
            "description",
        )
        return Response({"domains": list(rows)})


@extend_schema(tags=["platform"])
class MyModulesView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        if SharedService.objects.count() == 0:
            seed_ecosystem_catalog()
        return Response({"modules": list_enabled_modules(principal=request.auth.owner)})


@extend_schema(tags=["platform"])
class ModuleEnableView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, module_code: str):
        enabled = bool(request.data.get("enabled", True))
        try:
            row = set_module_enabled(
                principal=request.auth.owner,
                module_code=module_code,
                enabled=enabled,
            )
        except PlatformError as exc:
            return Response({"detail": str(exc)}, status=404)
        return Response(row)


@extend_schema(tags=["platform-workflow"])
class WorkflowBindingListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        if EcosystemWorkflowBinding.objects.count() == 0:
            seed_ecosystem_catalog()
        rows = EcosystemWorkflowBinding.objects.filter(active=True).values(
            "code",
            "name",
            "domain_code",
            "workflow_definition_code",
            "description",
        )
        return Response({"bindings": list(rows)})


@extend_schema(tags=["platform-workflow"])
class WorkflowStartView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        binding = request.data.get("binding_code")
        resource_id = request.data.get("resource_id")
        if not binding or not resource_id:
            return Response({"detail": "binding_code and resource_id required"}, status=400)
        try:
            inst = start_ecosystem_workflow(
                binding_code=str(binding),
                resource_id=str(resource_id),
                actor=request.auth.owner,
                context=request.data.get("context") or {},
            )
        except PlatformError as exc:
            return Response({"detail": str(exc)}, status=404)
        return Response(
            {
                "id": str(inst.id),
                "status": inst.status,
                "current_step": inst.current_step,
                "definition": inst.definition.code,
            },
            status=201,
        )


@extend_schema(tags=["platform-workflow"])
class WorkflowAdvanceView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, instance_id):
        try:
            inst = enterprise_workflow.advance(
                instance_id=instance_id,
                actor=request.auth.owner,
                note=str(request.data.get("note", "")),
            )
        except Exception as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(
            {
                "id": str(inst.id),
                "status": inst.status,
                "current_step": inst.current_step,
            }
        )


@extend_schema(tags=["platform-ai"])
class AiCapabilityListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        if SharedService.objects.count() == 0:
            seed_ecosystem_catalog()
        from .models import AiCapability

        rows = AiCapability.objects.values("code", "name", "status", "description")
        return Response({"capabilities": list(rows)})


@extend_schema(tags=["platform-ai"])
class AiInvokeView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, capability_code: str):
        try:
            result = invoke_ai(
                capability_code=capability_code,
                principal=request.auth.owner,
                payload=request.data.get("payload") or {},
                domain_code=str(request.data.get("domain_code", "")),
            )
        except Exception as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(result)


@extend_schema(tags=["platform-open"])
class WebhookSubscribeView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        rows = WebhookSubscription.objects.filter(
            owner_principal=request.auth.owner, active=True
        ).values("id", "target_url", "event_types", "secret_prefix", "created_at")
        return Response({"subscriptions": list(rows)})

    def post(self, request):
        url = request.data.get("target_url")
        if not url:
            return Response({"detail": "target_url required"}, status=400)
        sub, raw = WebhookSubscription.issue(
            owner_principal=request.auth.owner,
            target_url=str(url),
            event_types=request.data.get("event_types") or ["*"],
        )
        return Response(
            {
                "id": str(sub.id),
                "target_url": sub.target_url,
                "secret": raw,
                "secret_prefix": sub.secret_prefix,
                "event_types": sub.event_types,
                "note": "Store the secret securely; it is shown once.",
            },
            status=201,
        )


@extend_schema(tags=["platform-open"])
class PartnerApplyView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        code = request.data.get("partner_code")
        name = request.data.get("legal_name")
        if not code or not name:
            return Response({"detail": "partner_code and legal_name required"}, status=400)
        app = PartnerApplication.objects.create(
            partner_code=str(code),
            legal_name=str(name),
            owner_principal=request.auth.owner,
            domains=request.data.get("domains") or [],
            contact_email=str(request.data.get("contact_email", "")),
            status="pending",
        )
        try:
            start_ecosystem_workflow(
                binding_code="business_verification",
                resource_id=str(app.id),
                actor=request.auth.owner,
                context={"partner_code": app.partner_code},
            )
        except PlatformError:
            pass
        return Response(
            {"id": str(app.id), "status": app.status, "partner_code": app.partner_code},
            status=201,
        )


@extend_schema(tags=["platform-open"])
class OpenCatalogView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        if SharedService.objects.count() == 0:
            seed_ecosystem_catalog()
        blueprint = ecosystem_blueprint()
        return Response(
            {
                "name": "Taifa Open Platform",
                "version": "1.0.0",
                "rest_base": "/api/v1/",
                "openapi": "/api/schema",
                "domains": blueprint["domains"],
                "shared_services": [s["code"] for s in blueprint["shared_services"]],
                "sdks": blueprint["open_platform"]["sdks"],
                "webhooks": "/api/v1/ecosystem/webhooks/",
                "model_version": "open-catalog-v1",
            }
        )


@extend_schema(tags=["platform"])
class ObservabilityView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(observability_snapshot())


@extend_schema(tags=["platform-agriculture"])
class AgricultureFarmView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = AgricultureFarm.objects.filter(owner_principal=request.auth.owner)
        return Response(
            {
                "farms": [
                    {
                        "id": str(f.id),
                        "farm_code": f.farm_code,
                        "name": f.name,
                        "region": f.region,
                        "district": f.district,
                        "crop_types": f.crop_types,
                        "status": f.status,
                    }
                    for f in qs[:100]
                ]
            }
        )

    def post(self, request):
        try:
            farm = register_farm(
                owner=request.auth.owner,
                farm_code=str(request.data["farm_code"]),
                name=str(request.data["name"]),
                region=str(request.data.get("region", "")),
                district=str(request.data.get("district", "")),
                crop_types=request.data.get("crop_types") or [],
                latitude=_dec(request.data.get("latitude")),
                longitude=_dec(request.data.get("longitude")),
            )
        except KeyError as exc:
            return Response({"detail": f"missing {exc}"}, status=400)
        except Exception as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {"id": str(farm.id), "farm_code": farm.farm_code, "name": farm.name},
            status=201,
        )


@extend_schema(tags=["platform-agriculture"])
class AgricultureListingView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = AgricultureListing.objects.filter(status="open").order_by("-created_at")
        region = request.query_params.get("region")
        if region:
            qs = qs.filter(region__iexact=region)
        return Response(
            {
                "listings": [
                    {
                        "id": str(row.id),
                        "kind": row.kind,
                        "title": row.title,
                        "price_minor": row.price_minor,
                        "quantity_e2": row.quantity_e2,
                        "unit": row.unit,
                        "region": row.region,
                        "status": row.status,
                    }
                    for row in qs[:200]
                ]
            }
        )

    def post(self, request):
        try:
            listing = create_agriculture_listing(
                owner=request.auth.owner,
                kind=str(request.data.get("kind", "produce")),
                title=str(request.data["title"]),
                price_minor=int(request.data["price_minor"]),
                quantity_e2=int(request.data.get("quantity_e2", 0)),
                unit=str(request.data.get("unit", "kg")),
                region=str(request.data.get("region", "")),
                farm_id=request.data.get("farm_id"),
            )
        except (KeyError, ValueError) as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "id": str(listing.id),
                "title": listing.title,
                "price_minor": listing.price_minor,
                "payment_note": "Settle via Taifa Payments; store payment_ref after capture.",
            },
            status=201,
        )


@extend_schema(tags=["platform"])
class SeedCatalogView(APIView):
    """Operator-safe reseed of catalog rows (idempotent)."""

    permission_classes = [IsDevice]

    def post(self, request):
        return Response(seed_ecosystem_catalog())


def _dec(value):
    if value in (None, ""):
        return None
    try:
        return Decimal(str(value))
    except (InvalidOperation, ValueError):
        return None
