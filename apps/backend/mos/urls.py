from django.urls import path

from . import views

urlpatterns = [
    path("bootstrap", views.BootstrapView.as_view(), name="mos-bootstrap"),
    path("merchants/<uuid:merchant_id>", views.MerchantDetailView.as_view(), name="mos-merchant"),
    path("merchants/<uuid:merchant_id>/branches", views.BranchListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/staff", views.StaffListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/products", views.ProductListCreateView.as_view()),
    path(
        "merchants/<uuid:merchant_id>/products/<uuid:product_id>/publish-winga",
        views.ProductPublishWingaView.as_view(),
    ),
    path("merchants/<uuid:merchant_id>/warehouses", views.WarehouseListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/stock", views.StockListView.as_view()),
    path("merchants/<uuid:merchant_id>/stock/adjust", views.StockAdjustView.as_view()),
    path("merchants/<uuid:merchant_id>/suppliers", views.SupplierListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/purchase-orders", views.PurchaseOrderListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/customers", views.CustomerListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/orders", views.OrderListCreateView.as_view()),
    path("merchants/<uuid:merchant_id>/orders/<uuid:order_id>", views.OrderDetailView.as_view()),
    path("merchants/<uuid:merchant_id>/orders/<uuid:order_id>/pay", views.OrderPayView.as_view()),
    path(
        "merchants/<uuid:merchant_id>/orders/<uuid:order_id>/fulfill",
        views.OrderFulfillView.as_view(),
    ),
    path("merchants/<uuid:merchant_id>/pos/sessions", views.PosSessionListCreateView.as_view()),
    path(
        "merchants/<uuid:merchant_id>/pos/sessions/<uuid:session_id>/close",
        views.PosSessionCloseView.as_view(),
    ),
    path("merchants/<uuid:merchant_id>/analytics/summary", views.AnalyticsSummaryView.as_view()),
    path("merchants/<uuid:merchant_id>/assist", views.AssistView.as_view()),
]
