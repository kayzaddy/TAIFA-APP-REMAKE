from django.urls import path

from . import views

urlpatterns = [
    path("rank", views.RankStoresView.as_view(), name="express-rank"),
    path("stores", views.StoreListView.as_view(), name="express-stores"),
    path("products", views.ProductSearchView.as_view(), name="express-products"),
    path("ai/basket", views.AiBasketView.as_view(), name="express-ai-basket"),
    path("list/parse", views.ParseShoppingListView.as_view(), name="express-list-parse"),
    path("quote", views.QuoteView.as_view(), name="express-quote"),
    path("orders", views.OrderListCreateView.as_view(), name="express-orders"),
    path("orders/<uuid:order_id>", views.OrderDetailView.as_view(), name="express-order"),
    path("orders/<uuid:order_id>/accept", views.OrderAcceptView.as_view()),
    path("orders/<uuid:order_id>/pay", views.OrderPayView.as_view()),
    path("orders/<uuid:order_id>/ready", views.OrderReadyView.as_view()),
    path("orders/<uuid:order_id>/deliver", views.OrderDeliverView.as_view()),
    path("orders/<uuid:order_id>/advance", views.OrderAdvanceView.as_view()),
    path("checkout", views.CheckoutView.as_view(), name="express-checkout"),
]
