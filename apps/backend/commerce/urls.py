from django.urls import path

from . import views

app_name = "commerce"

urlpatterns = [
    path("food-orders", views.FoodOrderListCreateView.as_view(), name="food-orders"),
    path("food-orders/<uuid:order_id>", views.FoodOrderDetailView.as_view(), name="food-order-detail"),
    path("food-orders/<uuid:order_id>/pay", views.FoodOrderPayView.as_view(), name="food-order-pay"),
    path("stay-bookings", views.StayBookingListCreateView.as_view(), name="stay-bookings"),
    path("stay-bookings/<uuid:booking_id>", views.StayBookingDetailView.as_view(), name="stay-booking-detail"),
    path("stay-bookings/<uuid:booking_id>/pay", views.StayBookingPayView.as_view(), name="stay-booking-pay"),
    path("flight-bookings", views.FlightBookingListCreateView.as_view(), name="flight-bookings"),
    path("flight-bookings/<uuid:booking_id>", views.FlightBookingDetailView.as_view(), name="flight-booking-detail"),
    path(
        "flight-bookings/<uuid:booking_id>/pay",
        views.FlightBookingPayView.as_view(),
        name="flight-booking-pay",
    ),
    path("tour-bookings", views.TourBookingListCreateView.as_view(), name="tour-bookings"),
    path("tour-bookings/<uuid:booking_id>", views.TourBookingDetailView.as_view(), name="tour-booking-detail"),
    path("tour-bookings/<uuid:booking_id>/pay", views.TourBookingPayView.as_view(), name="tour-booking-pay"),
    path("winga-orders", views.WingaOrderListCreateView.as_view(), name="winga-orders"),
    path("winga-orders/<uuid:order_id>", views.WingaOrderDetailView.as_view(), name="winga-order-detail"),
    path("winga-orders/<uuid:order_id>/pay", views.WingaOrderPayView.as_view(), name="winga-order-pay"),
    path("winga-service-bookings", views.WingaServiceBookingListCreateView.as_view(), name="winga-service-bookings"),
    path("winga-shops", views.WingaShopApplicationListCreateView.as_view(), name="winga-shops"),
    path("gov-requests", views.GovRequestListCreateView.as_view(), name="gov-requests"),
    path("gov-requests/<uuid:request_id>", views.GovRequestDetailView.as_view(), name="gov-request-detail"),
    path("gov-requests/<uuid:request_id>/pay", views.GovRequestPayView.as_view(), name="gov-request-pay"),
    path("health-appointments", views.HealthAppointmentListCreateView.as_view(), name="health-appointments"),
    path(
        "health-appointments/<uuid:appointment_id>",
        views.HealthAppointmentDetailView.as_view(),
        name="health-appointment-detail",
    ),
    path(
        "health-appointments/<uuid:appointment_id>/pay",
        views.HealthAppointmentPayView.as_view(),
        name="health-appointment-pay",
    ),
    path("edu-payments", views.EduPaymentListCreateView.as_view(), name="edu-payments"),
    path("edu-payments/<uuid:payment_id>", views.EduPaymentDetailView.as_view(), name="edu-payment-detail"),
    path("edu-payments/<uuid:payment_id>/pay", views.EduPaymentPayView.as_view(), name="edu-payment-pay"),
    path("housing-inquiries", views.HousingInquiryListCreateView.as_view(), name="housing-inquiries"),
    path(
        "housing-inquiries/<uuid:inquiry_id>",
        views.HousingInquiryDetailView.as_view(),
        name="housing-inquiry-detail",
    ),
    path(
        "housing-inquiries/<uuid:inquiry_id>/pay",
        views.HousingInquiryPayView.as_view(),
        name="housing-inquiry-pay",
    ),
    path("wealth-contributions", views.WealthContributionListCreateView.as_view(), name="wealth-contributions"),
    path(
        "wealth-contributions/<uuid:contribution_id>",
        views.WealthContributionDetailView.as_view(),
        name="wealth-contribution-detail",
    ),
    path("job-assignments", views.JobAssignmentListCreateView.as_view(), name="job-assignments"),
    path(
        "job-assignments/<uuid:assignment_id>",
        views.JobAssignmentDetailView.as_view(),
        name="job-assignment-detail",
    ),
    path("insurance-policies", views.InsurancePolicyListCreateView.as_view(), name="insurance-policies"),
    path(
        "insurance-policies/<uuid:policy_id>",
        views.InsurancePolicyDetailView.as_view(),
        name="insurance-policy-detail",
    ),
    path("family-transfers", views.FamilyTransferListCreateView.as_view(), name="family-transfers"),
    path(
        "family-transfers/<uuid:transfer_id>",
        views.FamilyTransferDetailView.as_view(),
        name="family-transfer-detail",
    ),
    path("huduma-bookings", views.HudumaBookingListCreateView.as_view(), name="huduma-bookings"),
    path(
        "huduma-bookings/<uuid:booking_id>",
        views.HudumaBookingDetailView.as_view(),
        name="huduma-booking-detail",
    ),
    path("merchant-orders", views.MerchantOrderListCreateView.as_view(), name="merchant-orders"),
    path(
        "merchant-orders/<uuid:order_id>",
        views.MerchantOrderDetailView.as_view(),
        name="merchant-order-detail",
    ),
    path("driver-jobs", views.DriverJobListCreateView.as_view(), name="driver-jobs"),
    path(
        "driver-jobs/<uuid:job_id>",
        views.DriverJobDetailView.as_view(),
        name="driver-job-detail",
    ),
    path("chat-threads", views.ChatThreadListCreateView.as_view(), name="chat-threads"),
    path(
        "chat-threads/<uuid:thread_id>",
        views.ChatThreadDetailView.as_view(),
        name="chat-thread-detail",
    ),
    path(
        "chat-threads/<uuid:thread_id>/messages",
        views.ChatMessageListCreateView.as_view(),
        name="chat-messages",
    ),
    path("admin-cases", views.AdminCaseListCreateView.as_view(), name="admin-cases"),
    path(
        "admin-cases/<uuid:case_id>",
        views.AdminCaseDetailView.as_view(),
        name="admin-case-detail",
    ),
]
