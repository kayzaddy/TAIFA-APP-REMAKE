from django.urls import path

from . import views

urlpatterns = [
    path("bootstrap", views.BootstrapProfileView.as_view(), name="map-bootstrap"),
    path("merchants/<uuid:merchant_id>/profile", views.ProfileDetailView.as_view()),
    path("merchants/<uuid:merchant_id>/qr", views.QrIssueView.as_view()),
    path("merchants/<uuid:merchant_id>/qr/library", views.QrLibraryView.as_view()),
    path("merchants/<uuid:merchant_id>/qr/static/pay", views.StaticQrPayView.as_view()),
    path("merchants/<uuid:merchant_id>/links", views.PaymentLinkCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/invoices", views.InvoiceCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/checkout", views.CheckoutCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/terminals", views.TerminalListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/analytics", views.AnalyticsSummaryView.as_view()),
    path("merchants/<uuid:merchant_id>/winga/accept", views.WingaDealAcceptView.as_view()),
    path("merchants/<uuid:merchant_id>/mobility/accept", views.MobilityAcceptView.as_view()),
    path("intents/<str:public_code>", views.IntentDetailView.as_view()),
    path("intents/<str:public_code>/pay", views.IntentPayView.as_view()),
    path("links/<str:path_token>", views.LinkResolveView.as_view()),
    path("receipts/<str:public_code>", views.ReceiptDetailView.as_view()),
    path("funding/prefs", views.FundingPrefsView.as_view()),
    path("funding/resolve", views.FundingResolveView.as_view()),
    path("merchants/<uuid:merchant_id>/tap", views.TapStartView.as_view()),
    path("tap/<str:public_code>", views.TapDetailView.as_view()),
    path("tap/<str:public_code>/auth", views.TapAuthView.as_view()),
    path("tap/<str:public_code>/confirm", views.TapConfirmView.as_view()),
    path("tap/<str:public_code>/cancel", views.TapCancelView.as_view()),
]
