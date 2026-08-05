"""AI OS HTTP API — domains consume intelligence here."""
from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .agents import run_agent
from .automation import run_automation
from .command_center import command_center, decision_detail
from .gateway import AiOsError, infer, put_features, resolve_approval
from .knowledge import semantic_search
from .models import (
    AgentDefinition,
    CapabilityDefinition,
    DatasetRegistryEntry,
    KnowledgeDocument,
    ModelRegistryEntry,
)
from .services import seed_ai_os


def _ensure_seeded():
    if CapabilityDefinition.objects.count() == 0:
        seed_ai_os()


@extend_schema(tags=["ai-os"])
class CommandCenterView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure_seeded()
        return Response(command_center())


@extend_schema(tags=["ai-os"])
class CapabilityListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure_seeded()
        rows = CapabilityDefinition.objects.values(
            "code",
            "name",
            "family",
            "status",
            "requires_human_approval",
            "description",
        )
        return Response({"capabilities": list(rows)})


@extend_schema(tags=["ai-os"])
class InferView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, capability_code: str):
        _ensure_seeded()
        try:
            result = infer(
                capability_code=capability_code,
                principal=request.auth.owner,
                payload=request.data.get("payload") or request.data,
                domain_code=str(request.data.get("domain_code", "")),
                agent_code=str(request.data.get("agent_code", "")),
                modality=str(request.data.get("modality", "text")),
            )
        except AiOsError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(result)


@extend_schema(tags=["ai-os"])
class AgentListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure_seeded()
        rows = AgentDefinition.objects.filter(active=True).values(
            "code", "name", "domain_code", "capabilities", "description"
        )
        return Response({"agents": list(rows)})


@extend_schema(tags=["ai-os"])
class AgentRunView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, agent_code: str):
        _ensure_seeded()
        try:
            result = run_agent(
                agent_code=agent_code,
                principal=request.auth.owner,
                message=str(request.data.get("message", "")),
                capability_code=request.data.get("capability_code"),
                payload=request.data.get("payload") or {},
            )
        except AiOsError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(result)


@extend_schema(tags=["ai-os"])
class KnowledgeSearchView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        _ensure_seeded()
        query = str(request.data.get("query", "")).strip()
        if not query:
            return Response({"detail": "query required"}, status=400)
        hits = semantic_search(
            query=query,
            domain_code=str(request.data.get("domain_code", "")),
            limit=int(request.data.get("limit", 5)),
        )
        return Response({"query": query, "hits": hits, "model_version": "knowledge-search-v1"})


@extend_schema(tags=["ai-os"])
class KnowledgeListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure_seeded()
        qs = KnowledgeDocument.objects.filter(active=True)
        domain = request.query_params.get("domain")
        if domain:
            qs = qs.filter(domain_code__iexact=domain)
        return Response(
            {
                "documents": list(
                    qs.values("code", "title", "category", "domain_code", "citation")[:200]
                )
            }
        )


@extend_schema(tags=["ai-os"])
class AutomationRunView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, rule_code: str):
        _ensure_seeded()
        try:
            result = run_automation(
                rule_code=rule_code,
                principal=request.auth.owner,
                event_payload=request.data.get("payload") or request.data,
            )
        except AiOsError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(result, status=201)


@extend_schema(tags=["ai-os"])
class DecisionDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, decision_id):
        try:
            return Response(decision_detail(decision_id))
        except Exception as exc:
            return Response({"detail": str(exc)}, status=404)


@extend_schema(tags=["ai-os"])
class DecisionApprovalView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, decision_id):
        approved = bool(request.data.get("approved", False))
        try:
            from django.db import transaction

            with transaction.atomic():
                decision = resolve_approval(
                    decision_id=decision_id,
                    approved=approved,
                    actor=request.auth.owner,
                )
        except Exception as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(
            {
                "decision_id": str(decision.id),
                "approval_status": decision.approval_status,
            }
        )


@extend_schema(tags=["ai-os"])
class ModelRegistryView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        _ensure_seeded()
        return Response(
            {
                "models": list(
                    ModelRegistryEntry.objects.values(
                        "code", "name", "version", "status", "modality", "deployment", "rollback_to"
                    )
                ),
                "datasets": list(
                    DatasetRegistryEntry.objects.values(
                        "code", "name", "domain_code", "purpose", "pii_class", "row_count"
                    )
                ),
            }
        )


@extend_schema(tags=["ai-os"])
class FeatureStoreView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        try:
            row = put_features(
                entity_type=str(request.data["entity_type"]),
                entity_id=str(request.data["entity_id"]),
                feature_set=str(request.data["feature_set"]),
                features=request.data.get("features") or {},
                model_version=str(request.data.get("model_version", "")),
            )
        except KeyError as exc:
            return Response({"detail": f"missing {exc}"}, status=400)
        return Response({"id": str(row.id), "as_of": row.as_of.isoformat()}, status=201)


@extend_schema(tags=["ai-os"])
class SeedAiOsView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        return Response(seed_ai_os())
