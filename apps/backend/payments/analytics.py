"""Spending analytics — monthly in/out totals + breakdown by transaction
type, computed in Python (not DB-specific date-trunc SQL) so it behaves
identically on the SQLite dev fallback and Postgres production."""
from __future__ import annotations

from collections import OrderedDict, defaultdict

from dateutil.relativedelta import relativedelta
from django.utils import timezone
from drf_spectacular.utils import OpenApiParameter, extend_schema
from rest_framework import serializers
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .models import CURRENCY_CHOICES, Transaction, TransactionDirection, TransactionStatus

MIN_MONTHS = 1
MAX_MONTHS = 24
DEFAULT_MONTHS = 6


class SpendingAnalyticsQuerySerializer(serializers.Serializer):
    months = serializers.IntegerField(
        required=False, default=DEFAULT_MONTHS, min_value=MIN_MONTHS, max_value=MAX_MONTHS
    )
    currency = serializers.ChoiceField(choices=CURRENCY_CHOICES, default="TZS")


@extend_schema(
    tags=["payments"],
    parameters=[
        OpenApiParameter("months", int, description=f"1-{MAX_MONTHS}, default {DEFAULT_MONTHS}"),
        OpenApiParameter("currency", str, description="Default TZS"),
    ],
    summary="Monthly spending breakdown (in/out totals + by transaction type)",
)
class SpendingAnalyticsView(APIView):
    """GET /api/v1/payments/analytics/spending — only `succeeded` transactions
    count (pending/failed never moved money). Only one currency at a time,
    matching how the rest of the wallet API treats currency (WalletView
    itself is hardcoded to TZS) — pass `currency` to look at another."""

    permission_classes = [IsDevice]

    def get(self, request):
        q = SpendingAnalyticsQuerySerializer(data=request.query_params)
        q.is_valid(raise_exception=True)
        months = q.validated_data["months"]
        currency = q.validated_data["currency"]

        now = timezone.now()
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        range_start = month_start - relativedelta(months=months - 1)

        buckets: OrderedDict[str, dict] = OrderedDict()
        for i in range(months):
            key = (range_start + relativedelta(months=i)).strftime("%Y-%m")
            buckets[key] = {"total_in_minor": 0, "total_out_minor": 0, "by_type": defaultdict(int)}

        txns = Transaction.objects.filter(
            owner=request.auth.owner,
            status=TransactionStatus.SUCCEEDED,
            currency=currency,
            created_at__gte=range_start,
        ).only("amount_minor", "direction", "type", "created_at")

        for t in txns:
            key = t.created_at.strftime("%Y-%m")
            bucket = buckets.get(key)
            if bucket is None:
                continue  # created_at rounds oddly at a month boundary — skip rather than crash
            if t.direction == TransactionDirection.CREDIT:
                bucket["total_in_minor"] += t.amount_minor
            else:
                bucket["total_out_minor"] += t.amount_minor
            bucket["by_type"][t.type] += t.amount_minor

        months_out = []
        total_in = total_out = 0
        for key, b in buckets.items():
            total_in += b["total_in_minor"]
            total_out += b["total_out_minor"]
            months_out.append(
                {
                    "month": key,
                    "total_in_minor": b["total_in_minor"],
                    "total_out_minor": b["total_out_minor"],
                    "net_minor": b["total_in_minor"] - b["total_out_minor"],
                    "by_type": dict(b["by_type"]),
                }
            )

        return Response(
            {
                "currency": currency,
                "months": months_out,
                "summary": {
                    "total_in_minor": total_in,
                    "total_out_minor": total_out,
                    "net_minor": total_in - total_out,
                },
            }
        )
