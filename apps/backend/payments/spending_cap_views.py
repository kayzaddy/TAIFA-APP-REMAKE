"""Self-service spending cap: view/set/clear a personal budget ceiling on
outgoing money. Enforcement lives in `payments.risk`."""
from __future__ import annotations

from django.db.models import Sum
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .models import (
    CURRENCY_CHOICES,
    SpendingCap,
    SpendingCapPeriod,
    Transaction,
    TransactionDirection,
    TransactionStatus,
)
from .risk import spending_cap_period_start


class SpendingCapSetSerializer(serializers.Serializer):
    period = serializers.ChoiceField(choices=SpendingCapPeriod.choices)
    limit_minor = serializers.IntegerField(min_value=1)
    currency = serializers.ChoiceField(choices=CURRENCY_CHOICES, default="TZS")


class SpendingCapSerializer(serializers.Serializer):
    period = serializers.CharField()
    limit_minor = serializers.IntegerField()
    currency = serializers.CharField()
    spent_minor = serializers.IntegerField()
    remaining_minor = serializers.IntegerField()
    period_start = serializers.DateTimeField()


def _usage(cap: SpendingCap) -> dict:
    start = spending_cap_period_start(cap.period, timezone.now())
    spent = (
        Transaction.objects.filter(
            owner=cap.owner,
            direction=TransactionDirection.DEBIT,
            status__in=[
                TransactionStatus.SUCCEEDED,
                TransactionStatus.PROCESSING,
                TransactionStatus.APPROVED,
                TransactionStatus.PENDING,
            ],
            created_at__gte=start,
            currency=cap.currency,
        ).aggregate(s=Sum("amount_minor"))["s"]
        or 0
    )
    return {
        "period": cap.period,
        "limit_minor": cap.limit_minor,
        "currency": cap.currency,
        "spent_minor": spent,
        "remaining_minor": max(cap.limit_minor - spent, 0),
        "period_start": start,
    }


@extend_schema(
    tags=["payments"],
    request=SpendingCapSetSerializer,
    responses={200: SpendingCapSerializer, 204: None},
    summary="View (GET), set (POST), or clear (DELETE) my spending cap",
)
class SpendingCapView(APIView):
    """/api/v1/payments/spending-cap

    GET returns the current cap plus how much of it is used this period
    (204 if no cap is set). POST upserts (period/limit/currency). DELETE
    removes the cap entirely (uncapped)."""

    permission_classes = [IsDevice]

    def get(self, request):
        cap = SpendingCap.objects.filter(owner=request.auth.owner).first()
        if cap is None:
            return Response(status=204)
        return Response(SpendingCapSerializer(_usage(cap)).data)

    def post(self, request):
        s = SpendingCapSetSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        cap, _ = SpendingCap.objects.update_or_create(
            owner=request.auth.owner,
            defaults={"period": d["period"], "limit_minor": d["limit_minor"], "currency": d["currency"]},
        )
        return Response(SpendingCapSerializer(_usage(cap)).data, status=status.HTTP_200_OK)

    def delete(self, request):
        SpendingCap.objects.filter(owner=request.auth.owner).delete()
        return Response(status=204)
