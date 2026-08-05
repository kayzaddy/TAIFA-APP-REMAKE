from django.contrib import admin

from .models import (
    AdminCase,
    ChatMessage,
    ChatThread,
    DriverJob,
    EduPayment,
    FamilyTransfer,
    FlightBooking,
    FoodOrder,
    GovRequest,
    HealthAppointment,
    HousingInquiry,
    HudumaBooking,
    InsurancePolicy,
    JobAssignment,
    MerchantOrder,
    StayBooking,
    TourBooking,
    WealthContribution,
)


@admin.register(FoodOrder)
class FoodOrderAdmin(admin.ModelAdmin):
    list_display = ["id", "owner", "status", "restaurant_name", "total_minor", "created_at"]
    list_filter = ["status"]
    search_fields = ["owner", "restaurant_name", "payment_ref"]


@admin.register(StayBooking)
class StayBookingAdmin(admin.ModelAdmin):
    list_display = ["id", "owner", "status", "hotel_name", "confirmation_code", "total_minor", "created_at"]
    list_filter = ["status"]
    search_fields = ["owner", "hotel_name", "confirmation_code", "payment_ref"]


@admin.register(FlightBooking)
class FlightBookingAdmin(admin.ModelAdmin):
    list_display = ["id", "owner", "status", "flight_number", "origin_code", "destination_code", "pnr", "created_at"]
    list_filter = ["status"]
    search_fields = ["owner", "flight_number", "pnr", "payment_ref"]


@admin.register(GovRequest)
class GovRequestAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "service_title", "status", "applicant_name", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "service_id", "applicant_name", "reference")


@admin.register(HealthAppointment)
class HealthAppointmentAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "facility_name", "patient_name", "status", "slot_at", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "facility_id", "patient_name", "confirmation_code")


@admin.register(EduPayment)
class EduPaymentAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "school_name", "student_name", "status", "amount_minor", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "school_id", "student_name", "invoice_no")


@admin.register(HousingInquiry)
class HousingInquiryAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "listing_title", "status", "deposit_minor", "viewing_at", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "listing_id", "listing_title", "payment_ref")


@admin.register(WealthContribution)
class WealthContributionAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "circle_name", "status", "amount_minor", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "circle_id", "circle_name", "payment_ref")


@admin.register(JobAssignment)
class JobAssignmentAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "job_title", "status", "pay_minor", "kind", "created_at")
    list_filter = ("status", "kind")
    search_fields = ("owner", "job_id", "job_title", "payment_ref")


@admin.register(InsurancePolicy)
class InsurancePolicyAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "plan_name", "status", "premium_minor", "created_at")
    list_filter = ("status", "category")
    search_fields = ("owner", "plan_id", "policy_ref")


@admin.register(FamilyTransfer)
class FamilyTransferAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "member_name", "kind", "status", "amount_minor", "created_at")
    list_filter = ("status", "kind")
    search_fields = ("owner", "member_id", "member_name", "payment_ref")


@admin.register(HudumaBooking)
class HudumaBookingAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "service_title", "status", "price_minor", "slot_label", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "service_id", "service_title", "payment_ref")


@admin.register(MerchantOrder)
class MerchantOrderAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "customer_name", "status", "total_minor", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "customer_name", "items_label")


@admin.register(DriverJob)
class DriverJobAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "rider_name", "status", "fare_minor", "pickup", "created_at")
    list_filter = ("status",)
    search_fields = ("owner", "rider_name", "pickup", "dropoff")


@admin.register(ChatThread)
class ChatThreadAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "title", "unread", "updated_at")
    search_fields = ("owner", "title", "subtitle")


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "thread", "sender", "created_at")
    list_filter = ("sender",)
    search_fields = ("owner", "text")


@admin.register(AdminCase)
class AdminCaseAdmin(admin.ModelAdmin):
    list_display = ("id", "owner", "kind", "title", "status", "created_at")
    list_filter = ("kind", "status")
    search_fields = ("owner", "title", "subject")


@admin.register(TourBooking)
class TourBookingAdmin(admin.ModelAdmin):
    list_display = ["id", "owner", "status", "tour_title", "confirmation_code", "total_minor", "created_at"]
    list_filter = ["status"]
    search_fields = ["owner", "tour_title", "confirmation_code", "payment_ref"]
