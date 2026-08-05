from django.contrib import admin

from .models import (
    PropertyApplication,
    PropertyCategory,
    PropertyFavorite,
    PropertyLease,
    PropertyLeasePayment,
    PropertyListing,
    PropertyLiveMessage,
    PropertyLiveSession,
    PropertyMedia,
    PropertyMoveWorkflow,
    PropertyModerationReport,
    PropertyDispute,
    PropertyOpsAuditEvent,
    PropertyOwner,
    PropertySharedDocument,
    PropertyTimelineEvent,
    PropertyType,
    PropertyVerificationEvent,
    PropertyViewEvent,
    PropertyViewingAppointment,
    PropertyViewingPass,
    PropertyWingaAssignment,
    SavedSearch,
)


@admin.register(PropertyCategory)
class PropertyCategoryAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "sort_order", "active")
    list_filter = ("active",)
    search_fields = ("code", "name")


@admin.register(PropertyType)
class PropertyTypeAdmin(admin.ModelAdmin):
    list_display = ("code", "name", "category", "active")
    list_filter = ("category", "active")
    search_fields = ("code", "name")


@admin.register(PropertyOwner)
class PropertyOwnerAdmin(admin.ModelAdmin):
    list_display = ("display_name", "principal", "role", "verification_status", "active")
    list_filter = ("role", "verification_status", "active")
    search_fields = ("display_name", "principal", "phone")


class PropertyMediaInline(admin.TabularInline):
    model = PropertyMedia
    extra = 0


@admin.register(PropertyListing)
class PropertyListingAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "owner",
        "transaction_type",
        "price_minor",
        "region",
        "verification_status",
        "active",
    )
    list_filter = ("verification_status", "transaction_type", "region", "active")
    search_fields = ("title", "address_line", "ward", "district")
    inlines = [PropertyMediaInline]


@admin.register(PropertyFavorite)
class PropertyFavoriteAdmin(admin.ModelAdmin):
    list_display = ("principal", "listing", "created_at")
    search_fields = ("principal",)


@admin.register(SavedSearch)
class SavedSearchAdmin(admin.ModelAdmin):
    list_display = ("name", "principal", "active", "updated_at")
    list_filter = ("active",)


@admin.register(PropertyVerificationEvent)
class PropertyVerificationEventAdmin(admin.ModelAdmin):
    list_display = ("listing", "from_status", "to_status", "actor", "created_at")
    list_filter = ("to_status",)


@admin.register(PropertyViewEvent)
class PropertyViewEventAdmin(admin.ModelAdmin):
    list_display = ("principal", "listing", "viewed_at")
    search_fields = ("principal",)


@admin.register(PropertyViewingPass)
class PropertyViewingPassAdmin(admin.ModelAdmin):
    list_display = ("principal", "plan_code", "status", "amount_minor", "expires_at")
    list_filter = ("plan_code", "status")
    search_fields = ("principal", "qr_token")


@admin.register(PropertyLiveSession)
class PropertyLiveSessionAdmin(admin.ModelAdmin):
    list_display = ("listing", "status", "customer_principal", "owner_principal", "scheduled_at")
    list_filter = ("status",)
    search_fields = ("join_code", "customer_principal", "owner_principal")


@admin.register(PropertyLiveMessage)
class PropertyLiveMessageAdmin(admin.ModelAdmin):
    list_display = ("session", "sender_principal", "created_at")


@admin.register(PropertyWingaAssignment)
class PropertyWingaAssignmentAdmin(admin.ModelAdmin):
    list_display = ("listing", "customer_principal", "winga_principal", "status", "created_at")
    list_filter = ("status",)


@admin.register(PropertyTimelineEvent)
class PropertyTimelineEventAdmin(admin.ModelAdmin):
    list_display = ("assignment", "event_type", "title", "actor", "created_at")


@admin.register(PropertySharedDocument)
class PropertySharedDocumentAdmin(admin.ModelAdmin):
    list_display = ("assignment", "title", "shared_by", "created_at")


@admin.register(PropertyViewingAppointment)
class PropertyViewingAppointmentAdmin(admin.ModelAdmin):
    list_display = ("assignment", "scheduled_at", "status")


@admin.register(PropertyApplication)
class PropertyApplicationAdmin(admin.ModelAdmin):
    list_display = ("listing", "applicant_principal", "status", "submitted_at")
    list_filter = ("status",)


@admin.register(PropertyLease)
class PropertyLeaseAdmin(admin.ModelAdmin):
    list_display = ("listing", "tenant_principal", "status", "start_date", "end_date")
    list_filter = ("status",)


@admin.register(PropertyLeasePayment)
class PropertyLeasePaymentAdmin(admin.ModelAdmin):
    list_display = ("lease", "kind", "status", "amount_minor", "paid_at")
    list_filter = ("kind", "status")


@admin.register(PropertyMoveWorkflow)
class PropertyMoveWorkflowAdmin(admin.ModelAdmin):
    list_display = ("lease", "phase", "status", "scheduled_at")
    list_filter = ("phase", "status")


@admin.register(PropertyModerationReport)
class PropertyModerationReportAdmin(admin.ModelAdmin):
    list_display = ("listing", "reason", "status", "reporter_principal", "created_at")
    list_filter = ("reason", "status")


@admin.register(PropertyDispute)
class PropertyDisputeAdmin(admin.ModelAdmin):
    list_display = ("subject_type", "status", "opened_by", "assigned_ops", "created_at")
    list_filter = ("status", "subject_type")


@admin.register(PropertyOpsAuditEvent)
class PropertyOpsAuditEventAdmin(admin.ModelAdmin):
    list_display = ("action", "entity_type", "actor", "created_at")
    list_filter = ("action", "entity_type")
