"""Ziina-style social payments: payment links, money requests, receive-QR.

A payment link (`/pay/<slug>`) is a shareable receive-money URL — fixed or
open amount, note + emoji, one-time or reusable. A money request is a P2P
"please pay me" that lands in the payer's inbox. Both settle through
`TransactionEngine.initiate_p2p` — instant, free, ledger-backed.
"""
from __future__ import annotations

import secrets

from django.conf import settings
from django.db import transaction as db_transaction
from django.utils import timezone
from drf_spectacular.utils import extend_schema
from rest_framework import serializers, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice
from .engine import IdempotencyConflict, InvalidTransition
from .models import (
    CURRENCY_CHOICES,
    Device,
    MoneyRequest,
    MoneyRequestStatus,
    PaymentLink,
    PaymentLinkStatus,
)
from .money import Currency, Money
from .notifications import notify
from .orchestrator import OrchestratorContext, default_orchestrator
from .people import normalize_phone
from .risk import RiskDenied, check_request_spam
from .serializers import TransactionSerializer

_SLUG_ALPHABET = "abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789"


def _new_slug(length: int = 10) -> str:
    return "".join(secrets.choice(_SLUG_ALPHABET) for _ in range(length))


def _orch_ctx(request) -> OrchestratorContext:
    device = getattr(request, "auth", None)
    return OrchestratorContext(
        actor=getattr(device, "owner", "") or "anonymous",
        device_id=getattr(device, "device_id", "") or "",
        ip=request.META.get("REMOTE_ADDR"),
    )


def _idempotency_key(request) -> str | None:
    return request.headers.get("Idempotency-Key")


def _expire_if_due(link: PaymentLink) -> PaymentLink:
    if (
        link.status == PaymentLinkStatus.ACTIVE
        and link.expires_at is not None
        and link.expires_at <= timezone.now()
    ):
        link.status = PaymentLinkStatus.EXPIRED
        link.save(update_fields=["status", "updated_at"])
    return link


class PaymentLinkCreateSerializer(serializers.Serializer):
    amount_minor = serializers.IntegerField(required=False, allow_null=True, min_value=1)
    currency = serializers.ChoiceField(choices=CURRENCY_CHOICES, default="TZS")
    note = serializers.CharField(max_length=255, required=False, allow_blank=True, default="")
    emoji = serializers.CharField(max_length=16, required=False, allow_blank=True, default="")
    display_name = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")
    single_use = serializers.BooleanField(default=False)
    expires_in_hours = serializers.IntegerField(required=False, allow_null=True, min_value=1, max_value=24 * 90)


class PaymentLinkSerializer(serializers.ModelSerializer):
    url = serializers.SerializerMethodField()

    class Meta:
        model = PaymentLink
        fields = [
            "id", "slug", "url", "owner", "display_name", "amount_minor", "currency",
            "note", "emoji", "status", "single_use", "expires_at", "fee_bps",
            "total_paid_minor", "payment_count", "created_at",
        ]

    def get_url(self, obj: PaymentLink) -> str:
        return f"/api/v1/payments/pay/{obj.slug}"


class PaymentLinkPublicSerializer(serializers.ModelSerializer):
    """What a payer sees before paying — no owner internals beyond display name."""

    payee = serializers.SerializerMethodField()

    class Meta:
        model = PaymentLink
        fields = ["slug", "payee", "amount_minor", "currency", "note", "emoji", "status", "single_use"]

    def get_payee(self, obj: PaymentLink) -> str:
        return obj.display_name or obj.owner


class PayLinkSerializer(serializers.Serializer):
    # Required only for open-amount links; ignored (must match if sent) on fixed.
    amount_minor = serializers.IntegerField(required=False, allow_null=True, min_value=1)


class MoneyRequestCreateSerializer(serializers.Serializer):
    # Exactly one of these must identify the payer — a raw owner handle (legacy /
    # internal use) or a phone number (the normal human-facing path).
    payer = serializers.CharField(max_length=128, required=False, allow_blank=True, default="")
    payer_phone = serializers.CharField(max_length=20, required=False, allow_blank=True, default="")
    amount_minor = serializers.IntegerField(min_value=1)
    currency = serializers.ChoiceField(choices=CURRENCY_CHOICES, default="TZS")
    note = serializers.CharField(max_length=255, required=False, allow_blank=True, default="")
    emoji = serializers.CharField(max_length=16, required=False, allow_blank=True, default="")

    def validate(self, attrs):
        if not attrs.get("payer") and not attrs.get("payer_phone"):
            raise serializers.ValidationError("Provide either payer or payer_phone.")
        return attrs


class MoneyRequestSerializer(serializers.ModelSerializer):
    transaction_id = serializers.SerializerMethodField()
    requester_name = serializers.SerializerMethodField()
    payer_name = serializers.SerializerMethodField()

    class Meta:
        model = MoneyRequest
        fields = [
            "id", "requester", "requester_name", "payer", "payer_name",
            "amount_minor", "currency", "note", "emoji",
            "status", "transaction_id", "created_at", "responded_at",
        ]

    def get_transaction_id(self, obj: MoneyRequest) -> str | None:
        return str(obj.transaction_id) if obj.transaction_id else None

    def get_requester_name(self, obj: MoneyRequest) -> str:
        return _display_name_for(obj.requester)

    def get_payer_name(self, obj: MoneyRequest) -> str:
        return _display_name_for(obj.payer)


def _display_name_for(owner: str) -> str:
    device = Device.objects.filter(owner=owner).order_by("-last_seen_at").first()
    return (device.label if device else "") or owner


@extend_schema(
    tags=["social-payments"],
    request=PaymentLinkCreateSerializer,
    responses={201: PaymentLinkSerializer, 200: PaymentLinkSerializer(many=True)},
    summary="Create (POST) or list (GET) my payment links",
)
class PaymentLinkListCreateView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def get(self, request):
        links = PaymentLink.objects.filter(owner=request.auth.owner)[:100]
        return Response({"links": PaymentLinkSerializer(links, many=True).data})

    def post(self, request):
        s = PaymentLinkCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        expires_at = None
        if d.get("expires_in_hours"):
            expires_at = timezone.now() + timezone.timedelta(hours=d["expires_in_hours"])
        device: Device = request.auth
        link = PaymentLink.objects.create(
            slug=_new_slug(),
            owner=request.auth.owner,
            display_name=d.get("display_name", ""),
            amount_minor=d.get("amount_minor"),
            currency=d["currency"],
            note=d.get("note", ""),
            emoji=d.get("emoji", ""),
            single_use=d["single_use"],
            expires_at=expires_at,
            fee_bps=settings.PAYMENTS_MERCHANT_FEE_BPS if device.is_merchant else 0,
        )
        return Response(PaymentLinkSerializer(link).data, status=status.HTTP_201_CREATED)


@extend_schema(
    tags=["social-payments"],
    request=None,
    responses={200: PaymentLinkSerializer},
    summary="Pause or resume one of my payment links",
    operation_id="payments_link_action",
)
class PaymentLinkStatusView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, link_id, action):
        try:
            link = PaymentLink.objects.get(pk=link_id, owner=request.auth.owner)
        except PaymentLink.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if action == "pause" and link.status == PaymentLinkStatus.ACTIVE:
            link.status = PaymentLinkStatus.PAUSED
        elif action == "resume" and link.status == PaymentLinkStatus.PAUSED:
            link.status = PaymentLinkStatus.ACTIVE
        else:
            return Response({"detail": f"Cannot {action} a {link.status} link."}, status=409)
        link.save(update_fields=["status", "updated_at"])
        return Response(PaymentLinkSerializer(link).data)


@extend_schema(
    tags=["social-payments"],
    responses={200: PaymentLinkPublicSerializer},
    summary="Public payment-link info (what a payer sees before paying)",
)
class PaymentLinkPublicView(APIView):
    authentication_classes: list = []
    permission_classes = [AllowAny]

    def get(self, request, slug):
        try:
            link = _expire_if_due(PaymentLink.objects.get(slug=slug))
        except PaymentLink.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(PaymentLinkPublicSerializer(link).data)


@extend_schema(
    tags=["social-payments"],
    request=PayLinkSerializer,
    responses={201: TransactionSerializer},
    summary="Pay a payment link from my wallet (instant P2P)",
)
class PayLinkView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, slug):
        key = _idempotency_key(request)
        if not key:
            return Response({"detail": "Idempotency-Key header is required."}, status=400)
        s = PayLinkSerializer(data=request.data or {})
        s.is_valid(raise_exception=True)
        try:
            link = _expire_if_due(PaymentLink.objects.get(slug=slug))
        except PaymentLink.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if link.status != PaymentLinkStatus.ACTIVE:
            return Response({"detail": f"Link is {link.status}."}, status=409)

        amount_minor = link.amount_minor or s.validated_data.get("amount_minor")
        if not amount_minor:
            return Response({"detail": "This link needs an amount_minor."}, status=422)
        if link.amount_minor and s.validated_data.get("amount_minor") not in (None, link.amount_minor):
            return Response({"detail": "Amount does not match this link."}, status=422)

        payer = request.auth.owner
        if payer == link.owner:
            return Response({"detail": "You cannot pay your own link."}, status=422)

        amount = Money(amount_minor, Currency.from_code(link.currency))
        fee = Money(amount.minor_units * link.fee_bps // 10_000, amount.currency) if link.fee_bps else None
        note_bits = [b for b in (link.emoji, link.note) if b]
        try:
            outcome = default_orchestrator().initiate_p2p(
                ctx=_orch_ctx(request),
                payer=payer,
                payee=link.owner,
                amount=amount,
                idempotency_key=key,
                note=" ".join(note_bits),
                counterparty_label=link.display_name or link.owner,
                fee=fee,
            )
        except IdempotencyConflict:
            return Response({"detail": "Idempotency-Key reused with a different payload."}, status=409)
        except RiskDenied as exc:
            return Response({"detail": str(exc), "code": exc.decision.code}, status=403)
        except InvalidTransition as exc:
            return Response({"detail": str(exc)}, status=422)

        txn = outcome.transaction
        if not outcome.replayed and txn.status == "succeeded":
            with db_transaction.atomic():
                locked = PaymentLink.objects.select_for_update().get(pk=link.pk)
                locked.total_paid_minor += amount.minor_units
                locked.payment_count += 1
                if locked.single_use:
                    locked.status = PaymentLinkStatus.COMPLETED
                locked.save(update_fields=["total_paid_minor", "payment_count", "status", "updated_at"])
            notify(
                owner=link.owner,
                title=f"{link.emoji or '💸'} Payment received",
                body=f"You received {amount.format()} from {_display_name_for(payer)}",
                data={"type": "payment_link_paid", "payment_link_id": str(link.id)},
            )
        return Response(
            TransactionSerializer(txn).data,
            status=status.HTTP_200_OK if outcome.replayed else status.HTTP_201_CREATED,
        )


@extend_schema(
    tags=["social-payments"],
    request=MoneyRequestCreateSerializer,
    responses={201: MoneyRequestSerializer, 200: MoneyRequestSerializer(many=True)},
    summary="Create (POST) or list (GET) money requests — sent and received",
)
class MoneyRequestListCreateView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def get(self, request):
        owner = request.auth.owner
        sent = MoneyRequest.objects.filter(requester=owner)[:50]
        received = MoneyRequest.objects.filter(payer=owner)[:50]
        return Response(
            {
                "sent": MoneyRequestSerializer(sent, many=True).data,
                "received": MoneyRequestSerializer(received, many=True).data,
            }
        )

    def post(self, request):
        s = MoneyRequestCreateSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        requester = request.auth.owner

        if d.get("payer_phone"):
            phone = normalize_phone(d["payer_phone"])
            target = Device.objects.filter(phone_number=phone).first()
            if target is None:
                return Response({"detail": "No TAIFA wallet is linked to that number."}, status=404)
            payer = target.owner
        else:
            payer = d["payer"]
            if not Device.objects.filter(owner=payer).exists():
                return Response({"detail": "No wallet found for that payer."}, status=404)

        if payer == requester:
            return Response({"detail": "You cannot request money from yourself."}, status=422)

        spam_decision = check_request_spam(requester, payer)
        if not spam_decision.allowed:
            return Response({"detail": spam_decision.message, "code": spam_decision.code}, status=429)

        req = MoneyRequest.objects.create(
            requester=requester,
            payer=payer,
            amount_minor=d["amount_minor"],
            currency=d["currency"],
            note=d.get("note", ""),
            emoji=d.get("emoji", ""),
        )
        amount_display = Money(d["amount_minor"], Currency.from_code(d["currency"])).format()
        notify(
            owner=payer,
            title=f"{d.get('emoji', '') or '💰'} Money request",
            body=f"{_display_name_for(requester)} requested {amount_display}",
            data={"type": "money_request", "money_request_id": str(req.id)},
        )
        return Response(MoneyRequestSerializer(req).data, status=status.HTTP_201_CREATED)


@extend_schema(
    tags=["social-payments"],
    request=None,
    responses={200: MoneyRequestSerializer},
    summary="Pay, decline (payer) or cancel (requester) a money request",
    operation_id="payments_request_action",
)
class MoneyRequestActionView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, request_id, action):
        owner = request.auth.owner
        try:
            req = MoneyRequest.objects.get(pk=request_id)
        except MoneyRequest.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if owner not in (req.requester, req.payer):
            return Response({"detail": "Not found."}, status=404)

        if action == "cancel":
            if owner != req.requester:
                return Response({"detail": "Only the requester can cancel."}, status=403)
            if req.status != MoneyRequestStatus.PENDING:
                return Response({"detail": f"Request is already {req.status}."}, status=409)
            req.status = MoneyRequestStatus.CANCELLED
            req.responded_at = timezone.now()
            req.save(update_fields=["status", "responded_at", "updated_at"])
            return Response(MoneyRequestSerializer(req).data)

        if owner != req.payer:
            return Response({"detail": "Only the payer can respond."}, status=403)
        if req.status != MoneyRequestStatus.PENDING:
            return Response({"detail": f"Request is already {req.status}."}, status=409)

        if action == "decline":
            req.status = MoneyRequestStatus.DECLINED
            req.responded_at = timezone.now()
            req.save(update_fields=["status", "responded_at", "updated_at"])
            return Response(MoneyRequestSerializer(req).data)

        if action == "pay":
            key = _idempotency_key(request)
            if not key:
                return Response({"detail": "Idempotency-Key header is required."}, status=400)
            amount = Money(req.amount_minor, Currency.from_code(req.currency))
            note_bits = [b for b in (req.emoji, req.note) if b]
            try:
                outcome = default_orchestrator().initiate_p2p(
                    ctx=_orch_ctx(request),
                    payer=owner,
                    payee=req.requester,
                    amount=amount,
                    idempotency_key=key,
                    note=" ".join(note_bits),
                    counterparty_label=req.requester,
                )
            except IdempotencyConflict:
                return Response({"detail": "Idempotency-Key reused with a different payload."}, status=409)
            except RiskDenied as exc:
                return Response({"detail": str(exc), "code": exc.decision.code}, status=403)
            except InvalidTransition as exc:
                return Response({"detail": str(exc)}, status=422)
            txn = outcome.transaction
            if txn.status == "succeeded":
                req.status = MoneyRequestStatus.PAID
                req.transaction = txn
                req.responded_at = timezone.now()
                req.save(update_fields=["status", "transaction", "responded_at", "updated_at"])
                if req.bill_id:
                    # Local import: bill_views imports from this module too;
                    # deferring avoids a circular import at load time.
                    from .bill_views import refresh_bill_status

                    refresh_bill_status(req.bill)
                notify(
                    owner=req.requester,
                    title="✅ Request paid",
                    body=f"{_display_name_for(owner)} paid your request for {amount.format()}",
                    data={"type": "money_request_paid", "money_request_id": str(req.id)},
                )
            else:
                return Response({"detail": "Insufficient balance.", "transaction": TransactionSerializer(txn).data}, status=422)
            return Response(MoneyRequestSerializer(req).data)

        return Response({"detail": f"Unknown action {action}."}, status=404)


@extend_schema(
    tags=["social-payments"],
    responses={200: PaymentLinkSerializer},
    summary="My receive-QR: a reusable open-amount payment link + QR payload",
)
class ReceiveQrView(APIView):
    """Returns the device owner's standing "receive" link (created on first
    call) plus the payload a client should encode as a QR code. Scanning wallet
    resolves the slug via the public link endpoint and pays it."""

    permission_classes = [IsDevice]

    def get(self, request):
        owner = request.auth.owner
        link = (
            PaymentLink.objects.filter(
                owner=owner, single_use=False, amount_minor__isnull=True,
                status=PaymentLinkStatus.ACTIVE, expires_at__isnull=True,
            )
            .order_by("created_at")
            .first()
        )
        if link is None:
            device: Device = request.auth
            link = PaymentLink.objects.create(
                slug=_new_slug(),
                owner=owner,
                currency="TZS",
                fee_bps=settings.PAYMENTS_MERCHANT_FEE_BPS if device.is_merchant else 0,
            )
        data = PaymentLinkSerializer(link).data
        data["qr_payload"] = f"taifa://pay/{link.slug}"
        return Response(data)
