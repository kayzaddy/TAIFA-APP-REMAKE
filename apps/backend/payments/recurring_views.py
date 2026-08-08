"""Standing orders API — create, list, pause/resume/cancel a recurring P2P
payment. Execution itself happens in `payments.recurring` on a beat schedule.
"""
from __future__ import annotations

from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .models import (
    CURRENCY_CHOICES,
    Device,
    RecurringInterval,
    RecurringPayment,
    RecurringPaymentStatus,
)
from .p2p_views import _display_name_for
from .people import normalize_phone


class RecurringPaymentCreateSerializer(serializers.Serializer):
    payee = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")
    payee_phone = serializers.CharField(max_length=20, required=False, allow_blank=True, default="")
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.ChoiceField(choices=CURRENCY_CHOICES, default="TZS")
    interval = serializers.ChoiceField(choices=RecurringInterval.choices)
    note = serializers.CharField(max_length=255, required=False, allow_blank=True, default="")
    emoji = serializers.CharField(max_length=16, required=False, allow_blank=True, default="")
    # Defaults to now (fires on the first beat tick); pass a future ISO datetime to delay.
    start_at = serializers.DateTimeField(required=False, allow_null=True, default=None)

    def validate(self, attrs):
        if not attrs.get("payee") and not attrs.get("payee_phone"):
            raise serializers.ValidationError("Provide either payee or payee_phone.")
        return attrs


class RecurringPaymentSerializer(serializers.ModelSerializer):
    payee_name = serializers.SerializerMethodField()

    class Meta:
        model = RecurringPayment
        fields = [
            "id", "owner", "payee", "payee_name", "amount_minor", "currency",
            "note", "emoji", "interval", "status", "next_run_at", "last_run_at",
            "consecutive_failures", "created_at", "updated_at",
        ]

    def get_payee_name(self, obj: RecurringPayment) -> str:
        return _display_name_for(obj.payee)


@extend_schema(
    tags=["social-payments"],
    request=RecurringPaymentCreateSerializer,
    responses={201: RecurringPaymentSerializer, 200: RecurringPaymentSerializer(many=True)},
    summary="Create (POST) or list (GET) my standing orders",
)
class RecurringPaymentListCreateView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def get(self, request):
        rps = RecurringPayment.objects.filter(owner=request.auth.owner)
        return Response({"recurring_payments": RecurringPaymentSerializer(rps, many=True).data})

    def post(self, request):
        s = RecurringPaymentCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        owner = request.auth.owner

        if d.get("payee_phone"):
            target = Device.objects.filter(phone_number=normalize_phone(d["payee_phone"])).first()
            if target is None:
                return Response({"detail": "No TAIFA wallet is linked to that number."}, status=404)
            payee = target.owner
        else:
            payee = d["payee"]
            if not Device.objects.filter(owner=payee).exists():
                return Response({"detail": "No wallet found for that payee."}, status=404)

        if payee == owner:
            return Response({"detail": "You cannot set up a standing order to yourself."}, status=422)

        rp = RecurringPayment.objects.create(
            owner=owner,
            payee=payee,
            amount_minor=d["amount_minor"],
            currency=d["currency"],
            note=d.get("note", ""),
            emoji=d.get("emoji", ""),
            interval=d["interval"],
            next_run_at=d.get("start_at") or timezone.now(),
        )
        return Response(RecurringPaymentSerializer(rp).data, status=status.HTTP_201_CREATED)


@extend_schema(
    tags=["social-payments"],
    request=None,
    responses={200: RecurringPaymentSerializer},
    summary="Pause, resume, or cancel a standing order",
    operation_id="payments_recurring_action",
)
class RecurringPaymentActionView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, recurring_id, action):
        try:
            rp = RecurringPayment.objects.get(pk=recurring_id, owner=request.auth.owner)
        except RecurringPayment.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)

        if action == "pause":
            if rp.status != RecurringPaymentStatus.ACTIVE:
                return Response({"detail": f"Cannot pause a {rp.status} order."}, status=409)
            rp.status = RecurringPaymentStatus.PAUSED
        elif action == "resume":
            if rp.status != RecurringPaymentStatus.PAUSED:
                return Response({"detail": f"Cannot resume a {rp.status} order."}, status=409)
            rp.status = RecurringPaymentStatus.ACTIVE
            rp.consecutive_failures = 0
            # Resuming an order whose schedule lapsed while paused shouldn't
            # fire a burst of catch-up payments — resync to the next tick.
            if rp.next_run_at <= timezone.now():
                rp.next_run_at = timezone.now()
        elif action == "cancel":
            if rp.status == RecurringPaymentStatus.CANCELLED:
                return Response({"detail": "Already cancelled."}, status=409)
            rp.status = RecurringPaymentStatus.CANCELLED
        else:
            return Response({"detail": f"Unknown action {action}."}, status=404)

        rp.save(update_fields=["status", "consecutive_failures", "next_run_at", "updated_at"])
        return Response(RecurringPaymentSerializer(rp).data)
