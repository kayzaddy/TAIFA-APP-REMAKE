from django.contrib import admin

from . import models


@admin.register(models.AcceptanceProfile)
class AcceptanceProfileAdmin(admin.ModelAdmin):
    list_display = ("display_name", "merchant", "qr_identity", "active", "default_currency")
    search_fields = ("display_name", "qr_identity", "merchant__code")


@admin.register(models.AcceptanceIntent)
class AcceptanceIntentAdmin(admin.ModelAdmin):
    list_display = ("public_code", "merchant", "channel", "status", "amount_minor", "currency")
    list_filter = ("channel", "status")
    search_fields = ("public_code", "payment_ref")


admin.site.register(models.QrArtifact)
admin.site.register(models.PaymentLink)
admin.site.register(models.DigitalInvoice)
admin.site.register(models.CheckoutSession)
admin.site.register(models.AcceptanceTerminal)
admin.site.register(models.AcceptanceReceipt)
