"""Split bills — organizer already paid, friends each owe a share.

A BillSplit groups several MoneyRequests (one per participant). Paying a
share goes through the existing MoneyRequestActionView `pay` action; this
module only owns creating the split and rolling its status up to `settled`
once every share is paid (see `refresh_bill_status`, called from
p2p_views.MoneyRequestActionView).
"""
from __future__ import annotations

from django.db import transaction as db_transaction
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .models import (
    CURRENCY_CHOICES,
    BillSplit,
    BillSplitStatus,
    Device,
    MoneyRequest,
    MoneyRequestStatus,
)
from .p2p_views import MoneyRequestSerializer, _display_name_for
from .people import normalize_phone
from .risk import check_request_spam


def refresh_bill_status(bill: BillSplit) -> BillSplit:
    """Call after any share's status changes. Settles the bill once every
    non-cancelled share is paid (a decline/cancel doesn't block settlement —
    it just means that friend never pays their part)."""
    shares = list(bill.shares.all())
    live = [s for s in shares if s.status != MoneyRequestStatus.CANCELLED]
    if live and all(s.status == MoneyRequestStatus.PAID for s in live):
        if bill.status != BillSplitStatus.SETTLED:
            bill.status = BillSplitStatus.SETTLED
            bill.save(update_fields=["status", "updated_at"])
    return bill


class SplitParticipantSerializer(serializers.Serializer):
    phone_number = serializers.CharField(max_length=20, required=False, allow_blank=True, default="")
    payer = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")
    # Only used for split_type="custom" — ignored (must sum to total) otherwise.
    amount_minor = serializers.IntegerField(required=False, allow_null=True, min_value=1)

    def validate(self, attrs):
        if not attrs.get("phone_number") and not attrs.get("payer"):
            raise serializers.ValidationError("Each participant needs phone_number or payer.")
        return attrs


class BillSplitCreateSerializer(serializers.Serializer):
    title = serializers.CharField(max_length=128)
    emoji = serializers.CharField(max_length=16, required=False, allow_blank=True, default="")
    currency = serializers.ChoiceField(choices=CURRENCY_CHOICES, default="TZS")
    total_amount_minor = serializers.IntegerField(min_value=1)
    split_type = serializers.ChoiceField(choices=["even", "custom"], default="even")
    participants = SplitParticipantSerializer(many=True)

    def validate_participants(self, value):
        if not value:
            raise serializers.ValidationError("Add at least one participant.")
        if len(value) > 50:
            raise serializers.ValidationError("Too many participants (max 50).")
        return value

    def validate(self, attrs):
        if attrs["split_type"] == "custom":
            missing = [p for p in attrs["participants"] if not p.get("amount_minor")]
            if missing:
                raise serializers.ValidationError("Custom splits need amount_minor for every participant.")
            total_shares = sum(p["amount_minor"] for p in attrs["participants"])
            if total_shares > attrs["total_amount_minor"]:
                raise serializers.ValidationError(
                    "Participant shares add up to more than total_amount_minor."
                )
        return attrs


class BillSplitSerializer(serializers.ModelSerializer):
    organizer_name = serializers.SerializerMethodField()
    shares = MoneyRequestSerializer(many=True, read_only=True)
    paid_amount_minor = serializers.SerializerMethodField()

    class Meta:
        model = BillSplit
        fields = [
            "id", "organizer", "organizer_name", "title", "emoji",
            "total_amount_minor", "currency", "status",
            "paid_amount_minor", "shares", "created_at", "updated_at",
        ]

    def get_organizer_name(self, obj: BillSplit) -> str:
        return _display_name_for(obj.organizer)

    def get_paid_amount_minor(self, obj: BillSplit) -> int:
        return sum(s.amount_minor for s in obj.shares.all() if s.status == MoneyRequestStatus.PAID)


def _even_shares(total_minor: int, n: int) -> list[int]:
    """Split `total_minor` into `n` integer parts that sum exactly to it —
    the remainder (unavoidable with integer minor units) goes one unit at a
    time to the first shares so no cent is created or lost."""
    base, remainder = divmod(total_minor, n)
    return [base + (1 if i < remainder else 0) for i in range(n)]


@extend_schema(
    tags=["social-payments"],
    request=BillSplitCreateSerializer,
    responses={201: BillSplitSerializer, 200: BillSplitSerializer(many=True)},
    summary="Create (POST) or list (GET) split bills",
)
class BillSplitListCreateView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def get(self, request):
        owner = request.auth.owner
        organized = BillSplit.objects.filter(organizer=owner)
        owing = BillSplit.objects.filter(shares__payer=owner).distinct()
        return Response(
            {
                "organized": BillSplitSerializer(organized, many=True).data,
                "owing": BillSplitSerializer(owing, many=True).data,
            }
        )

    def post(self, request):
        s = BillSplitCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        organizer = request.auth.owner

        # Resolve every participant to a wallet owner before creating anything.
        resolved: list[tuple[str, int | None]] = []
        for p in d["participants"]:
            if p.get("phone_number"):
                target = Device.objects.filter(phone_number=normalize_phone(p["phone_number"])).first()
                if target is None:
                    return Response(
                        {"detail": f"No TAIFA wallet is linked to {p['phone_number']}."}, status=404
                    )
                payer = target.owner
            else:
                payer = p["payer"]
                if not Device.objects.filter(owner=payer).exists():
                    return Response({"detail": f"No wallet found for {payer}."}, status=404)
            if payer == organizer:
                return Response({"detail": "You cannot split a bill with yourself."}, status=422)
            resolved.append((payer, p.get("amount_minor")))

        if len({payer for payer, _ in resolved}) != len(resolved):
            return Response({"detail": "Duplicate participant in the split."}, status=422)

        for payer, _ in resolved:
            spam_decision = check_request_spam(organizer, payer)
            if not spam_decision.allowed:
                return Response(
                    {"detail": f"{spam_decision.message} ({payer})", "code": spam_decision.code},
                    status=429,
                )

        if d["split_type"] == "even":
            amounts = _even_shares(d["total_amount_minor"], len(resolved) + 1)[: len(resolved)]
        else:
            amounts = [amt for _, amt in resolved]

        with db_transaction.atomic():
            bill = BillSplit.objects.create(
                organizer=organizer,
                title=d["title"],
                emoji=d.get("emoji", ""),
                total_amount_minor=d["total_amount_minor"],
                currency=d["currency"],
            )
            for (payer, _), amount_minor in zip(resolved, amounts):
                MoneyRequest.objects.create(
                    requester=organizer,
                    payer=payer,
                    amount_minor=amount_minor,
                    currency=d["currency"],
                    note=d["title"],
                    emoji=d.get("emoji", ""),
                    bill=bill,
                )
        bill.refresh_from_db()
        return Response(BillSplitSerializer(bill).data, status=status.HTTP_201_CREATED)


@extend_schema(tags=["social-payments"], responses={200: BillSplitSerializer}, summary="View one split bill")
class BillSplitDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, bill_id):
        owner = request.auth.owner
        try:
            bill = BillSplit.objects.get(pk=bill_id)
        except BillSplit.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if owner != bill.organizer and not bill.shares.filter(payer=owner).exists():
            return Response({"detail": "Not found."}, status=404)
        return Response(BillSplitSerializer(bill).data)


@extend_schema(
    tags=["social-payments"],
    request=None,
    responses={200: BillSplitSerializer},
    summary="Cancel a split bill (organizer only) — cancels every unpaid share",
)
class BillSplitCancelView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, bill_id):
        try:
            bill = BillSplit.objects.get(pk=bill_id, organizer=request.auth.owner)
        except BillSplit.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if bill.status != BillSplitStatus.OPEN:
            return Response({"detail": f"Bill is already {bill.status}."}, status=409)
        with db_transaction.atomic():
            bill.shares.filter(status=MoneyRequestStatus.PENDING).update(status=MoneyRequestStatus.CANCELLED)
            bill.status = BillSplitStatus.CANCELLED
            bill.save(update_fields=["status", "updated_at"])
        return Response(BillSplitSerializer(bill).data)
