"""Taifa Commerce MOS HTTP API — reuses enterprise capture; never forges money."""
from __future__ import annotations

from decimal import Decimal

from django.shortcuts import get_object_or_404
from drf_spectacular.utils import extend_schema
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView

from enterprise.models import Merchant, MerchantStatus
from payments.auth import IsDevice

from .models import (
    Branch,
    CommerceMerchant,
    CustomerProfile,
    PosSession,
    PosSessionStatus,
    Product,
    PurchaseOrder,
    SalesOrder,
    StaffMembership,
    StockItem,
    Supplier,
    Warehouse,
)
from .serializers import (
    BranchSerializer,
    CommerceMerchantSerializer,
    CustomerSerializer,
    PosSessionSerializer,
    ProductSerializer,
    PurchaseOrderSerializer,
    SalesOrderSerializer,
    StaffSerializer,
    StockItemSerializer,
    SupplierSerializer,
    WarehouseSerializer,
)
from . import services


def _principal(request) -> str:
    return getattr(request, "device_id", None) or request.headers.get("X-Device-Id", "anonymous")


def _cm(merchant_id) -> CommerceMerchant:
    return get_object_or_404(CommerceMerchant, merchant_id=merchant_id)


class BootstrapView(APIView):
    """Register ACTIVE merchant + MOS profile + HQ branch + warehouse."""

    permission_classes = [IsDevice]

    def post(self, request):
        code = (request.data.get("code") or "").strip()
        legal_name = (request.data.get("legal_name") or "").strip()
        if not code or not legal_name:
            return Response({"detail": "code and legal_name required"}, status=400)
        business_type = request.data.get("business_type") or "retail"
        merchant = Merchant.objects.filter(code=code).first()
        if merchant is None:
            merchant = Merchant.objects.create(
                code=code,
                legal_name=legal_name,
                trading_name=request.data.get("trading_name") or legal_name,
                status=MerchantStatus.ACTIVE,
                sector=business_type,
                owner_principal=_principal(request),
            )
        if merchant.status != MerchantStatus.ACTIVE:
            merchant.status = MerchantStatus.ACTIVE
            merchant.save(update_fields=["status", "updated_at"])
        cm, branch, wh = services.bootstrap_merchant_ops(
            merchant=merchant,
            business_type=business_type,
            hq_name=request.data.get("hq_name") or "Main Branch",
            actor=_principal(request),
        )
        return Response(
            {
                "commerce_merchant": CommerceMerchantSerializer(cm).data,
                "branch": BranchSerializer(branch).data,
                "warehouse": WarehouseSerializer(wh).data,
            },
            status=201,
        )


class MerchantDetailView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(CommerceMerchantSerializer(_cm(merchant_id)).data)


class BranchListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        cm = _cm(merchant_id)
        return Response(BranchSerializer(cm.branches.all(), many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        ser = BranchSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        branch = Branch.objects.create(commerce_merchant=cm, **ser.validated_data)
        return Response(BranchSerializer(branch).data, status=201)


class StaffListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(StaffSerializer(_cm(merchant_id).staff.all(), many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        ser = StaffSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        row = StaffMembership.objects.create(commerce_merchant=cm, **ser.validated_data)
        return Response(StaffSerializer(row).data, status=201)


class ProductListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        qs = _cm(merchant_id).products.all()
        q = request.query_params.get("q")
        if q:
            qs = qs.filter(name__icontains=q) | qs.filter(sku__icontains=q)
        return Response(ProductSerializer(qs[:200], many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        ser = ProductSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        product = Product.objects.create(commerce_merchant=cm, **ser.validated_data)
        return Response(ProductSerializer(product).data, status=201)


class ProductPublishWingaView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id, product_id):
        cm = _cm(merchant_id)
        product = get_object_or_404(Product, pk=product_id, commerce_merchant=cm)
        try:
            product = services.publish_product_to_winga(
                product=product,
                domain_code=request.data.get("domain_code") or "retail",
            )
        except services.MosError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(ProductSerializer(product).data)


class WarehouseListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(WarehouseSerializer(_cm(merchant_id).warehouses.all(), many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        ser = WarehouseSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        wh = Warehouse.objects.create(commerce_merchant=cm, **ser.validated_data)
        return Response(WarehouseSerializer(wh).data, status=201)


class StockListView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        cm = _cm(merchant_id)
        qs = StockItem.objects.filter(warehouse__commerce_merchant=cm).select_related("product")
        return Response(StockItemSerializer(qs[:500], many=True).data)


class StockAdjustView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        warehouse = get_object_or_404(Warehouse, pk=request.data.get("warehouse_id"), commerce_merchant=cm)
        product = get_object_or_404(Product, pk=request.data.get("product_id"), commerce_merchant=cm)
        item = services.get_or_create_stock(warehouse=warehouse, product=product)
        try:
            item = services.adjust_stock(
                stock_item=item,
                kind=request.data.get("kind") or "receive",
                quantity=Decimal(str(request.data.get("quantity") or "0")),
                actor=_principal(request),
                reference=request.data.get("reference") or "",
                note=request.data.get("note") or "",
            )
        except services.MosError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(StockItemSerializer(item).data)


class SupplierListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(SupplierSerializer(_cm(merchant_id).suppliers.all(), many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        ser = SupplierSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        row = Supplier.objects.create(commerce_merchant=cm, **ser.validated_data)
        return Response(SupplierSerializer(row).data, status=201)


class PurchaseOrderListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(PurchaseOrderSerializer(_cm(merchant_id).purchase_orders.all()[:100], many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        supplier = get_object_or_404(Supplier, pk=request.data.get("supplier_id"), commerce_merchant=cm)
        warehouse = get_object_or_404(Warehouse, pk=request.data.get("warehouse_id"), commerce_merchant=cm)
        po = PurchaseOrder.objects.create(
            commerce_merchant=cm,
            supplier=supplier,
            warehouse=warehouse,
            lines=request.data.get("lines") or [],
            total_minor=int(request.data.get("total_minor") or 0),
            reference=request.data.get("reference") or "",
            created_by=_principal(request),
            currency=cm.default_currency,
        )
        return Response(PurchaseOrderSerializer(po).data, status=201)


class CustomerListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(CustomerSerializer(_cm(merchant_id).customers.all()[:200], many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        ser = CustomerSerializer(data=request.data)
        ser.is_valid(raise_exception=True)
        row = CustomerProfile.objects.create(commerce_merchant=cm, **ser.validated_data)
        return Response(CustomerSerializer(row).data, status=201)


class OrderListCreateView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="mos_merchant_orders_list")
    def get(self, request, merchant_id):
        qs = _cm(merchant_id).orders.all()[:100]
        return Response(SalesOrderSerializer(qs, many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        try:
            order = services.create_sales_order(
                commerce_merchant=cm,
                lines=request.data.get("lines") or [],
                channel=request.data.get("channel") or "pos",
                payer_principal=request.data.get("payer_principal") or "",
                created_by=_principal(request),
                discount_minor=int(request.data.get("discount_minor") or 0),
            )
        except services.MosError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(SalesOrderSerializer(order).data, status=201)


class OrderDetailView(APIView):
    permission_classes = [IsDevice]

    @extend_schema(operation_id="mos_merchant_orders_retrieve")
    def get(self, request, merchant_id, order_id):
        order = get_object_or_404(SalesOrder, pk=order_id, commerce_merchant=_cm(merchant_id))
        return Response(SalesOrderSerializer(order).data)


class OrderPayView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id, order_id):
        order = get_object_or_404(SalesOrder, pk=order_id, commerce_merchant=_cm(merchant_id))
        idem = request.headers.get("Idempotency-Key") or request.data.get("idempotency_key")
        if not idem:
            return Response({"detail": "Idempotency-Key required"}, status=400)
        payer = request.data.get("payer_principal") or order.payer_principal or _principal(request)
        # Ensure payer has wallet funds in test/demo: opening top-up if missing balance path fails — tests fund explicitly
        try:
            order = services.pay_sales_order(
                order=order,
                payer_principal=payer,
                idempotency_key=idem,
                actor=_principal(request),
            )
        except services.MosError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(SalesOrderSerializer(order).data)


class OrderFulfillView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id, order_id):
        order = get_object_or_404(SalesOrder, pk=order_id, commerce_merchant=_cm(merchant_id))
        try:
            order = services.fulfill_sales_order(order=order, actor=_principal(request))
        except services.MosError as exc:
            return Response({"detail": str(exc)}, status=400)
        return Response(SalesOrderSerializer(order).data)


class PosSessionListCreateView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(PosSessionSerializer(_cm(merchant_id).pos_sessions.all()[:50], many=True).data)

    def post(self, request, merchant_id):
        cm = _cm(merchant_id)
        branch = get_object_or_404(Branch, pk=request.data.get("branch_id"), commerce_merchant=cm)
        session = PosSession.objects.create(
            commerce_merchant=cm,
            branch=branch,
            cashier_principal=request.data.get("cashier_principal") or _principal(request),
            opening_float_minor=int(request.data.get("opening_float_minor") or 0),
        )
        return Response(PosSessionSerializer(session).data, status=201)


class PosSessionCloseView(APIView):
    permission_classes = [IsDevice]

    def post(self, request, merchant_id, session_id):
        cm = _cm(merchant_id)
        session = get_object_or_404(PosSession, pk=session_id, commerce_merchant=cm)
        session.status = PosSessionStatus.CLOSED
        session.closing_cash_minor = int(request.data.get("closing_cash_minor") or 0)
        from django.utils import timezone

        session.closed_at = timezone.now()
        session.save(update_fields=["status", "closing_cash_minor", "closed_at"])
        return Response(PosSessionSerializer(session).data)


class AnalyticsSummaryView(APIView):
    permission_classes = [IsDevice]

    def get(self, request, merchant_id):
        return Response(services.analytics_summary(commerce_merchant=_cm(merchant_id)))


class AssistView(APIView):
    """AI commerce copilot stub — never authorizes payments."""

    permission_classes = [IsDevice]

    def post(self, request, merchant_id):
        capability = (request.data.get("capability") or "").lower()
        if capability in ("authorize_payment", "capture_payment", "move_money", "settle"):
            return Response(
                {"detail": "AI must never authorize payments", "blocked": True},
                status=400,
            )
        _cm(merchant_id)
        tips = {
            "inventory_forecast": ["Review SKUs below reorder point", "Receive high-velocity items before weekend"],
            "pricing": ["Compare cost_minor vs price_minor margins", "Test a weekend percent promotion"],
            "demand": ["Promote top sellers via Winga campaign", "Bundle slow movers with bestsellers"],
        }.get(capability, ["Ask for inventory_forecast, pricing, or demand"])
        return Response({"capability": capability, "tips": tips, "payment_authority": False})
