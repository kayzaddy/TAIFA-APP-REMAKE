"""Taifa Express HTTP API — orchestration only; money via commerce; delivery via trips."""
from __future__ import annotations

from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework.response import Response
from rest_framework.views import APIView

from payments.auth import IsDevice

from . import services
from .list_parser import parse_shopping_list
from .models import ExpressOrder, ExpressStore, PaymentTiming
from .serializers import ExpressOrderSerializer, ExpressProductSerializer, ExpressStoreSerializer


def _principal(request) -> str:
    return getattr(request, "device_id", None) or request.headers.get("X-Device-Id", "anonymous")


def _idem(request) -> str:
    return (
        request.headers.get("Idempotency-Key")
        or request.data.get("idempotency_key")
        or f"xp-{_principal(request)}-{request.path}"
    )


class RankStoresView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        try:
            lat = float(request.query_params.get("lat", -6.7924))
            lng = float(request.query_params.get("lng", 39.2083))
        except (TypeError, ValueError):
            return Response({"detail": "lat and lng must be numbers"}, status=400)
        names = request.query_params.getlist("product") or []
        q = (request.query_params.get("q") or "").strip()
        if q and not names:
            names = [p.strip() for p in q.split(",") if p.strip()]
        ranked = services.rank_stores(
            customer_lat=lat,
            customer_lng=lng,
            product_names=names or None,
            category=(request.query_params.get("category") or "").strip(),
            limit=int(request.query_params.get("limit") or 10),
        )
        return Response({"results": ranked})


class StoreListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        qs = ExpressStore.objects.filter(active=True)
        category = (request.query_params.get("category") or "").strip()
        if category:
            qs = qs.filter(category=category)
        return Response(ExpressStoreSerializer(qs[:50], many=True).data)


class ProductSearchView(APIView):
    permission_classes = [IsDevice]

    def get(self, request):
        products = services.search_products(
            query=(request.query_params.get("q") or "").strip(),
            category=(request.query_params.get("category") or "").strip(),
            limit=int(request.query_params.get("limit") or 40),
        )
        return Response(ExpressProductSerializer(products, many=True).data)


class AiBasketView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        prompt = (request.data.get("prompt") or request.data.get("message") or "").strip()
        if not prompt:
            return Response({"detail": "prompt required"}, status=400)
        return Response(services.ai_build_basket(prompt=prompt))


class ParseShoppingListView(APIView):
    """Smart Shopping List — parse multiline list into matched basket items."""

    permission_classes = [IsDevice]

    def post(self, request):
        text = request.data.get("text") or request.data.get("list") or ""
        if not str(text).strip():
            return Response({"detail": "text required"}, status=400)
        try:
            lat = request.data.get("lat")
            lng = request.data.get("lng")
            result = parse_shopping_list(
                text=str(text),
                customer_lat=float(lat) if lat is not None else None,
                customer_lng=float(lng) if lng is not None else None,
            )
        except (TypeError, ValueError):
            return Response({"detail": "invalid lat/lng"}, status=400)
        return Response(result)


class QuoteView(APIView):
    permission_classes = [IsDevice]

    def post(self, request):
        items = request.data.get("items") or []
        if not isinstance(items, list) or not items:
            return Response({"detail": "items required"}, status=400)
        try:
            lat = float(request.data.get("lat") or -6.7924)
            lng = float(request.data.get("lng") or 39.2083)
            quote = services.quote_fulfillment(
                items=items,
                customer_lat=lat,
                customer_lng=lng,
                urgency=(request.data.get("urgency") or "standard").strip(),
                category=(request.data.get("category") or "").strip(),
            )
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(quote)


class OrderListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="express_orders_list")
    def get(self, request):
        owner = _principal(request)
        qs = ExpressOrder.objects.filter(owner=owner).select_related("store")[:40]
        return Response(ExpressOrderSerializer(qs, many=True).data)

    def post(self, request):
        items = request.data.get("items") or []
        if not isinstance(items, list) or not items:
            return Response({"detail": "items required"}, status=400)
        try:
            lat = float(request.data.get("lat") or request.data.get("customer_lat") or -6.7924)
            lng = float(request.data.get("lng") or request.data.get("customer_lng") or 39.2083)
            order = services.create_order(
                owner=_principal(request),
                items=items,
                customer_lat=lat,
                customer_lng=lng,
                customer_address=(request.data.get("address") or "").strip(),
                customer_phone=(request.data.get("phone") or "").strip(),
                customer_notes=(request.data.get("notes") or "").strip(),
                store_id=request.data.get("store_id"),
                urgency=(request.data.get("urgency") or "standard").strip(),
                ai_prompt=(request.data.get("ai_prompt") or "").strip(),
                payment_timing=(request.data.get("payment_timing") or PaymentTiming.PREPAID),
                payment_method=(request.data.get("payment_method") or "wallet").strip(),
                promo_code=(request.data.get("promo_code") or "").strip(),
            )
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ExpressOrderSerializer(order).data, status=201)


class OrderDetailView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="express_orders_retrieve")
    def get(self, request, order_id):
        order = get_object_or_404(ExpressOrder, id=order_id, owner=_principal(request))
        return Response(ExpressOrderSerializer(order).data)


class OrderAcceptView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, order_id):
        order = get_object_or_404(ExpressOrder, id=order_id)
        try:
            order = services.merchant_accept(order=order, actor=_principal(request))
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ExpressOrderSerializer(order).data)


class OrderPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, order_id):
        owner = _principal(request)
        order = get_object_or_404(ExpressOrder, id=order_id, owner=owner)
        try:
            order = services.pay_order(
                order=order,
                owner=owner,
                idempotency_key=_idem(request),
                actor=owner,
            )
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ExpressOrderSerializer(order).data)


class OrderReadyView(APIView):
    """Merchant READY → auto-dispatch rider + package POD."""

    permission_classes = [IsDevice]

    def post(self, request, order_id):
        order = get_object_or_404(ExpressOrder, id=order_id)
        try:
            order = services.merchant_ready(order=order, actor=_principal(request))
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ExpressOrderSerializer(order).data)


class OrderDeliverView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, order_id):
        order = get_object_or_404(ExpressOrder, id=order_id, owner=_principal(request))
        try:
            order = services.request_delivery(order=order, actor=_principal(request))
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ExpressOrderSerializer(order).data)


class OrderAdvanceView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, order_id):
        order = get_object_or_404(ExpressOrder, id=order_id)
        stage = (request.data.get("stage") or "").strip()
        try:
            order = services.advance_fulfillment(
                order=order, stage=stage, actor=_principal(request)
            )
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ExpressOrderSerializer(order).data)


class CheckoutView(APIView):
    """One-tap: rank → accept → pay → READY → rider."""

    permission_classes = [IsDevice]

    def post(self, request):
        items = request.data.get("items") or []
        if not isinstance(items, list) or not items:
            return Response({"detail": "items required"}, status=400)
        try:
            lat = float(request.data.get("lat") or request.data.get("customer_lat") or -6.7924)
            lng = float(request.data.get("lng") or request.data.get("customer_lng") or 39.2083)
            order = services.checkout(
                owner=_principal(request),
                items=items,
                customer_lat=lat,
                customer_lng=lng,
                customer_address=(request.data.get("address") or "").strip(),
                customer_phone=(request.data.get("phone") or "").strip(),
                customer_notes=(request.data.get("notes") or "").strip(),
                idempotency_key=_idem(request),
                urgency=(request.data.get("urgency") or "standard").strip(),
                ai_prompt=(request.data.get("ai_prompt") or "").strip(),
                payment_timing=(request.data.get("payment_timing") or PaymentTiming.PREPAID),
                payment_method=(request.data.get("payment_method") or "wallet").strip(),
                promo_code=(request.data.get("promo_code") or "").strip(),
                auto_accept=bool(request.data.get("auto_accept", True)),
                auto_ready=bool(request.data.get("auto_ready", True)),
            )
        except services.ExpressError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ExpressOrderSerializer(order).data, status=201)
