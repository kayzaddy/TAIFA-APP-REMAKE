from django.contrib import admin

from payments import audit

from .models import (
    BlacklistEntry,
    ComplianceFinding,
    CompliancePolicy,
    DriverRegistration,
    ExternalVerificationRequest,
    FleetRegistration,
    RegistryApplication,
    RegistryDocument,
    RegistryNotification,
    StationRegistration,
    VehicleRegistration,
    WorkflowTransition,
)


@admin.register(RegistryApplication)
class RegistryApplicationAdmin(admin.ModelAdmin):
    list_display = [
        "application_number",
        "application_type",
        "status",
        "stage",
        "region",
        "district",
        "created_at",
    ]
    list_filter = ["application_type", "status", "stage", "region"]
    search_fields = ["application_number", "applicant_principal"]
    readonly_fields = [
        "application_number",
        "status",
        "stage",
        "approval_reference",
        "operational_object_id",
        "version",
        "submitted_at",
        "approved_at",
        "rejected_at",
        "suspended_at",
        "created_at",
        "updated_at",
    ]

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


class SensitiveProfileAdmin(admin.ModelAdmin):
    sensitive_fields = [
        "national_id_ciphertext",
        "national_id_nonce",
        "passport_ciphertext",
        "passport_nonce",
        "phone_ciphertext",
        "phone_nonce",
        "emergency_phone_ciphertext",
        "emergency_phone_nonce",
        "bank_account_ciphertext",
        "bank_account_nonce",
        "chassis_number_ciphertext",
        "chassis_number_nonce",
        "engine_number_ciphertext",
        "engine_number_nonce",
        "brela_number_ciphertext",
        "brela_number_nonce",
        "tin_ciphertext",
        "tin_nonce",
        "bank_details_ciphertext",
        "bank_details_nonce",
    ]

    def get_exclude(self, request, obj=None):
        return [name for name in self.sensitive_fields if hasattr(self.model, name)]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


admin.site.register(DriverRegistration, SensitiveProfileAdmin)
admin.site.register(VehicleRegistration, SensitiveProfileAdmin)
admin.site.register(StationRegistration, SensitiveProfileAdmin)
admin.site.register(FleetRegistration, SensitiveProfileAdmin)


@admin.register(RegistryDocument)
class RegistryDocumentAdmin(admin.ModelAdmin):
    list_display = ["id", "application", "kind", "version", "status", "expiry_date"]
    list_filter = ["kind", "status", "current"]
    exclude = [
        "encrypted_payload",
        "encryption_nonce",
        "document_number_ciphertext",
        "document_number_nonce",
    ]

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


class AppendOnlyAdmin(admin.ModelAdmin):
    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False


admin.site.register(WorkflowTransition, AppendOnlyAdmin)
admin.site.register(ExternalVerificationRequest, AppendOnlyAdmin)
admin.site.register(RegistryNotification, AppendOnlyAdmin)

@admin.register(CompliancePolicy)
class CompliancePolicyAdmin(admin.ModelAdmin):
    list_display = ["code", "application_type", "version", "effective_from", "active"]

    def has_change_permission(self, request, obj=None):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def save_model(self, request, obj, form, change):
        super().save_model(request, obj, form, change)
        audit.record(
            actor=str(request.user),
            action="mobility_registry.policy.create",
            resource_type="registry_compliance_policy",
            resource_id=str(obj.pk),
            after={
                "code": obj.code,
                "application_type": obj.application_type,
                "version": obj.version,
            },
        )


admin.site.register(ComplianceFinding, AppendOnlyAdmin)
admin.site.register(BlacklistEntry, AppendOnlyAdmin)
