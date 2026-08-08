from django.urls import path

from . import (
    analytics,
    bill_views,
    notification_views,
    p2p_views,
    people_views,
    recurring_views,
    spending_cap_views,
    transaction_search,
    views,
)

app_name = "payments"

urlpatterns = [
    path("wallet", views.WalletView.as_view(), name="wallet"),
    path("wallet/qr", p2p_views.ReceiveQrView.as_view(), name="wallet-qr"),
    path("transactions", transaction_search.TransactionSearchView.as_view(), name="transaction-search"),
    path(
        "analytics/spending", analytics.SpendingAnalyticsView.as_view(), name="analytics-spending"
    ),
    path("spending-cap", spending_cap_views.SpendingCapView.as_view(), name="spending-cap"),
    path("notifications", notification_views.NotificationListView.as_view(), name="notifications"),
    path(
        "notifications/<uuid:notification_id>/read",
        notification_views.NotificationMarkReadView.as_view(),
        name="notification-read",
    ),
    path("bills", bill_views.BillSplitListCreateView.as_view(), name="bills"),
    path("bills/<uuid:bill_id>", bill_views.BillSplitDetailView.as_view(), name="bill-detail"),
    path("bills/<uuid:bill_id>/cancel", bill_views.BillSplitCancelView.as_view(), name="bill-cancel"),
    path(
        "recurring", recurring_views.RecurringPaymentListCreateView.as_view(), name="recurring-payments"
    ),
    path(
        "recurring/<uuid:recurring_id>/<str:action>",
        recurring_views.RecurringPaymentActionView.as_view(),
        name="recurring-payment-action",
    ),
    path("people/lookup", people_views.PeopleLookupView.as_view(), name="people-lookup"),
    path("contacts", people_views.ContactListCreateView.as_view(), name="contacts"),
    path("contacts/<uuid:contact_id>", people_views.ContactDetailView.as_view(), name="contact-detail"),
    path(
        "contacts/<uuid:contact_id>/<str:action>",
        people_views.ContactActionView.as_view(),
        name="contact-action",
    ),
    path("links", p2p_views.PaymentLinkListCreateView.as_view(), name="payment-links"),
    path(
        "links/<uuid:link_id>/<str:action>",
        p2p_views.PaymentLinkStatusView.as_view(),
        name="payment-link-action",
    ),
    path("pay/<str:slug>", p2p_views.PaymentLinkPublicView.as_view(), name="pay-link-info"),
    path("pay/<str:slug>/confirm", p2p_views.PayLinkView.as_view(), name="pay-link-confirm"),
    path("requests", p2p_views.MoneyRequestListCreateView.as_view(), name="money-requests"),
    path(
        "requests/<uuid:request_id>/<str:action>",
        p2p_views.MoneyRequestActionView.as_view(),
        name="money-request-action",
    ),
    path("topups", views.TopUpView.as_view(), name="topups"),
    path("topups/<uuid:txn_id>/demo-complete", views.DemoTopUpCompleteView.as_view(), name="topup-demo-complete"),
    path("topups/<uuid:txn_id>/poll-status", views.PollTopUpStatusView.as_view(), name="topup-poll-status"),
    path("transfers", views.TransferView.as_view(), name="transfers"),
    path("withdrawals", views.WithdrawalView.as_view(), name="withdrawals"),
    path("withdrawals/<uuid:txn_id>/approve", views.WithdrawalApproveView.as_view(), name="withdrawal-approve"),
    path("withdrawals/<uuid:txn_id>/reject", views.WithdrawalRejectView.as_view(), name="withdrawal-reject"),
    path("withdrawals/<uuid:txn_id>/process", views.WithdrawalProcessView.as_view(), name="withdrawal-process"),
    path("refunds", views.RefundView.as_view(), name="refunds"),
    path("transactions/<uuid:txn_id>", views.TransactionDetailView.as_view(), name="transaction-detail"),
    path("transactions/<uuid:txn_id>/reverse", views.ReverseTransactionView.as_view(), name="transaction-reverse"),
    path("webhooks/mpesa/stk", views.MpesaStkWebhookView.as_view(), name="mpesa-stk-webhook"),
]
