from django.urls import path
from .views import (
    ProductListView, ProductDetailView,
    CartView, CartItemManageView,
    CheckoutView, VerifyPaymentView, OrderListView, OrderDetailView,
    ProductWatcherListView, ProductWatcherDetailView, WatchNotificationListView
)

urlpatterns = [
    # Catalog
    path('products/', ProductListView.as_view(), name='product_list'),
    path('products/<uuid:pk>/', ProductDetailView.as_view(), name='product_detail'),

    # Cart
    path('cart/', CartView.as_view(), name='cart_detail'),
    path('cart/item/', CartItemManageView.as_view(), name='cart_item_manage'),
    path('cart/item/<uuid:item_id>/', CartItemManageView.as_view(), name='cart_item_delete'),

    # Checkout & Payment
    path('checkout/initiate/', CheckoutView.as_view(), name='checkout_initiate'),
    path('payment/verify/', VerifyPaymentView.as_view(), name='payment_verify'),
    path('orders/', OrderListView.as_view(), name='order_list'),
    path('orders/<uuid:pk>/', OrderDetailView.as_view(), name='order_detail'),

    # Dynamic Product Watcher & Radar
    path('watchers/', ProductWatcherListView.as_view(), name='product_watcher_list'),
    path('watchers/<uuid:pk>/', ProductWatcherDetailView.as_view(), name='product_watcher_detail'),
    path('watchers/notifications/', WatchNotificationListView.as_view(), name='watch_notifications'),
]
