from __future__ import annotations

from django.conf import settings
from drf_spectacular.utils import OpenApiResponse, extend_schema
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from .auth import IsDevice, hash_token, issue_token
from .engine import (
    IdempotencyConflict,
    InsufficientFunds,
    InvalidTransition,
    RefundError,
    default_engine,
)
from .gateways.base import PaymentAccepted, PaymentContractError, PaymentFailed
from .gateways.factory import live_mpesa_gateway
from .models import Device, Transaction, TransactionStatus, TransactionType
from .money import Currency, Money
from .orchestrator import OrchestratorContext, default_orchestrator
from .production_gates import demo_wallet_funding_allowed
from .risk import RiskDenied
from .serializers import (
    DevicePushTokenSerializer,
    DeviceRegisterResponseSerializer,
    DeviceRegisterSerializer,
    RefundRequestSerializer,
    ReverseRequestSerializer,
    TopUpRequestSerializer,
    TransactionSerializer,
    TransferRequestSerializer,
    WalletSerializer,
    WithdrawalRequestSerializer,
)
from .webhook_auth import assert_mpesa_stk_webhook_trusted

# Demo opening balance — ONLY when ALLOW_DEMO_WALLET_FUNDING is true (never production).
DEMO_OPENING_BALANCE = Money.major(2847500, Currency.TZS)


def _idempotency_key(request) -> str | None:
    return request.headers.get("Idempotency-Key")


def _orch_ctx(request) -> OrchestratorContext:
    device = getattr(request, "auth", None)
    return OrchestratorContext(
        actor=getattr(device, "owner", "") or "anonymous",
        device_id=getattr(device, "device_id", "") or "",
        ip=request.META.get("REMOTE_ADDR"),
    )


@extend_schema(
    tags=["auth"],
    request=DeviceRegisterSerializer,
    responses={201: DeviceRegisterResponseSerializer, 200: DeviceRegisterResponseSerializer},
    summary="Register a device and mint a bound token",
)
class DeviceRegisterView(APIView):
    """POST /api/v1/auth/device/register — bind a device and mint a token.

    Open (no token yet). Idempotent per `device_id`: re-registering rotates the
    token and keeps the same owner/wallet. Demo funding only when
    `ALLOW_DEMO_WALLET_FUNDING` is true (forbidden in production).
    """

    authentication_classes: list = []
    permission_classes = [AllowAny]
    throttle_scope = "device_register"

    def post(self, request):
        s = DeviceRegisterSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data

        token = issue_token()
        device, created = Device.objects.get_or_create(
            device_id=d["device_id"],
            defaults={"owner": f"dev_{d['device_id'][:16]}"},
        )
        device.token_hash = hash_token(token)
        if d.get("label"):
            device.label = d["label"]
        if d.get("platform"):
            device.platform = d["platform"]
        if d.get("push_token"):
            device.push_token = d["push_token"]
        device.save()

        if created and demo_wallet_funding_allowed():
            default_orchestrator().open_wallet(
                device.owner,
                DEMO_OPENING_BALANCE,
                OrchestratorContext(actor=device.owner, device_id=device.device_id),
            )

        balance = default_engine().wallet_balance(device.owner, Currency.TZS)
        return Response(
            {
                "token": token,
                "device_id": device.device_id,
                "owner": device.owner,
                "currency": "TZS",
                "balance_minor": balance.minor_units,
                "balance_display": balance.format(),
            },
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


@extend_schema(
    tags=["auth"],
    request=DevicePushTokenSerializer,
    summary="Update push notification token for the authenticated device",
)
class DevicePushTokenView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        s = DevicePushTokenSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        device = request.auth
        device.push_token = s.validated_data["push_token"]
        device.save(update_fields=["push_token", "last_seen_at"])
        return Response({"push_token_registered": True})


@extend_schema(tags=["wallet"], responses=WalletSerializer, summary="Wallet balance + recent transactions")
class WalletView(APIView):
    """GET /api/v1/payments/wallet — the authenticated device's balance + recent
    transactions. This is what the mobile `RestWalletRepository.load()` reads."""

    permission_classes = [IsDevice]

    def get(self, request):
        owner = request.auth.owner
        balance = default_engine().wallet_balance(owner, Currency.TZS)
        txns = Transaction.objects.filter(owner=owner)[:50]
        return Response(
            {
                "owner": owner,
                "currency": "TZS",
                "balance_minor": balance.minor_units,
                "balance_display": balance.format(),
                "transactions": TransactionSerializer(txns, many=True).data,
            }
        )


@extend_schema(
    tags=["payments"],
    request=TopUpRequestSerializer,
    responses={201: TransactionSerializer, 200: TransactionSerializer},
    summary="Initiate an M-Pesa STK-push top-up",
)
class TopUpView(APIView):
    """POST /api/v1/payments/topups — initiate an M-Pesa STK-push top-up.

    Returns a `processing` transaction; the final state arrives via the M-Pesa
    webhook. Requires an `Idempotency-Key` header and a device token.
    """

    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request):
        key = _idempotency_key(request)
        if not key:
            return Response({"detail": "Idempotency-Key header is required."}, status=400)
        s = TopUpRequestSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        amount = Money(d["amount_minor"], Currency.from_code(d["currency"]))
        try:
            outcome = default_orchestrator().initiate_topup(
                ctx=_orch_ctx(request),
                owner=request.auth.owner, amount=amount, msisdn=d["msisdn"],
                operator=d["operator"], idempotency_key=key, note=d["note"],
            )
        except IdempotencyConflict:
            return Response({"detail": "Idempotency-Key reused with a different payload."}, status=409)
        except RiskDenied as exc:
            return Response({"detail": str(exc), "code": exc.decision.code}, status=403)
        except PaymentContractError as exc:
            return Response({"detail": str(exc)}, status=422)
        return Response(
            TransactionSerializer(outcome.transaction).data,
            status=status.HTTP_200_OK if outcome.replayed else status.HTTP_201_CREATED,
        )


@extend_schema(
    tags=["payments"],
    request=TransferRequestSerializer,
    responses={201: TransactionSerializer, 200: TransactionSerializer},
    summary="Send money to a recipient",
)
class TransferView(APIView):
    """POST /api/v1/payments/transfers — send money to a recipient."""

    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request):
        key = _idempotency_key(request)
        if not key:
            return Response({"detail": "Idempotency-Key header is required."}, status=400)
        s = TransferRequestSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        amount = Money(d["amount_minor"], Currency.from_code(d["currency"]))
        try:
            outcome = default_orchestrator().initiate_transfer(
                ctx=_orch_ctx(request),
                owner=request.auth.owner, amount=amount, method_kind=d["method_kind"],
                method_ref=d["method_ref"], operator=d["operator"],
                counterparty=d["counterparty"], idempotency_key=key, note=d["note"],
            )
        except IdempotencyConflict:
            return Response({"detail": "Idempotency-Key reused with a different payload."}, status=409)
        except RiskDenied as exc:
            return Response({"detail": str(exc), "code": exc.decision.code}, status=403)
        except PaymentContractError as exc:
            return Response({"detail": str(exc)}, status=422)
        return Response(
            TransactionSerializer(outcome.transaction).data,
            status=status.HTTP_200_OK if outcome.replayed else status.HTTP_201_CREATED,
        )


@extend_schema(
    tags=["payments"],
    request=WithdrawalRequestSerializer,
    responses={201: TransactionSerializer, 200: TransactionSerializer},
    summary="Request a withdrawal (hold → rail payout)",
)
class WithdrawalView(APIView):
    """POST /api/v1/payments/withdrawals — request a withdrawal.

    Lifecycle: pending → approved (ledger hold) → processing → succeeded/failed.
    When `WITHDRAWAL_AUTO_APPROVE` is true, approve+process run inline.
    """

    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request):
        key = _idempotency_key(request)
        if not key:
            return Response({"detail": "Idempotency-Key header is required."}, status=400)
        s = WithdrawalRequestSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        amount = Money(d["amount_minor"], Currency.from_code(d["currency"]))
        try:
            outcome = default_orchestrator().initiate_withdrawal(
                ctx=_orch_ctx(request),
                owner=request.auth.owner,
                amount=amount,
                method_kind=d["method_kind"],
                method_ref=d["method_ref"],
                operator=d["operator"],
                counterparty=d["counterparty"],
                idempotency_key=key,
                note=d["note"],
            )
        except IdempotencyConflict:
            return Response({"detail": "Idempotency-Key reused with a different payload."}, status=409)
        except RiskDenied as exc:
            return Response({"detail": str(exc), "code": exc.decision.code}, status=403)
        except PaymentContractError as exc:
            return Response({"detail": str(exc)}, status=422)
        return Response(
            TransactionSerializer(outcome.transaction).data,
            status=status.HTTP_200_OK if outcome.replayed else status.HTTP_201_CREATED,
        )


@extend_schema(
    tags=["payments"],
    request=None,
    responses={200: TransactionSerializer},
    summary="Approve a pending withdrawal",
)
class WithdrawalApproveView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(pk=txn_id, owner=request.auth.owner, type=TransactionType.WITHDRAWAL)
        except Transaction.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        try:
            txn = default_orchestrator().approve_withdrawal(ctx=_orch_ctx(request), txn=txn)
        except InvalidTransition as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(TransactionSerializer(txn).data)


@extend_schema(
    tags=["payments"],
    request=None,
    responses={200: TransactionSerializer},
    summary="Reject a withdrawal",
)
class WithdrawalRejectView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(pk=txn_id, owner=request.auth.owner, type=TransactionType.WITHDRAWAL)
        except Transaction.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        reason = (request.data or {}).get("reason", "")
        try:
            txn = default_orchestrator().reject_withdrawal(
                ctx=_orch_ctx(request), txn=txn, reason=reason
            )
        except InvalidTransition as exc:
            return Response({"detail": str(exc)}, status=409)
        return Response(TransactionSerializer(txn).data)


@extend_schema(
    tags=["payments"],
    request=None,
    responses={200: TransactionSerializer},
    summary="Process an approved withdrawal",
)
class WithdrawalProcessView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(pk=txn_id, owner=request.auth.owner, type=TransactionType.WITHDRAWAL)
        except Transaction.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        try:
            outcome = default_orchestrator().process_withdrawal(ctx=_orch_ctx(request), txn=txn)
        except InvalidTransition as exc:
            return Response({"detail": str(exc)}, status=409)
        except PaymentContractError as exc:
            return Response({"detail": str(exc)}, status=422)
        return Response(TransactionSerializer(outcome.transaction).data)


@extend_schema(
    tags=["payments"],
    request=RefundRequestSerializer,
    responses={201: TransactionSerializer, 200: TransactionSerializer},
    summary="Refund a succeeded transaction (partial or full)",
)
class RefundView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request):
        key = _idempotency_key(request)
        if not key:
            return Response({"detail": "Idempotency-Key header is required."}, status=400)
        s = RefundRequestSerializer(data=request.data)
        s.is_valid(raise_exception=True)
        d = s.validated_data
        try:
            original = Transaction.objects.get(pk=d["original_transaction_id"], owner=request.auth.owner)
        except Transaction.DoesNotExist:
            return Response({"detail": "Original transaction not found."}, status=404)
        amount = Money(d["amount_minor"], Currency.from_code(d["currency"]))
        try:
            outcome = default_orchestrator().initiate_refund(
                ctx=_orch_ctx(request),
                owner=request.auth.owner,
                original=original,
                amount=amount,
                idempotency_key=key,
                note=d["note"],
            )
        except IdempotencyConflict:
            return Response({"detail": "Idempotency-Key reused with a different payload."}, status=409)
        except RiskDenied as exc:
            return Response({"detail": str(exc), "code": exc.decision.code}, status=403)
        except (RefundError, InsufficientFunds) as exc:
            return Response({"detail": str(exc)}, status=422)
        return Response(
            TransactionSerializer(outcome.transaction).data,
            status=status.HTTP_200_OK if outcome.replayed else status.HTTP_201_CREATED,
        )


@extend_schema(
    tags=["payments"],
    request=ReverseRequestSerializer,
    responses={201: TransactionSerializer, 200: TransactionSerializer},
    summary="Reverse a succeeded transaction via compensating journals",
)
class ReverseTransactionView(APIView):
    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, txn_id):
        key = _idempotency_key(request)
        if not key:
            return Response({"detail": "Idempotency-Key header is required."}, status=400)
        s = ReverseRequestSerializer(data=request.data or {})
        s.is_valid(raise_exception=True)
        try:
            original = Transaction.objects.get(pk=txn_id, owner=request.auth.owner)
        except Transaction.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        try:
            outcome = default_orchestrator().reverse_transaction(
                ctx=_orch_ctx(request),
                owner=request.auth.owner,
                original=original,
                idempotency_key=key,
                note=s.validated_data.get("note", ""),
            )
        except IdempotencyConflict:
            return Response({"detail": "Idempotency-Key reused with a different payload."}, status=409)
        except InvalidTransition as exc:
            return Response({"detail": str(exc)}, status=422)
        return Response(
            TransactionSerializer(outcome.transaction).data,
            status=status.HTTP_200_OK if outcome.replayed else status.HTTP_201_CREATED,
        )


@extend_schema(tags=["payments"], responses={200: TransactionSerializer}, summary="Fetch one transaction")
class TransactionDetailView(APIView):
    """GET /api/v1/payments/transactions/{id} — scoped to the device's owner."""

    permission_classes = [IsDevice]

    def get(self, request, txn_id):
        try:
            txn = Transaction.objects.get(pk=txn_id, owner=request.auth.owner)
        except Transaction.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        return Response(TransactionSerializer(txn).data)


@extend_schema(
    tags=["payments"],
    request=None,
    responses={200: TransactionSerializer},
    summary="Demo-complete a pending STK top-up (gated)",
)
class DemoTopUpCompleteView(APIView):
    """POST /api/v1/payments/topups/{id}/demo-complete

    Synthesizes a successful M-Pesa STK callback for a *pending* top-up owned by
    the calling device. Enabled only when `ALLOW_DEMO_STK` is true (defaults to
    DEBUG). Real Daraja webhooks still hit `/webhooks/mpesa/stk` unchanged.
    """

    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, txn_id):
        if not getattr(settings, "ALLOW_DEMO_STK", False):
            return Response(
                {"detail": "Demo STK settle is disabled on this environment."},
                status=403,
            )
        try:
            txn = Transaction.objects.get(pk=txn_id, owner=request.auth.owner)
        except Transaction.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if txn.type != TransactionType.TOP_UP:
            return Response({"detail": "Only top-ups can be demo-completed."}, status=422)
        if txn.status != TransactionStatus.PROCESSING:
            return Response(
                {"detail": f"Transaction is already {txn.status}."},
                status=409,
            )
        if not txn.provider_ref:
            return Response({"detail": "Top-up has no provider_ref to settle."}, status=422)

        callback = {
            "Body": {
                "stkCallback": {
                    "CheckoutRequestID": txn.provider_ref,
                    "ResultCode": 0,
                    "ResultDesc": "Demo STK success",
                }
            }
        }
        default_orchestrator().settle_mpesa_stk_callback(callback, ctx=_orch_ctx(request))
        txn.refresh_from_db()
        return Response(TransactionSerializer(txn).data)


@extend_schema(
    tags=["payments"],
    request=None,
    responses={200: TransactionSerializer},
    summary="Poll Daraja STK query and settle if complete",
)
class PollTopUpStatusView(APIView):
    """POST /api/v1/payments/topups/{id}/poll-status

    Queries Daraja STK push status for a pending top-up and settles the ledger
    when the customer has completed (or cancelled) the prompt. Use this when
    `MPESA_CALLBACK_BASE_URL` is not publicly reachable (local sandbox without
    ngrok). Idempotent once the transaction is terminal.
    """

    permission_classes = [IsDevice]
    throttle_scope = "money_write"

    def post(self, request, txn_id):
        try:
            txn = Transaction.objects.get(pk=txn_id, owner=request.auth.owner)
        except Transaction.DoesNotExist:
            return Response({"detail": "Not found."}, status=404)
        if txn.type != TransactionType.TOP_UP:
            return Response({"detail": "Only top-ups can be polled."}, status=422)
        if txn.status != TransactionStatus.PROCESSING:
            return Response(TransactionSerializer(txn).data)
        if not txn.provider_ref:
            return Response({"detail": "Top-up has no provider_ref to poll."}, status=422)

        gateway = live_mpesa_gateway()
        if gateway is None:
            return Response(
                {
                    "detail": (
                        "Live Daraja is not configured. Set MPESA_CONSUMER_KEY / "
                        "SECRET (and sandbox passkey) or use demo-complete."
                    )
                },
                status=503,
            )

        result = gateway.status(txn.provider_ref)
        if isinstance(result, PaymentAccepted):
            callback = {
                "Body": {
                    "stkCallback": {
                        "CheckoutRequestID": txn.provider_ref,
                        "ResultCode": 0,
                        "ResultDesc": "STK query success",
                    }
                }
            }
            default_orchestrator().settle_mpesa_stk_callback(callback, ctx=_orch_ctx(request))
        elif isinstance(result, PaymentFailed):
            callback = {
                "Body": {
                    "stkCallback": {
                        "CheckoutRequestID": txn.provider_ref,
                        "ResultCode": int(result.code) if str(result.code).isdigit() else 1,
                        "ResultDesc": result.message or "STK query failed",
                    }
                }
            }
            default_orchestrator().settle_mpesa_stk_callback(callback, ctx=_orch_ctx(request))

        txn.refresh_from_db()
        return Response(TransactionSerializer(txn).data)


@extend_schema(
    tags=["webhooks"],
    request=None,
    responses=OpenApiResponse(description="Daraja acknowledgement `{ResultCode, ResultDesc}`"),
    summary="M-Pesa STK result callback",
)
class MpesaStkWebhookView(APIView):
    """POST /api/v1/payments/webhooks/mpesa/stk — Daraja STK result callback.

    Unauthenticated (Safaricom cannot present a device token). Trust is
    layered: optional IP allow-list + shared secret header, structural
    validation of `Body.stkCallback`, then match `CheckoutRequestID` to a
    pending txn. Always acknowledges with the Daraja-expected body so retries
    stop once we've durably captured the event.
    """

    authentication_classes: list = []
    permission_classes = [AllowAny]

    def post(self, request):
        assert_mpesa_stk_webhook_trusted(request)
        default_orchestrator().settle_mpesa_stk_callback(
            request.data,
            ctx=OrchestratorContext(actor="mpesa-webhook", ip=request.META.get("REMOTE_ADDR")),
        )
        return Response({"ResultCode": 0, "ResultDesc": "Accepted"})
