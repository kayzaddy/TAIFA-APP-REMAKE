from __future__ import annotations

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from taifa_merchant.application.payment_services import PaymentAcceptanceService
from taifa_merchant.application.services import MerchantAppError
from taifa_merchant.domain.payment_enums import QRType
from taifa_merchant.presentation.auth import (
    HasMerchantPermission,
    IsMerchantAuthenticated,
    MerchantJWTAuthentication,
    MerchantPrincipal,
    require_merchant_context,
)
from taifa_merchant.presentation.payment_serializers import (
    PaymentLinkCreateSerializer,
    PaymentLinkSerializer,
    QRCreateSerializer,
    QRSerializer,
    ReceiptSerializer,
    ReceiptShareSerializer,
    RefundSerializer,
    RefundSerializerOut,
    SoftposConfirmSerializer,
    SoftposSessionSerializer,
    TerminalSerializer,
    TransactionSerializer,
)
from taifa_merchant.presentation.views import _handle_app_error


def _tx_response(tx, receipt=None) -> dict:
    data = {"transaction": TransactionSerializer(tx).data}
    if receipt:
        data["receipt"] = ReceiptSerializer(receipt).data
    return data


class TerminalRegisterView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:accept"

    def post(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        device_id = request.data.get("device_id")
        if not device_id:
            return Response({"detail": "device_id required"}, status=400)
        try:
            terminal = PaymentAcceptanceService().register_terminal(
                merchant_id=merchant_id, device_id=device_id, actor_id=user.user_id
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(TerminalSerializer(terminal).data, status=status.HTTP_201_CREATED)


class TerminalStatusView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:read"

    def get(self, request, device_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        try:
            terminal = PaymentAcceptanceService().terminal_status(merchant_id=merchant_id, device_id=device_id)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(TerminalSerializer(terminal).data)


class SoftposSessionView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:accept"

    def post(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        ser = SoftposSessionSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            tx = PaymentAcceptanceService().start_softpos_session(
                merchant_id=merchant_id, actor_id=user.user_id, **ser.validated_data
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(TransactionSerializer(tx).data, status=status.HTTP_201_CREATED)


class SoftposConfirmView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:accept"

    def post(self, request, transaction_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        ser = SoftposConfirmSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            tx, receipt = PaymentAcceptanceService().confirm_softpos(
                merchant_id=merchant_id,
                transaction_id=transaction_id,
                actor_id=user.user_id,
                **ser.validated_data,
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(_tx_response(tx, receipt))


class QRCreateView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:accept"

    def post(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        ser = QRCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        data = ser.validated_data
        if data["qr_type"] == QRType.STATIC:
            data["amount"] = data.get("amount")
        elif data.get("amount") is None:
            return Response({"detail": "amount required for dynamic QR"}, status=400)
        try:
            qr = PaymentAcceptanceService().create_qr(merchant_id=merchant_id, actor_id=user.user_id, **data)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(QRSerializer(qr).data, status=status.HTTP_201_CREATED)


class QRCompleteView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:accept"

    def post(self, request, qr_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        try:
            tx, receipt = PaymentAcceptanceService().complete_qr_payment(
                merchant_id=merchant_id, qr_id=qr_id, actor_id=user.user_id
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(_tx_response(tx, receipt))


class PaymentLinkCreateView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:accept"

    def post(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        ser = PaymentLinkCreateSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        share = ser.validated_data.pop("share", None)
        try:
            link = PaymentAcceptanceService().create_payment_link(
                merchant_id=merchant_id, actor_id=user.user_id, share=share, **ser.validated_data
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(PaymentLinkSerializer(link).data, status=status.HTTP_201_CREATED)


class PaymentLinkCompleteView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:accept"

    def post(self, request, link_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        try:
            tx, receipt = PaymentAcceptanceService().complete_link_payment(
                merchant_id=merchant_id, link_id=link_id, actor_id=user.user_id
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(_tx_response(tx, receipt))


class TransactionListView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        txs = PaymentAcceptanceService().list_transactions(
            merchant_id=merchant_id,
            query=request.query_params.get("q", ""),
            status=request.query_params.get("status"),
            channel=request.query_params.get("channel"),
        )
        return Response(TransactionSerializer(txs, many=True).data)


class TransactionDetailView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:read"

    def get(self, request, transaction_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        try:
            tx = PaymentAcceptanceService().get_transaction(merchant_id=merchant_id, transaction_id=transaction_id)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        receipt = getattr(tx, "receipt", None)
        data = TransactionSerializer(tx).data
        if receipt:
            data["receipt"] = ReceiptSerializer(receipt).data
        refunds = RefundSerializerOut(tx.refunds.all(), many=True).data
        data["refunds"] = refunds
        return Response(data)


class TransactionRefundView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:refund"

    def post(self, request, transaction_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        ser = RefundSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            refund = PaymentAcceptanceService().refund(
                merchant_id=merchant_id,
                transaction_id=transaction_id,
                actor_id=user.user_id,
                **ser.validated_data,
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        tx = PaymentAcceptanceService().get_transaction(merchant_id=merchant_id, transaction_id=transaction_id)
        return Response({"refund": RefundSerializerOut(refund).data, "transaction": TransactionSerializer(tx).data})


class ReceiptDetailView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:read"

    def get(self, request, receipt_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        try:
            receipt = PaymentAcceptanceService().get_receipt(merchant_id=merchant_id, receipt_id=receipt_id)
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(ReceiptSerializer(receipt).data)


class ReceiptShareView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:read"

    def post(self, request, receipt_id):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        ser = ReceiptShareSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        try:
            receipt = PaymentAcceptanceService().share_receipt(
                merchant_id=merchant_id,
                receipt_id=receipt_id,
                actor_id=user.user_id,
                **ser.validated_data,
            )
        except MerchantAppError as exc:
            return _handle_app_error(exc)
        return Response(ReceiptSerializer(receipt).data)


class PaymentAnalyticsView(APIView):
    authentication_classes = [MerchantJWTAuthentication]
    permission_classes = [IsMerchantAuthenticated, HasMerchantPermission]
    required_permission = "payment:read"

    def get(self, request):
        user: MerchantPrincipal = request.user
        merchant_id = require_merchant_context(user)
        return Response(PaymentAcceptanceService().analytics_today(merchant_id=merchant_id))
