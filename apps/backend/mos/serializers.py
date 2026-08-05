from rest_framework import serializers

from .models import (
    Branch,
    CommerceMerchant,
    CustomerProfile,
    PosSession,
    Product,
    PurchaseOrder,
    SalesOrder,
    SalesOrderLine,
    StaffMembership,
    StockItem,
    Supplier,
    Warehouse,
)


class CommerceMerchantSerializer(serializers.ModelSerializer):
    merchant_code = serializers.CharField(source="merchant.code", read_only=True)
    merchant_id = serializers.UUIDField(source="merchant.id", read_only=True)

    class Meta:
        model = CommerceMerchant
        fields = (
            "id",
            "merchant_id",
            "merchant_code",
            "business_type",
            "operating_hours",
            "default_currency",
            "tax_inclusive",
            "settings",
            "winga_enabled",
            "active",
            "created_at",
        )


class BranchSerializer(serializers.ModelSerializer):
    class Meta:
        model = Branch
        fields = ("id", "code", "name", "address", "is_hq", "active", "metadata")


class StaffSerializer(serializers.ModelSerializer):
    class Meta:
        model = StaffMembership
        fields = ("id", "principal", "display_name", "role", "branch", "permissions", "active")


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = (
            "id",
            "sku",
            "name",
            "description",
            "kind",
            "unit",
            "currency",
            "price_minor",
            "cost_minor",
            "tax_bps",
            "category",
            "brand",
            "images",
            "attributes",
            "track_inventory",
            "winga_offering_id",
            "active",
        )


class WarehouseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Warehouse
        fields = ("id", "code", "name", "branch", "is_default", "active")


class StockItemSerializer(serializers.ModelSerializer):
    available = serializers.DecimalField(max_digits=18, decimal_places=3, read_only=True)
    product_sku = serializers.CharField(source="product.sku", read_only=True)

    class Meta:
        model = StockItem
        fields = (
            "id",
            "warehouse",
            "product",
            "product_sku",
            "variant",
            "on_hand",
            "reserved",
            "available",
            "reorder_point",
            "batch_no",
            "serial_no",
            "expires_on",
            "unit_cost_minor",
        )


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = ("id", "code", "name", "contacts", "payment_terms", "rating_e4", "active")


class PurchaseOrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = PurchaseOrder
        fields = (
            "id",
            "supplier",
            "warehouse",
            "status",
            "currency",
            "lines",
            "total_minor",
            "reference",
            "created_at",
        )


class CustomerSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomerProfile
        fields = (
            "id",
            "principal",
            "display_name",
            "phone",
            "email",
            "segment",
            "loyalty_points",
            "credit_limit_minor",
            "notes",
        )


class SalesOrderLineSerializer(serializers.ModelSerializer):
    class Meta:
        model = SalesOrderLine
        fields = (
            "id",
            "product",
            "variant",
            "description",
            "quantity",
            "unit_price_minor",
            "discount_minor",
            "tax_minor",
            "line_total_minor",
            "fulfilled_qty",
        )


class SalesOrderSerializer(serializers.ModelSerializer):
    lines = SalesOrderLineSerializer(many=True, read_only=True)

    class Meta:
        model = SalesOrder
        fields = (
            "id",
            "branch",
            "warehouse",
            "customer",
            "channel",
            "status",
            "currency",
            "subtotal_minor",
            "discount_minor",
            "tax_minor",
            "total_minor",
            "payer_principal",
            "payment_ref",
            "paid",
            "mobility_job_ref",
            "winga_deal_id",
            "timeline",
            "lines",
            "created_at",
        )


class PosSessionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PosSession
        fields = (
            "id",
            "branch",
            "cashier_principal",
            "status",
            "opening_float_minor",
            "closing_cash_minor",
            "opened_at",
            "closed_at",
        )
