"""Django admin — financial objects are read-only.

Corrections happen only through the Payment Orchestrator + compensating journals.
Staff may inspect, never mutate money, ledger, or payment lifecycle fields.
"""
from __future__ import annotations

from django.contrib import admin

from .models import (
    AuditRecord,
    Device,
    DomainEvent,
    IdempotencyKey,
    LedgerAccount,
    LedgerEntry,
    Posting,
    ReconciliationException,
    SettlementBatch,
    SettlementLine,
    Transaction,
    WebhookEvent,
    WebhookReplayGuard,
)


class FinancialReadOnlyAdmin(admin.ModelAdmin):
    """Forbid add / change / delete on financial and audit records."""

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


class PostingInline(admin.TabularInline):
    model = Posting
    extra = 0
    can_delete = False
    readonly_fields = [
        "account",
        "direction",
        "amount_minor",
        "currency",
        "base_currency",
        "fx_rate_e8",
        "base_amount_minor",
        "created_at",
    ]


@admin.register(LedgerEntry)
class LedgerEntryAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "kind", "description", "transaction", "created_at"]
    inlines = [PostingInline]
    readonly_fields = ["id", "transaction", "description", "kind", "reverses", "created_at"]


@admin.register(Transaction)
class TransactionAdmin(FinancialReadOnlyAdmin):
    list_display = [
        "id",
        "owner",
        "type",
        "status",
        "direction",
        "amount_minor",
        "currency",
        "counterparty",
        "provider",
        "created_at",
    ]
    list_filter = ["type", "status", "currency", "provider"]
    search_fields = ["id", "owner", "counterparty", "provider_ref", "idempotency_key"]
    readonly_fields = [
        "id",
        "owner",
        "type",
        "status",
        "direction",
        "amount_minor",
        "fee_minor",
        "currency",
        "counterparty",
        "method_kind",
        "method_label",
        "method_ref",
        "operator",
        "idempotency_key",
        "note",
        "provider",
        "provider_ref",
        "parent",
        "ledger_entry",
        "created_at",
        "updated_at",
    ]


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ["device_id", "owner", "platform", "label", "created_at", "last_seen_at"]
    search_fields = ["device_id", "owner", "label"]
    readonly_fields = ["token_hash", "created_at", "last_seen_at"]


@admin.register(LedgerAccount)
class LedgerAccountAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "account_type", "currency", "owner"]
    list_filter = ["account_type", "currency"]
    readonly_fields = ["id", "account_type", "currency", "owner", "created_at"]


@admin.register(IdempotencyKey)
class IdempotencyKeyAdmin(FinancialReadOnlyAdmin):
    list_display = ["key", "scope", "status", "transaction", "created_at"]
    list_filter = ["scope", "status"]


@admin.register(WebhookEvent)
class WebhookEventAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "provider", "event_type", "provider_ref", "processed", "result", "received_at"]
    list_filter = ["provider", "processed", "result"]


@admin.register(DomainEvent)
class DomainEventAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "event_type", "owner", "transaction", "created_at"]
    list_filter = ["event_type"]


@admin.register(AuditRecord)
class AuditRecordAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "actor", "action", "resource_type", "resource_id", "created_at"]
    list_filter = ["action"]


@admin.register(WebhookReplayGuard)
class WebhookReplayGuardAdmin(FinancialReadOnlyAdmin):
    list_display = ["fingerprint", "provider", "provider_ref", "created_at"]


@admin.register(SettlementBatch)
class SettlementBatchAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "provider", "filename", "status", "line_count", "received_at"]


@admin.register(SettlementLine)
class SettlementLineAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "batch", "provider_ref", "amount_minor", "currency", "match_status"]
    list_filter = ["match_status", "currency"]


@admin.register(ReconciliationException)
class ReconciliationExceptionAdmin(FinancialReadOnlyAdmin):
    list_display = ["id", "batch", "code", "provider_ref", "created_at"]
    list_filter = ["code"]
