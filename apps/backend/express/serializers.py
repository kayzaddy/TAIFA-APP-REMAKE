from rest_framework import serializers

from .models import ExpressOrder, ExpressProduct, ExpressStore


class ExpressStoreSerializer(serializers.ModelSerializer):
    class Meta:
        model = ExpressStore
        fields = [
            "id",
            "code",
            "name",
            "category",
            "logo_url",
            "banner_url",
            "lat",
            "lng",
            "delivery_radius_m",
            "prep_minutes",
            "rating",
            "reliability",
            "workload",
            "operating_hours",
            "verified",
            "active",
        ]


class ExpressProductSerializer(serializers.ModelSerializer):
    store_id = serializers.UUIDField(source="store.id", read_only=True)
    store_name = serializers.CharField(source="store.name", read_only=True)
    store_code = serializers.CharField(source="store.code", read_only=True)

    class Meta:
        model = ExpressProduct
        fields = [
            "id",
            "store_id",
            "store_name",
            "store_code",
            "sku",
            "name",
            "category",
            "price_minor",
            "currency",
            "stock_qty",
            "stock_status",
            "image_url",
            "tags",
            "active",
        ]


class ExpressOrderSerializer(serializers.ModelSerializer):
    store_name = serializers.CharField(source="store.name", read_only=True, allow_null=True)
    store_code = serializers.CharField(source="store.code", read_only=True, allow_null=True)

    class Meta:
        model = ExpressOrder
        fields = [
            "id",
            "public_code",
            "package_code",
            "package_qr",
            "packing_checklist",
            "owner",
            "status",
            "store",
            "store_name",
            "store_code",
            "lines",
            "subtotal_minor",
            "delivery_fee_minor",
            "platform_fee_minor",
            "total_minor",
            "currency",
            "urgency",
            "payment_timing",
            "payment_method",
            "customer_lat",
            "customer_lng",
            "customer_address",
            "customer_phone",
            "customer_notes",
            "promo_code",
            "ranking",
            "food_order_id",
            "mos_order_id",
            "trip_id",
            "delivery_id",
            "payment_ref",
            "tap_session_code",
            "delivery_pin",
            "settlement_plan",
            "settlement_status",
            "eta_minutes",
            "merchant_notes",
            "timeline",
            "ai_prompt",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields
