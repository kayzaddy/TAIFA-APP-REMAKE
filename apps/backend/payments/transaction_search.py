"""Transaction search/filtering — a richer, paginated alternative to
`WalletView`'s fixed-50 summary list."""
from __future__ import annotations

from django.core.paginator import Paginator
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .models import Transaction, TransactionDirection, TransactionStatus, TransactionType
from .serializers import TransactionSerializer

MAX_PAGE_SIZE = 100


class TransactionSearchQuerySerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=TransactionType.choices, required=False)
    status = serializers.ChoiceField(choices=TransactionStatus.choices, required=False)
    direction = serializers.ChoiceField(choices=TransactionDirection.choices, required=False)
    min_amount_minor = serializers.IntegerField(required=False, min_value=0)
    max_amount_minor = serializers.IntegerField(required=False, min_value=0)
    from_date = serializers.DateTimeField(required=False)
    to_date = serializers.DateTimeField(required=False)
    q = serializers.CharField(required=False, allow_blank=True, max_length=200)
    page = serializers.IntegerField(required=False, min_value=1, default=1)
    page_size = serializers.IntegerField(required=False, min_value=1, max_value=MAX_PAGE_SIZE, default=20)

    def validate(self, attrs):
        lo, hi = attrs.get("min_amount_minor"), attrs.get("max_amount_minor")
        if lo is not None and hi is not None and lo > hi:
            raise serializers.ValidationError("min_amount_minor cannot exceed max_amount_minor.")
        start, end = attrs.get("from_date"), attrs.get("to_date")
        if start is not None and end is not None and start > end:
            raise serializers.ValidationError("from_date cannot be after to_date.")
        return attrs


@extend_schema(
    tags=["payments"],
    parameters=[
        OpenApiParameter("type", str, description="Filter by transaction type"),
        OpenApiParameter("status", str, description="Filter by status"),
        OpenApiParameter("direction", str, description="credit or debit"),
        OpenApiParameter("min_amount_minor", int),
        OpenApiParameter("max_amount_minor", int),
        OpenApiParameter("from_date", str, description="ISO 8601 datetime, inclusive"),
        OpenApiParameter("to_date", str, description="ISO 8601 datetime, inclusive"),
        OpenApiParameter("q", str, description="Free-text search on counterparty/note"),
        OpenApiParameter("page", int),
        OpenApiParameter("page_size", int, description=f"Max {MAX_PAGE_SIZE}"),
    ],
    responses={200: TransactionSerializer(many=True)},
    summary="Search/filter my transactions (paginated)",
)
class TransactionSearchView(APIView):
    """GET /api/v1/payments/transactions — filtered, paginated transaction
    history for the authenticated device's owner. `WalletView` stays a fast
    fixed-50 summary; this is for building a real history/search screen."""

    permission_classes = [IsDevice]

    def get(self, request):
        q = TransactionSearchQuerySerializer(data=request.query_params)
        q.is_valid(raise_exception=True)
        f = q.validated_data

        qs = Transaction.objects.filter(owner=request.auth.owner)
        if f.get("type"):
            qs = qs.filter(type=f["type"])
        if f.get("status"):
            qs = qs.filter(status=f["status"])
        if f.get("direction"):
            qs = qs.filter(direction=f["direction"])
        if f.get("min_amount_minor") is not None:
            qs = qs.filter(amount_minor__gte=f["min_amount_minor"])
        if f.get("max_amount_minor") is not None:
            qs = qs.filter(amount_minor__lte=f["max_amount_minor"])
        if f.get("from_date"):
            qs = qs.filter(created_at__gte=f["from_date"])
        if f.get("to_date"):
            qs = qs.filter(created_at__lte=f["to_date"])
        if f.get("q"):
            from django.db.models import Q

            qs = qs.filter(Q(counterparty__icontains=f["q"]) | Q(note__icontains=f["q"]))

        paginator = Paginator(qs, f["page_size"])
        page = paginator.get_page(f["page"])
        return Response(
            {
                "count": paginator.count,
                "page": page.number,
                "page_size": f["page_size"],
                "num_pages": paginator.num_pages,
                "results": TransactionSerializer(page.object_list, many=True).data,
            }
        )
