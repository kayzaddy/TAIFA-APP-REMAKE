"""Integration catalog + certification API."""
from __future__ import annotations

from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .catalog import build_catalog
from .certification import build_certification_report
from .circuit import get_breaker


class IntegrationCatalogView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response({"integrations": build_catalog()})


class IntegrationCertificationView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        return Response(build_certification_report())


class IntegrationHealthView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        catalog = build_catalog()
        circuits = []
        for entry in catalog:
            name = entry["id"]
            circuits.append(get_breaker(name).status)
        return Response(
            {
                "status": "ok",
                "integrations": [
                    {
                        "id": e["id"],
                        "configured": e.get("configured"),
                        "mode": e.get("mode"),
                    }
                    for e in catalog
                ],
                "circuits": circuits,
            }
        )
