"""Governance HTTP API — scorecard and catalog only."""
from __future__ import annotations

from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from .scorecard import build_scorecard


@extend_schema(tags=["governance"])
class ScorecardView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(build_scorecard())


@extend_schema(tags=["governance"])
class GovernanceCatalogView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        return Response(
            {
                "hub": "docs/GOVERNANCE.md",
                "sections": [
                    "EA_GOVERNANCE",
                    "API_GOVERNANCE",
                    "ENGINEERING_STANDARDS",
                    "PLATFORM_ENGINEERING",
                    "SECURITY_GOVERNANCE",
                    "DATA_GOVERNANCE",
                    "PRIVACY_COMPLIANCE",
                    "AI_GOVERNANCE",
                    "DEVSECOPS",
                    "QUALITY_ENGINEERING",
                    "OBSERVABILITY_GOVERNANCE",
                    "LIFECYCLE",
                    "DOCUMENTATION",
                    "OPERATIONAL_GOVERNANCE",
                    "OWNERSHIP",
                    "SCORECARD",
                    "ENGINEERING_CULTURE",
                    "TECHNICAL_DEBT",
                ],
                "adrs": "docs/adr/",
                "golden_template": "templates/golden-django-service/",
                "model_version": "governance-catalog-v1",
            }
        )
