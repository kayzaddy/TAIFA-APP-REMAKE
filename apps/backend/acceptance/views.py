"""MAP HTTP API — acceptance channels; money via enterprise capture only."""
from __future__ import annotations

from django.shortcuts import get_object_or_404
from rest_framework.response import Response
from rest_framework.views import APIView

from enterprise.models import Merchant, MerchantStatus
from payments.auth import IsDevice

from . import services
from . import tap as tap_services
from .models import (
    AcceptanceIntent,
    AcceptanceProfile,
    AcceptanceReceipt,
    AcceptanceTerminal,
    DigitalInvoice,
    PaymentLink,
    QrArtifact,
    TapSession,
)
from .serializers import (
    AcceptanceIntentSerializer,
    AcceptanceProfileSerializer,
    AcceptanceReceiptSerializer,
    AcceptanceTerminalSerializer,
    CheckoutSessionSerializer,
    DigitalInvoiceSerializer,
    PaymentLinkSerializer,
    QrArtifactSerializer,
    TapSessionSerializer,
    WalletFundingPreferenceSerializer,
)


def _principal(request) -> str:
    return getattr(request, "device_id", None) or request.headers.get("X-Device-Id", "anonymous")


def _merchant(merchant_id) -> Merchant:
    return get_object_or_404(Merchant, id=merchant_id)


class BootstrapProfileView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        code = (request.data.get("code") or "").strip()
        legal_name = (request.data.get("legal_name") or "").strip()
        if not code or not legal_name:
            return Response({"detail": "code and legal_name required"}, status=400)
        merchant = Merchant.objects.filter(code=code).first()
        if merchant is None:
            merchant = Merchant.objects.create(
                code=code,
                legal_name=legal_name,
                trading_name=request.data.get("trading_name") or legal_name,
                status=MerchantStatus.ACTIVE,
                sector=request.data.get("sector") or "retail",
                owner_principal=_principal(request),
            )
        elif merchant.status != MerchantStatus.ACTIVE:
            merchant.status = MerchantStatus.ACTIVE
            merchant.save(update_fields=["status", "updated_at"])
        profile = services.ensure_profile(
            merchant=merchant,
            display_name=request.data.get("display_name") or "",
            actor=_principal(request),
        )
        methods = request.data.get("accepted_methods")
        if isinstance(methods, list) and methods:
            profile.accepted_methods = methods
            profile.save(update_fields=["accepted_methods", "updated_at"])
        return Response(
            {
                "merchant_id": str(merchant.id),
                "merchant_code": merchant.code,
                "profile": AcceptanceProfileSerializer(profile).data,
            },
            status=201,
        )


class ProfileDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        profile = get_object_or_404(AcceptanceProfile, merchant_id=merchant_id)
        return Response(AcceptanceProfileSerializer(profile).data)

    def patch(self, request, merchant_id):
        profile = get_object_or_404(AcceptanceProfile, merchant_id=merchant_id)
        for field in (
            "display_name",
            "logo_url",
            "default_currency",
            "accepted_methods",
            "receipt_preferences",
            "branding",
            "branch_config",
            "store_config",
            "terminal_config",
            "active",
        ):
            if field in request.data:
                setattr(profile, field, request.data[field])
        profile.save()
        return Response(AcceptanceProfileSerializer(profile).data)


class QrIssueView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        try:
            qr, intent = services.issue_qr(
                merchant=merchant,
                kind=request.data.get("kind") or "dynamic",
                amount_minor=request.data.get("amount_minor"),
                currency=request.data.get("currency") or "TZS",
                description=request.data.get("description") or "",
                ttl_minutes=request.data.get("ttl_minutes", 60),
                branch_ref=request.data.get("branch_ref") or "",
                terminal_ref=request.data.get("terminal_ref") or "",
                created_by=_principal(request),
            )
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        body = {"qr": QrArtifactSerializer(qr).data}
        if intent:
            body["intent"] = AcceptanceIntentSerializer(intent).data
        return Response(body, status=201)


class PaymentLinkCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        amount = request.data.get("amount_minor")
        if amount is None:
            return Response({"detail": "amount_minor required"}, status=400)
        try:
            link = services.create_payment_link(
                merchant=merchant,
                amount_minor=int(amount),
                purpose=request.data.get("purpose") or "general",
                currency=request.data.get("currency") or "TZS",
                description=request.data.get("description") or "",
                ttl_minutes=request.data.get("ttl_minutes", 1440),
                max_uses=int(request.data.get("max_uses") or 1),
                branding=request.data.get("branding"),
                created_by=_principal(request),
                sales_order_id=request.data.get("sales_order_id"),
                winga_deal_id=request.data.get("winga_deal_id"),
            )
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(PaymentLinkSerializer(link).data, status=201)

    def get(self, request, merchant_id):
        qs = PaymentLink.objects.filter(merchant_id=merchant_id).order_by("-created_at")[:50]
        return Response(PaymentLinkSerializer(qs, many=True).data)


class InvoiceCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        number = (request.data.get("invoice_number") or "").strip()
        amount = request.data.get("amount_minor")
        if not number or amount is None:
            return Response({"detail": "invoice_number and amount_minor required"}, status=400)
        try:
            inv, intent, qr = services.create_invoice(
                merchant=merchant,
                invoice_number=number,
                amount_minor=int(amount),
                line_items=request.data.get("line_items") or [],
                currency=request.data.get("currency") or "TZS",
                customer_name=request.data.get("customer_name") or "",
                customer_ref=request.data.get("customer_ref") or "",
                allow_partial=bool(request.data.get("allow_partial")),
                installment_plan=request.data.get("installment_plan"),
                created_by=_principal(request),
            )
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "invoice": DigitalInvoiceSerializer(inv).data,
                "intent": AcceptanceIntentSerializer(intent).data,
                "qr": QrArtifactSerializer(qr).data,
            },
            status=201,
        )

    def get(self, request, merchant_id):
        qs = DigitalInvoice.objects.filter(merchant_id=merchant_id).order_by("-created_at")[:50]
        return Response(DigitalInvoiceSerializer(qs, many=True).data)


class CheckoutCreateView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        amount = request.data.get("amount_minor")
        if amount is None:
            return Response({"detail": "amount_minor required"}, status=400)
        try:
            session = services.create_checkout(
                merchant=merchant,
                amount_minor=int(amount),
                mode=request.data.get("mode") or "mobile",
                currency=request.data.get("currency") or "TZS",
                description=request.data.get("description") or "",
                return_url=request.data.get("return_url") or "",
                cancel_url=request.data.get("cancel_url") or "",
                ttl_minutes=request.data.get("ttl_minutes", 30),
                sales_order_id=request.data.get("sales_order_id"),
                winga_deal_id=request.data.get("winga_deal_id"),
                trip_id=request.data.get("trip_id"),
                created_by=_principal(request),
            )
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(CheckoutSessionSerializer(session).data, status=201)


class TerminalListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        qs = AcceptanceTerminal.objects.filter(merchant_id=merchant_id, active=True)
        return Response(AcceptanceTerminalSerializer(qs, many=True).data)

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        code = (request.data.get("code") or "").strip()
        if not code:
            return Response({"detail": "code required"}, status=400)
        term = services.register_terminal(
            merchant=merchant,
            code=code,
            kind=request.data.get("kind") or "pos",
            label=request.data.get("label") or "",
            branch_ref=request.data.get("branch_ref") or "",
            softpos_ready=bool(request.data.get("softpos_ready")),
            nfc_ready=bool(request.data.get("nfc_ready")),
        )
        return Response(AcceptanceTerminalSerializer(term).data, status=201)


class IntentDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, public_code):
        intent = get_object_or_404(AcceptanceIntent, public_code=public_code)
        return Response(AcceptanceIntentSerializer(intent).data)


class IntentPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, public_code):
        intent = get_object_or_404(AcceptanceIntent, public_code=public_code)
        idem = request.headers.get("Idempotency-Key") or request.data.get("idempotency_key")
        if not idem:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        payer = request.data.get("payer_principal") or _principal(request)
        amount = request.data.get("amount_minor")
        try:
            intent, receipt = services.pay_intent(
                intent=intent,
                payer_principal=payer,
                idempotency_key=idem,
                amount_minor=int(amount) if amount is not None else None,
                actor=_principal(request),
            )
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "intent": AcceptanceIntentSerializer(intent).data,
                "receipt": AcceptanceReceiptSerializer(receipt).data,
            }
        )


class LinkResolveView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, path_token):
        link = get_object_or_404(PaymentLink, path_token=path_token, active=True)
        return Response(
            {
                "link": PaymentLinkSerializer(link).data,
                "intent": AcceptanceIntentSerializer(link.intent).data,
                "merchant_display": link.profile.display_name,
            }
        )


class StaticQrPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        amount = request.data.get("amount_minor")
        idem = request.headers.get("Idempotency-Key") or request.data.get("idempotency_key")
        if amount is None or not idem:
            return Response({"detail": "amount_minor and Idempotency-Key required"}, status=400)
        payer = request.data.get("payer_principal") or _principal(request)
        try:
            intent, receipt = services.pay_from_static_qr(
                merchant=merchant,
                amount_minor=int(amount),
                payer_principal=payer,
                idempotency_key=idem,
                currency=request.data.get("currency") or "TZS",
                actor=_principal(request),
            )
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "intent": AcceptanceIntentSerializer(intent).data,
                "receipt": AcceptanceReceiptSerializer(receipt).data,
            }
        )


class ReceiptDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, public_code):
        receipt = get_object_or_404(AcceptanceReceipt, public_code=public_code)
        return Response(AcceptanceReceiptSerializer(receipt).data)


class AnalyticsSummaryView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        return Response(services.analytics_summary(merchant=merchant))


class QrLibraryView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        qs = QrArtifact.objects.filter(merchant_id=merchant_id).order_by("-created_at")[:50]
        return Response(QrArtifactSerializer(qs, many=True).data)


class WingaDealAcceptView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        amount = request.data.get("amount_minor")
        deal_id = request.data.get("winga_deal_id")
        if amount is None:
            return Response({"detail": "amount_minor required"}, status=400)
        try:
            qr, intent = services.issue_qr(
                merchant=merchant,
                kind="dynamic",
                amount_minor=int(amount),
                currency=request.data.get("currency") or "TZS",
                description=request.data.get("description") or "Winga deal",
                created_by=_principal(request),
            )
            if intent and deal_id:
                intent.winga_deal_id = deal_id
                intent.channel = "winga"
                intent.signature = services._sign_intent(intent)
                intent.save(update_fields=["winga_deal_id", "channel", "signature", "updated_at"])
            link = services.create_payment_link(
                merchant=merchant,
                amount_minor=int(amount),
                purpose="booking",
                currency=request.data.get("currency") or "TZS",
                description="Winga deal link",
                winga_deal_id=deal_id,
                created_by=_principal(request),
            )
            checkout = services.create_checkout(
                merchant=merchant,
                amount_minor=int(amount),
                description="Winga checkout",
                winga_deal_id=deal_id,
                created_by=_principal(request),
            )
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(
            {
                "qr": QrArtifactSerializer(qr).data,
                "intent": AcceptanceIntentSerializer(intent).data if intent else None,
                "link": PaymentLinkSerializer(link).data,
                "checkout": CheckoutSessionSerializer(checkout).data,
            },
            status=201,
        )


class MobilityAcceptView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        amount = request.data.get("amount_minor")
        if amount is None:
            return Response({"detail": "amount_minor required"}, status=400)
        try:
            session = services.create_checkout(
                merchant=merchant,
                amount_minor=int(amount),
                mode="mobile",
                description=request.data.get("description") or "Mobility payment",
                trip_id=request.data.get("trip_id"),
                created_by=_principal(request),
            )
            intent = session.intent
            intent.channel = "mobility"
            intent.signature = services._sign_intent(intent)
            intent.save(update_fields=["channel", "signature", "updated_at"])
        except services.MapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(CheckoutSessionSerializer(session).data, status=201)


class FundingPrefsView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        prefs = tap_services.get_or_create_funding_prefs(owner_principal=_principal(request))
        return Response(WalletFundingPreferenceSerializer(prefs).data)

    def put(self, request):
        return self._save(request)

    def patch(self, request):
        return self._save(request)

    def post(self, request):
        return self._save(request)

    def _save(self, request):
        prefs = tap_services.update_funding_prefs(
            owner_principal=_principal(request),
            priority=request.data.get("priority"),
            auto_route=request.data.get("auto_route"),
            require_confirmation=request.data.get("require_confirmation"),
            auth_policy=request.data.get("auth_policy"),
            low_risk_threshold_minor=request.data.get("low_risk_threshold_minor"),
            merchant_overrides=request.data.get("merchant_overrides"),
        )
        return Response(WalletFundingPreferenceSerializer(prefs).data)


class FundingResolveView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        amount = request.data.get("amount_minor")
        if amount is None:
            return Response({"detail": "amount_minor required"}, status=400)
        result = tap_services.resolve_funding(
            owner_principal=_principal(request),
            amount_minor=int(amount),
            currency=request.data.get("currency") or "TZS",
            merchant_code=request.data.get("merchant_code") or "",
        )
        return Response(result)


class TapStartView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        merchant = _merchant(merchant_id)
        amount = request.data.get("amount_minor")
        if amount is None:
            return Response({"detail": "amount_minor required"}, status=400)
        payer = request.data.get("payer_principal") or _principal(request)
        try:
            session = tap_services.start_tap(
                merchant=merchant,
                amount_minor=int(amount),
                currency=request.data.get("currency") or "TZS",
                payer_principal=payer,
                channel=request.data.get("channel") or "nfc",
                terminal_code=request.data.get("terminal_code") or "",
                nfc_meta=request.data.get("nfc_meta") or {},
                ttl_seconds=int(request.data.get("ttl_seconds") or 90),
                created_by=_principal(request),
            )
        except tap_services.TapError as exc:
            return Response({"detail": str(exc)}, status=400)
        routing = tap_services.resolve_funding(
            owner_principal=payer,
            amount_minor=int(amount),
            currency=request.data.get("currency") or "TZS",
            merchant_code=merchant.code,
        )
        return Response(
            {"session": TapSessionSerializer(session).data, "routing": routing},
            status=201,
        )


class TapDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, public_code):
        session = get_object_or_404(TapSession, public_code=public_code)
        return Response(TapSessionSerializer(session).data)


class TapAuthView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, public_code):
        session = get_object_or_404(TapSession, public_code=public_code)
        try:
            session = tap_services.authenticate_tap(
                session=session,
                method=request.data.get("method") or "biometric",
                actor=_principal(request),
            )
        except tap_services.TapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(TapSessionSerializer(session).data)


class TapConfirmView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, public_code):
        session = get_object_or_404(TapSession, public_code=public_code)
        idem = request.headers.get("Idempotency-Key") or request.data.get("idempotency_key")
        if not idem:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        try:
            session = tap_services.confirm_tap(
                session=session,
                idempotency_key=idem,
                funding_ref=request.data.get("funding_ref"),
                actor=_principal(request),
            )
        except tap_services.TapError as exc:
            return Response(
                {"detail": str(exc), "session": TapSessionSerializer(session).data},
                status=400,
            )
        return Response(TapSessionSerializer(session).data)


class TapCancelView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, public_code):
        session = get_object_or_404(TapSession, public_code=public_code)
        try:
            session = tap_services.cancel_tap(session=session)
        except tap_services.TapError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(TapSessionSerializer(session).data)
