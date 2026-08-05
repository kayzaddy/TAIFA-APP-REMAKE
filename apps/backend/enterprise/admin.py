from django.contrib import admin

from . import models


@admin.register(models.Merchant)
class MerchantAdmin(admin.ModelAdmin):
    list_display = ["code", "legal_name", "status", "settlement_mode", "sector", "created_at"]
    list_filter = ["status", "sector", "settlement_mode"]
    search_fields = ["code", "legal_name"]


@admin.register(models.MerchantSettlement)
class MerchantSettlementAdmin(admin.ModelAdmin):
    list_display = ["id", "merchant", "status", "net_minor", "currency", "created_at"]
    list_filter = ["status"]
    readonly_fields = ["transaction", "statement_ref"]


@admin.register(models.ChargebackCase)
class ChargebackAdmin(admin.ModelAdmin):
    list_display = ["id", "merchant", "status", "amount_minor", "reason_code", "created_at"]
    list_filter = ["status"]


@admin.register(models.TreasuryBankAccount)
class TreasuryAccountAdmin(admin.ModelAdmin):
    list_display = ["code", "bank_name", "kind", "currency", "is_active"]


@admin.register(models.BusinessRule)
class BusinessRuleAdmin(admin.ModelAdmin):
    list_display = ["code", "category", "priority", "active", "version"]
    list_filter = ["category", "active"]


@admin.register(models.ApprovalRequest)
class ApprovalAdmin(admin.ModelAdmin):
    list_display = ["id", "action", "maker", "checker", "status", "amount_minor", "created_at"]
    list_filter = ["status", "action"]


@admin.register(models.RegulatoryReport)
class RegulatoryReportAdmin(admin.ModelAdmin):
    list_display = ["report_type", "period_start", "period_end", "status", "created_at"]
    list_filter = ["report_type"]
