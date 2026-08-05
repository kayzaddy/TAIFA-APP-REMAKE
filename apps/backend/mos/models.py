"""Taifa Commerce — Merchant Operating System (MOS) models.

Identity of a seller = enterprise.Merchant (never duplicated).
Money truth = payments ledger via enterprise capture.
Brokerage discovery = optional publish to winga.Offering.
"""
from __future__ import annotations

import uuid

from django.db import models


class BusinessType(models.TextChoices):
    RETAIL = "retail"
    WHOLESALE = "wholesale"
    MANUFACTURER = "manufacturer"
    RESTAURANT = "restaurant"
    PHARMACY = "pharmacy"
    ELECTRONICS = "electronics"
    FASHION = "fashion"
    AGRICULTURE = "agriculture"
    CONSTRUCTION = "construction"
    HOTEL = "hotel"
    PROFESSIONAL = "professional"
    DIGITAL = "digital"
    SUBSCRIPTION = "subscription"
    MARKET_VENDOR = "market_vendor"
    GOV_SUPPLIER = "gov_supplier"
    FRANCHISE = "franchise"
    MULTI_BRANCH = "multi_branch"
    OTHER = "other"


class StaffRole(models.TextChoices):
    OWNER = "owner"
    MANAGER = "manager"
    CASHIER = "cashier"
    WAREHOUSE = "warehouse"
    PURCHASER = "purchaser"
    ANALYST = "analyst"
    SUPPORT = "support"


class ProductKind(models.TextChoices):
    PHYSICAL = "physical"
    DIGITAL = "digital"
    SERVICE = "service"
    SUBSCRIPTION = "subscription"
    BUNDLE = "bundle"


class StockMovementKind(models.TextChoices):
    RECEIVE = "receive"
    ISSUE = "issue"
    ADJUST = "adjust"
    TRANSFER_OUT = "transfer_out"
    TRANSFER_IN = "transfer_in"
    RESERVE = "reserve"
    RELEASE = "release"
    COUNT = "count"
    RETURN = "return"


class OrderChannel(models.TextChoices):
    POS = "pos"
    ONLINE = "online"
    DRAFT = "draft"
    WINGA = "winga"
    PHONE = "phone"
    MANUAL = "manual"


class OrderStatus(models.TextChoices):
    DRAFT = "draft"
    OPEN = "open"
    CONFIRMED = "confirmed"
    PARTIALLY_FULFILLED = "partially_fulfilled"
    FULFILLED = "fulfilled"
    CANCELLED = "cancelled"
    RETURNED = "returned"


class PurchaseOrderStatus(models.TextChoices):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    APPROVED = "approved"
    PARTIALLY_RECEIVED = "partially_received"
    RECEIVED = "received"
    CANCELLED = "cancelled"


class PosSessionStatus(models.TextChoices):
    OPEN = "open"
    CLOSED = "closed"


class CommerceMerchant(models.Model):
    """MOS profile layered on enterprise.Merchant — no second money identity."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    merchant = models.OneToOneField(
        "enterprise.Merchant",
        on_delete=models.CASCADE,
        related_name="commerce_profile",
    )
    business_type = models.CharField(
        max_length=32, choices=BusinessType.choices, default=BusinessType.RETAIL
    )
    operating_hours = models.JSONField(default=dict, blank=True)
    default_currency = models.CharField(max_length=8, default="TZS")
    tax_inclusive = models.BooleanField(default=True)
    settings = models.JSONField(default=dict, blank=True)
    documents = models.JSONField(default=list, blank=True)
    winga_enabled = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self) -> str:
        return f"MOS:{self.merchant.code}"


class Branch(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="branches"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=255)
    address = models.JSONField(default=dict, blank=True)
    is_hq = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("commerce_merchant", "code")]
        ordering = ["name"]


class StaffMembership(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="staff"
    )
    branch = models.ForeignKey(
        Branch, null=True, blank=True, on_delete=models.SET_NULL, related_name="staff"
    )
    principal = models.CharField(max_length=128, db_index=True)
    display_name = models.CharField(max_length=255, blank=True, default="")
    role = models.CharField(max_length=32, choices=StaffRole.choices, default=StaffRole.CASHIER)
    permissions = models.JSONField(default=list, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("commerce_merchant", "principal")]


class CatalogCategory(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="categories"
    )
    parent = models.ForeignKey(
        "self", null=True, blank=True, on_delete=models.SET_NULL, related_name="children"
    )
    name = models.CharField(max_length=128)
    slug = models.SlugField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("commerce_merchant", "slug")]


class Brand(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="brands"
    )
    name = models.CharField(max_length=128)
    created_at = models.DateTimeField(auto_now_add=True)


class Product(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="products"
    )
    category = models.ForeignKey(
        CatalogCategory, null=True, blank=True, on_delete=models.SET_NULL, related_name="products"
    )
    brand = models.ForeignKey(
        Brand, null=True, blank=True, on_delete=models.SET_NULL, related_name="products"
    )
    kind = models.CharField(max_length=16, choices=ProductKind.choices, default=ProductKind.PHYSICAL)
    sku = models.CharField(max_length=64)
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True, default="")
    unit = models.CharField(max_length=32, default="ea")
    currency = models.CharField(max_length=8, default="TZS")
    price_minor = models.BigIntegerField(default=0)
    cost_minor = models.BigIntegerField(default=0)
    tax_bps = models.PositiveIntegerField(default=0)
    images = models.JSONField(default=list, blank=True)
    attributes = models.JSONField(default=dict, blank=True)
    seo = models.JSONField(default=dict, blank=True)
    track_inventory = models.BooleanField(default=True)
    track_serial = models.BooleanField(default=False)
    track_batch = models.BooleanField(default=False)
    track_expiry = models.BooleanField(default=False)
    winga_offering_id = models.UUIDField(null=True, blank=True, db_index=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [("commerce_merchant", "sku")]
        indexes = [models.Index(fields=["commerce_merchant", "active"])]


class ProductVariant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="variants")
    sku = models.CharField(max_length=64)
    name = models.CharField(max_length=128)
    price_minor = models.BigIntegerField(null=True, blank=True)
    attributes = models.JSONField(default=dict, blank=True)
    barcode = models.CharField(max_length=64, blank=True, default="", db_index=True)
    active = models.BooleanField(default=True)

    class Meta:
        unique_together = [("product", "sku")]


class Warehouse(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="warehouses"
    )
    branch = models.ForeignKey(
        Branch, null=True, blank=True, on_delete=models.SET_NULL, related_name="warehouses"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=255)
    is_default = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("commerce_merchant", "code")]


class StockItem(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    warehouse = models.ForeignKey(Warehouse, on_delete=models.CASCADE, related_name="stock")
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name="stock")
    variant = models.ForeignKey(
        ProductVariant, null=True, blank=True, on_delete=models.CASCADE, related_name="stock"
    )
    on_hand = models.DecimalField(max_digits=18, decimal_places=3, default=0)
    reserved = models.DecimalField(max_digits=18, decimal_places=3, default=0)
    reorder_point = models.DecimalField(max_digits=18, decimal_places=3, default=0)
    batch_no = models.CharField(max_length=64, blank=True, default="")
    serial_no = models.CharField(max_length=64, blank=True, default="")
    expires_on = models.DateField(null=True, blank=True)
    unit_cost_minor = models.BigIntegerField(default=0)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=["warehouse", "product"])]

    @property
    def available(self):
        return self.on_hand - self.reserved


class StockMovement(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    stock_item = models.ForeignKey(StockItem, on_delete=models.CASCADE, related_name="movements")
    kind = models.CharField(max_length=16, choices=StockMovementKind.choices)
    quantity = models.DecimalField(max_digits=18, decimal_places=3)
    reference = models.CharField(max_length=128, blank=True, default="")
    actor = models.CharField(max_length=128, blank=True, default="")
    note = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]


class Supplier(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="suppliers"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=255)
    contacts = models.JSONField(default=list, blank=True)
    payment_terms = models.CharField(max_length=128, blank=True, default="")
    rating_e4 = models.PositiveIntegerField(default=5000)
    metadata = models.JSONField(default=dict, blank=True)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("commerce_merchant", "code")]


class PurchaseOrder(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="purchase_orders"
    )
    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, related_name="purchase_orders")
    warehouse = models.ForeignKey(Warehouse, on_delete=models.PROTECT, related_name="purchase_orders")
    status = models.CharField(
        max_length=32, choices=PurchaseOrderStatus.choices, default=PurchaseOrderStatus.DRAFT
    )
    currency = models.CharField(max_length=8, default="TZS")
    lines = models.JSONField(default=list, blank=True)
    total_minor = models.BigIntegerField(default=0)
    reference = models.CharField(max_length=64, blank=True, default="")
    created_by = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)


class CustomerProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="customers"
    )
    principal = models.CharField(max_length=128, blank=True, default="", db_index=True)
    display_name = models.CharField(max_length=255)
    phone = models.CharField(max_length=32, blank=True, default="")
    email = models.CharField(max_length=255, blank=True, default="")
    segment = models.CharField(max_length=64, blank=True, default="")
    loyalty_points = models.PositiveIntegerField(default=0)
    credit_limit_minor = models.BigIntegerField(default=0)
    notes = models.TextField(blank=True, default="")
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=["commerce_merchant", "phone"])]


class SalesOrder(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="orders"
    )
    branch = models.ForeignKey(
        Branch, null=True, blank=True, on_delete=models.SET_NULL, related_name="orders"
    )
    warehouse = models.ForeignKey(
        Warehouse, null=True, blank=True, on_delete=models.SET_NULL, related_name="orders"
    )
    customer = models.ForeignKey(
        CustomerProfile, null=True, blank=True, on_delete=models.SET_NULL, related_name="orders"
    )
    channel = models.CharField(max_length=16, choices=OrderChannel.choices, default=OrderChannel.POS)
    status = models.CharField(max_length=32, choices=OrderStatus.choices, default=OrderStatus.DRAFT)
    currency = models.CharField(max_length=8, default="TZS")
    subtotal_minor = models.BigIntegerField(default=0)
    discount_minor = models.BigIntegerField(default=0)
    tax_minor = models.BigIntegerField(default=0)
    total_minor = models.BigIntegerField(default=0)
    payer_principal = models.CharField(max_length=128, blank=True, default="")
    payment_ref = models.CharField(max_length=64, blank=True, default="", db_index=True)
    paid = models.BooleanField(default=False)
    mobility_job_ref = models.CharField(max_length=64, blank=True, default="")
    winga_deal_id = models.UUIDField(null=True, blank=True)
    timeline = models.JSONField(default=list, blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_by = models.CharField(max_length=128, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["commerce_merchant", "status"])]


class SalesOrderLine(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(SalesOrder, on_delete=models.CASCADE, related_name="lines")
    product = models.ForeignKey(Product, on_delete=models.PROTECT, related_name="order_lines")
    variant = models.ForeignKey(
        ProductVariant, null=True, blank=True, on_delete=models.SET_NULL, related_name="order_lines"
    )
    description = models.CharField(max_length=255, blank=True, default="")
    quantity = models.DecimalField(max_digits=18, decimal_places=3, default=1)
    unit_price_minor = models.BigIntegerField()
    discount_minor = models.BigIntegerField(default=0)
    tax_minor = models.BigIntegerField(default=0)
    line_total_minor = models.BigIntegerField()
    fulfilled_qty = models.DecimalField(max_digits=18, decimal_places=3, default=0)


class PosSession(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="pos_sessions"
    )
    branch = models.ForeignKey(Branch, on_delete=models.PROTECT, related_name="pos_sessions")
    cashier_principal = models.CharField(max_length=128)
    status = models.CharField(
        max_length=16, choices=PosSessionStatus.choices, default=PosSessionStatus.OPEN
    )
    opening_float_minor = models.BigIntegerField(default=0)
    closing_cash_minor = models.BigIntegerField(null=True, blank=True)
    opened_at = models.DateTimeField(auto_now_add=True)
    closed_at = models.DateTimeField(null=True, blank=True)
    metadata = models.JSONField(default=dict, blank=True)


class Promotion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="promotions"
    )
    code = models.SlugField(max_length=64)
    name = models.CharField(max_length=128)
    kind = models.CharField(max_length=32, default="percent")  # percent|flat|bogo|coupon
    value = models.PositiveIntegerField(default=0)  # bps or minor
    active = models.BooleanField(default=True)
    starts_at = models.DateTimeField(null=True, blank=True)
    ends_at = models.DateTimeField(null=True, blank=True)
    rules = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [("commerce_merchant", "code")]


class CommerceDocument(models.Model):
    """Document metadata — generation payloads reuse Taifa Documents patterns."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    commerce_merchant = models.ForeignKey(
        CommerceMerchant, on_delete=models.CASCADE, related_name="commerce_documents"
    )
    kind = models.CharField(max_length=32)  # invoice|receipt|po|delivery_note|credit_note
    reference = models.CharField(max_length=64)
    related_order_id = models.UUIDField(null=True, blank=True)
    payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
