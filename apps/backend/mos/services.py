"""MOS domain services — inventory, orders, payments via enterprise, Winga publish."""
from __future__ import annotations

from decimal import Decimal

from django.db import transaction
from django.utils import timezone

from enterprise.models import Merchant, MerchantStatus
from enterprise.orchestrator import PlatformContext, PlatformError, PlatformOrchestrator
from payments.money import Currency, Money

from . import metrics
from .models import (
    Branch,
    CommerceMerchant,
    OrderChannel,
    OrderStatus,
    Product,
    ProductKind,
    SalesOrder,
    SalesOrderLine,
    StockItem,
    StockMovement,
    StockMovementKind,
    Warehouse,
)


class MosError(Exception):
    pass


def ensure_commerce_merchant(*, merchant: Merchant, business_type: str = "retail") -> CommerceMerchant:
    profile, _ = CommerceMerchant.objects.get_or_create(
        merchant=merchant,
        defaults={"business_type": business_type, "default_currency": merchant.settlement_currency},
    )
    return profile


@transaction.atomic
def bootstrap_merchant_ops(
    *,
    merchant: Merchant,
    business_type: str = "retail",
    hq_name: str = "Main Branch",
    actor: str = "ops",
) -> tuple[CommerceMerchant, Branch, Warehouse]:
    if merchant.status != MerchantStatus.ACTIVE:
        raise MosError("merchant must be ACTIVE")
    cm = ensure_commerce_merchant(merchant=merchant, business_type=business_type)
    branch, _ = Branch.objects.get_or_create(
        commerce_merchant=cm,
        code="hq",
        defaults={"name": hq_name, "is_hq": True},
    )
    wh, _ = Warehouse.objects.get_or_create(
        commerce_merchant=cm,
        code="main",
        defaults={"name": "Main Warehouse", "branch": branch, "is_default": True},
    )
    metrics.merchants_bootstrapped.inc()
    return cm, branch, wh


@transaction.atomic
def adjust_stock(
    *,
    stock_item: StockItem,
    kind: str,
    quantity: Decimal,
    actor: str = "",
    reference: str = "",
    note: str = "",
) -> StockItem:
    qty = Decimal(quantity)
    if qty <= 0:
        raise MosError("quantity must be positive")

    item = StockItem.objects.select_for_update().get(pk=stock_item.pk)
    if kind in (StockMovementKind.RECEIVE, StockMovementKind.TRANSFER_IN, StockMovementKind.RETURN):
        item.on_hand += qty
    elif kind in (StockMovementKind.ISSUE, StockMovementKind.TRANSFER_OUT):
        if item.available < qty:
            raise MosError("insufficient available stock")
        item.on_hand -= qty
    elif kind == StockMovementKind.ADJUST:
        item.on_hand = qty  # absolute set via adjust semantics: quantity = new on_hand
    elif kind == StockMovementKind.RESERVE:
        if item.available < qty:
            raise MosError("insufficient available stock")
        item.reserved += qty
    elif kind == StockMovementKind.RELEASE:
        item.reserved = max(Decimal("0"), item.reserved - qty)
    elif kind == StockMovementKind.COUNT:
        item.on_hand = qty
    else:
        raise MosError(f"unsupported movement kind: {kind}")

    item.save(update_fields=["on_hand", "reserved", "updated_at"])
    StockMovement.objects.create(
        stock_item=item,
        kind=kind,
        quantity=qty,
        reference=reference,
        actor=actor,
        note=note,
    )
    metrics.stock_movements.labels(kind=kind).inc()
    return item


def get_or_create_stock(*, warehouse: Warehouse, product: Product, variant=None) -> StockItem:
    item, _ = StockItem.objects.get_or_create(
        warehouse=warehouse,
        product=product,
        variant=variant,
        defaults={"on_hand": Decimal("0"), "reserved": Decimal("0")},
    )
    return item


@transaction.atomic
def create_sales_order(
    *,
    commerce_merchant: CommerceMerchant,
    lines: list[dict],
    channel: str = OrderChannel.POS,
    branch: Branch | None = None,
    warehouse: Warehouse | None = None,
    customer=None,
    payer_principal: str = "",
    created_by: str = "",
    discount_minor: int = 0,
) -> SalesOrder:
    if not lines:
        raise MosError("order requires lines")
    wh = warehouse or commerce_merchant.warehouses.filter(is_default=True, active=True).first()
    order = SalesOrder.objects.create(
        commerce_merchant=commerce_merchant,
        branch=branch,
        warehouse=wh,
        customer=customer,
        channel=channel,
        status=OrderStatus.OPEN,
        currency=commerce_merchant.default_currency,
        payer_principal=payer_principal,
        created_by=created_by,
        discount_minor=discount_minor,
        timeline=[{"at": timezone.now().isoformat(), "event": "created", "actor": created_by}],
    )
    subtotal = 0
    tax = 0
    for row in lines:
        product = Product.objects.get(pk=row["product_id"], commerce_merchant=commerce_merchant)
        qty = Decimal(str(row.get("quantity", 1)))
        unit = int(row.get("unit_price_minor", product.price_minor))
        line_disc = int(row.get("discount_minor", 0))
        line_tax = int(row.get("tax_minor", 0))
        line_total = int(unit * qty) - line_disc + line_tax
        SalesOrderLine.objects.create(
            order=order,
            product=product,
            variant_id=row.get("variant_id"),
            description=product.name,
            quantity=qty,
            unit_price_minor=unit,
            discount_minor=line_disc,
            tax_minor=line_tax,
            line_total_minor=line_total,
        )
        subtotal += int(unit * qty) - line_disc
        tax += line_tax
        if product.track_inventory and product.kind == ProductKind.PHYSICAL and wh:
            stock = get_or_create_stock(warehouse=wh, product=product)
            adjust_stock(
                stock_item=stock,
                kind=StockMovementKind.RESERVE,
                quantity=qty,
                actor=created_by,
                reference=str(order.id),
                note="order reserve",
            )
    order.subtotal_minor = subtotal
    order.tax_minor = tax
    order.total_minor = max(0, subtotal + tax - discount_minor)
    order.save(update_fields=["subtotal_minor", "tax_minor", "total_minor", "updated_at"])
    metrics.orders_created.labels(channel=channel).inc()
    return order


@transaction.atomic
def pay_sales_order(
    *,
    order: SalesOrder,
    payer_principal: str,
    idempotency_key: str,
    actor: str = "",
) -> SalesOrder:
    if order.paid:
        return order
    if order.status in (OrderStatus.CANCELLED, OrderStatus.DRAFT):
        raise MosError("order not payable")
    merchant = order.commerce_merchant.merchant
    if merchant.status != MerchantStatus.ACTIVE:
        raise MosError("merchant not active")
    currency = Currency.from_code(order.currency or "TZS")
    try:
        txn = PlatformOrchestrator().capture_merchant_payment(
            ctx=PlatformContext(actor=actor or payer_principal),
            merchant=merchant,
            payer_owner=payer_principal,
            amount=Money(order.total_minor, currency),
            idempotency_key=idempotency_key,
            note=f"mos-order:{order.id}",
        )
    except PlatformError as exc:
        raise MosError(str(exc)) from exc

    order.payment_ref = str(txn.id)
    order.paid = True
    order.payer_principal = payer_principal
    order.status = OrderStatus.CONFIRMED
    timeline = list(order.timeline or [])
    timeline.append({"at": timezone.now().isoformat(), "event": "paid", "payment_ref": order.payment_ref})
    order.timeline = timeline
    order.save(
        update_fields=["payment_ref", "paid", "payer_principal", "status", "timeline", "updated_at"]
    )
    metrics.orders_paid.inc()
    return order


@transaction.atomic
def fulfill_sales_order(*, order: SalesOrder, actor: str = "") -> SalesOrder:
    if not order.paid:
        raise MosError("order must be paid before fulfillment")
    wh = order.warehouse
    for line in order.lines.select_related("product"):
        remaining = line.quantity - line.fulfilled_qty
        if remaining <= 0:
            continue
        if line.product.track_inventory and wh:
            stock = get_or_create_stock(warehouse=wh, product=line.product, variant=line.variant)
            # release reserve then issue
            adjust_stock(
                stock_item=stock,
                kind=StockMovementKind.RELEASE,
                quantity=remaining,
                actor=actor,
                reference=str(order.id),
            )
            adjust_stock(
                stock_item=stock,
                kind=StockMovementKind.ISSUE,
                quantity=remaining,
                actor=actor,
                reference=str(order.id),
                note="fulfillment",
            )
        line.fulfilled_qty = line.quantity
        line.save(update_fields=["fulfilled_qty"])
    order.status = OrderStatus.FULFILLED
    timeline = list(order.timeline or [])
    timeline.append({"at": timezone.now().isoformat(), "event": "fulfilled", "actor": actor})
    order.timeline = timeline
    order.save(update_fields=["status", "timeline", "updated_at"])
    metrics.orders_fulfilled.inc()
    return order


@transaction.atomic
def publish_product_to_winga(*, product: Product, domain_code: str = "retail") -> Product:
    """Publish MOS product as Winga Offering for brokerage discovery — no money duplication."""
    from winga.models import BrokerageDomain, Offering, OfferingKind, ProviderProfile, VerificationStatus

    merchant = product.commerce_merchant.merchant
    provider, _ = ProviderProfile.objects.get_or_create(
        principal=f"mos:{merchant.code}",
        defaults={
            "legal_name": merchant.legal_name,
            "trading_name": merchant.trading_name or merchant.legal_name,
            "verification_status": VerificationStatus.VERIFIED,
            "merchant": merchant,
        },
    )
    if provider.merchant_id != merchant.id:
        provider.merchant = merchant
        provider.save(update_fields=["merchant"])

    domain = BrokerageDomain.objects.filter(code=domain_code).first()
    if domain is None:
        domain = BrokerageDomain.objects.filter(active=True).first()
    if domain is None:
        raise MosError("no winga domain available — run seed_winga")

    kind_map = {
        ProductKind.PHYSICAL: OfferingKind.PRODUCT,
        ProductKind.DIGITAL: OfferingKind.DIGITAL,
        ProductKind.SERVICE: OfferingKind.SERVICE,
        ProductKind.SUBSCRIPTION: OfferingKind.DIGITAL,
        ProductKind.BUNDLE: OfferingKind.PRODUCT,
    }
    offering_kind = kind_map.get(product.kind, OfferingKind.PRODUCT)
    if product.winga_offering_id:
        offering = Offering.objects.filter(pk=product.winga_offering_id).first()
    else:
        offering = None
    if offering is None:
        offering = Offering.objects.create(
            provider=provider,
            domain=domain,
            kind=offering_kind,
            title=product.name,
            description=product.description,
            currency=product.currency,
            price_minor=product.price_minor,
            attributes={"mos_product_id": str(product.id), "sku": product.sku},
            active=product.active,
        )
    else:
        offering.title = product.name
        offering.description = product.description
        offering.price_minor = product.price_minor
        offering.active = product.active
        offering.save()

    product.winga_offering_id = offering.id
    product.commerce_merchant.winga_enabled = True
    product.commerce_merchant.save(update_fields=["winga_enabled", "updated_at"])
    product.save(update_fields=["winga_offering_id", "updated_at"])
    metrics.winga_publishes.inc()
    return product


def analytics_summary(*, commerce_merchant: CommerceMerchant) -> dict:
    from django.db.models import Sum

    orders = SalesOrder.objects.filter(commerce_merchant=commerce_merchant)
    paid = orders.filter(paid=True)
    return {
        "products": Product.objects.filter(commerce_merchant=commerce_merchant, active=True).count(),
        "orders_total": orders.count(),
        "orders_paid": paid.count(),
        "gmv_minor": paid.aggregate(s=Sum("total_minor"))["s"] or 0,
        "customers": commerce_merchant.customers.count(),
        "warehouses": commerce_merchant.warehouses.filter(active=True).count(),
        "low_stock": _low_stock_count(commerce_merchant),
        "winga_enabled": commerce_merchant.winga_enabled,
    }


def _low_stock_count(commerce_merchant: CommerceMerchant) -> int:
    n = 0
    for item in StockItem.objects.filter(warehouse__commerce_merchant=commerce_merchant).only(
        "on_hand", "reorder_point"
    ):
        if item.on_hand <= item.reorder_point:
            n += 1
    return n
