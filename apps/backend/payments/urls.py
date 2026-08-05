from django.urls import path

from . import views

app_name = "payments"

urlpatterns = [
    path("wallet", views.WalletView.as_view(), name="wallet"),
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
