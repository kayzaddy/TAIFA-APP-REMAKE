from django.urls import path

from taifa_merchant.presentation import views
from taifa_merchant.presentation import payment_views
from taifa_merchant.presentation import workspace_views

app_name = "taifa_merchant"

urlpatterns = [
    path("auth/signup", views.SignUpView.as_view(), name="auth-signup"),
    path("auth/login", views.LoginView.as_view(), name="auth-login"),
    path("auth/mfa", views.MfaLoginView.as_view(), name="auth-mfa"),
    path("auth/forgot-password", views.ForgotPasswordView.as_view(), name="auth-forgot"),
    path("auth/logout", views.LogoutView.as_view(), name="auth-logout"),
    path("auth/session", views.SessionView.as_view(), name="auth-session"),
    path("merchants/register", views.MerchantRegisterView.as_view(), name="merchant-register"),
    path("merchants/me", views.MerchantMeView.as_view(), name="merchant-me"),
    path("branches", views.BranchListCreateView.as_view(), name="branches"),
    path("branches/<uuid:branch_id>", views.BranchDetailView.as_view(), name="branch-detail"),
    path("employees", views.EmployeeListInviteView.as_view(), name="employees"),
    path("employees/<uuid:employee_id>", views.EmployeeDetailView.as_view(), name="employee-detail"),
    path("devices", views.DeviceListCreateView.as_view(), name="devices"),
    path("devices/<uuid:device_id>/activate", views.DeviceActivateView.as_view(), name="device-activate"),
    path("devices/<uuid:device_id>/deactivate", views.DeviceDeactivateView.as_view(), name="device-deactivate"),
    path("dashboard", views.DashboardView.as_view(), name="dashboard"),
    path("dashboard/operational", workspace_views.OperationalDashboardView.as_view(), name="dashboard-operational"),
    path("business-profile", workspace_views.BusinessProfileView.as_view(), name="business-profile"),
    path("settings", workspace_views.MerchantSettingsView.as_view(), name="settings"),
    path("notifications", workspace_views.NotificationListView.as_view(), name="notifications"),
    path("notifications/preferences", workspace_views.NotificationPreferencesView.as_view(), name="notification-preferences"),
    path("notifications/<uuid:notification_id>/read", workspace_views.NotificationReadView.as_view(), name="notification-read"),
    path("activities", workspace_views.ActivityTimelineView.as_view(), name="activities"),
    path("branches/<uuid:branch_id>/dashboard", workspace_views.BranchDashboardView.as_view(), name="branch-dashboard"),
    path("employees/<uuid:employee_id>/suspend", workspace_views.EmployeeSuspendView.as_view(), name="employee-suspend"),
    path("devices/<uuid:device_id>", workspace_views.DeviceDetailView.as_view(), name="device-detail"),
    path("devices/<uuid:device_id>/assign", workspace_views.DeviceAssignView.as_view(), name="device-assign"),
    path("payments/terminals", payment_views.TerminalRegisterView.as_view(), name="terminal-register"),
    path("payments/terminals/<uuid:device_id>", payment_views.TerminalStatusView.as_view(), name="terminal-status"),
    path("payments/softpos/sessions", payment_views.SoftposSessionView.as_view(), name="softpos-session"),
    path("payments/softpos/<uuid:transaction_id>/confirm", payment_views.SoftposConfirmView.as_view(), name="softpos-confirm"),
    path("payments/qr", payment_views.QRCreateView.as_view(), name="qr-create"),
    path("payments/qr/<uuid:qr_id>/complete", payment_views.QRCompleteView.as_view(), name="qr-complete"),
    path("payments/links", payment_views.PaymentLinkCreateView.as_view(), name="link-create"),
    path("payments/links/<uuid:link_id>/complete", payment_views.PaymentLinkCompleteView.as_view(), name="link-complete"),
    path("payments/transactions", payment_views.TransactionListView.as_view(), name="transactions"),
    path("payments/transactions/<uuid:transaction_id>", payment_views.TransactionDetailView.as_view(), name="transaction-detail"),
    path("payments/transactions/<uuid:transaction_id>/refund", payment_views.TransactionRefundView.as_view(), name="transaction-refund"),
    path("payments/receipts/<uuid:receipt_id>", payment_views.ReceiptDetailView.as_view(), name="receipt-detail"),
    path("payments/receipts/<uuid:receipt_id>/share", payment_views.ReceiptShareView.as_view(), name="receipt-share"),
    path("payments/analytics/today", payment_views.PaymentAnalyticsView.as_view(), name="analytics-today"),
]
