from django.urls import path

from . import views

app_name = "enterprise"

urlpatterns = [
    path("merchants/register", views.MerchantRegisterView.as_view(), name="merchant-register"),
    path("merchants/<uuid:merchant_id>/capture", views.MerchantCaptureView.as_view(), name="merchant-capture"),
    path("merchants/<uuid:merchant_id>/settlements", views.SettlementCreateView.as_view(), name="settlement-create"),
    path("settlements/<uuid:settlement_id>/execute", views.SettlementExecuteView.as_view(), name="settlement-execute"),
    path("settlements/<uuid:settlement_id>/cancel", views.SettlementCancelView.as_view(), name="settlement-cancel"),
    path("approvals/<uuid:approval_id>/decide", views.ApprovalDecideView.as_view(), name="approval-decide"),
    path("chargebacks", views.ChargebackOpenView.as_view(), name="chargeback-open"),
    path("chargebacks/<uuid:case_id>/transition", views.ChargebackTransitionView.as_view(), name="chargeback-transition"),
    path("treasury/accounts", views.TreasuryAccountView.as_view(), name="treasury-accounts"),
    path("treasury/transfers", views.TreasuryTransferView.as_view(), name="treasury-transfers"),
    path("reports/<str:report_type>", views.ReportsView.as_view(), name="reports"),
    path("dashboards/<str:kind>", views.DashboardView.as_view(), name="dashboards"),
    path("events/outbox/drain", views.OutboxDrainView.as_view(), name="outbox-drain"),
    path("wallets/bootstrap", views.MerchantBootstrapWalletView.as_view(), name="wallet-bootstrap"),
]
