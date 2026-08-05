from django.contrib import admin

from .models import (
    DispatchOffer,
    Driver,
    DriverLocation,
    DriverVerification,
    Fleet,
    MobilityDailyMetric,
    MobilityRegulatoryReport,
    PricingRule,
    Promotion,
    SafetyIncident,
    Station,
    StationQueueEntry,
    Trip,
    TripEvent,
    Vehicle,
    VehicleOperationalLog,
)


@admin.register(Trip)
class TripAdmin(admin.ModelAdmin):
    list_display = [
        "id",
        "owner",
        "status",
        "station",
        "driver",
        "pickup_name",
        "dropoff_name",
        "fare_minor",
        "created_at",
    ]
    list_filter = ["status", "vehicle_mode", "kind"]
    search_fields = ["owner", "pickup_name", "dropoff_name", "driver_name"]
    readonly_fields = [
        "owner",
        "status",
        "lifecycle_version",
        "fare_minor",
        "fare_breakdown",
        "pricing_rule_version",
        "payment_ref",
        "payment_transaction",
        "created_at",
        "updated_at",
    ]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


@admin.register(Station)
class StationAdmin(admin.ModelAdmin):
    list_display = ["code", "name", "region", "district", "capacity", "active"]
    list_filter = ["active", "region", "district"]
    search_fields = ["code", "name"]


@admin.register(Driver)
class DriverAdmin(admin.ModelAdmin):
    list_display = [
        "full_name",
        "status",
        "availability",
        "identity_status",
        "license_status",
        "station",
    ]
    list_filter = ["status", "availability", "identity_status", "license_status"]


@admin.register(Vehicle)
class VehicleAdmin(admin.ModelAdmin):
    list_display = [
        "registration_number",
        "mode",
        "status",
        "insurance_status",
        "road_license_status",
        "inspection_status",
    ]
    list_filter = ["mode", "status"]


admin.site.register(Fleet)
admin.site.register(DriverVerification)
admin.site.register(StationQueueEntry)
admin.site.register(PricingRule)
admin.site.register(Promotion)
admin.site.register(SafetyIncident)
admin.site.register(VehicleOperationalLog)
admin.site.register(MobilityDailyMetric)
admin.site.register(MobilityRegulatoryReport)


class AppendOnlyMobilityAdmin(admin.ModelAdmin):
    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


admin.site.register(TripEvent, AppendOnlyMobilityAdmin)
admin.site.register(DispatchOffer, AppendOnlyMobilityAdmin)
admin.site.register(DriverLocation, AppendOnlyMobilityAdmin)
