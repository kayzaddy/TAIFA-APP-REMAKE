from django.contrib import admin

from . import models


@admin.register(models.ExpressStore)
class ExpressStoreAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "category", "rating", "verified", "active")
    list_filter = ("category", "active", "verified")
    search_fields = ("code", "name")


@admin.register(models.ExpressProduct)
class ExpressProductAdmin(admin.ModelAdmin):
    list_display = ("sku", "name", "store", "price_minor", "stock_qty", "active")
    list_filter = ("active", "stock_status")
    search_fields = ("sku", "name", "store__code")


@admin.register(models.ExpressOrder)
class ExpressOrderAdmin(admin.ModelAdmin):
    list_display = (
        "public_code",
        "owner",
        "status",
        "store",
        "total_minor",
        "payment_ref",
        "created_at",
    )
    list_filter = ("status",)
    search_fields = ("public_code", "owner", "payment_ref")
