from rest_framework import serializers
from .models import Merchant, Category, Product, Cart, CartItem, Order, OrderItem, PaymentTransaction, ProductWatcher, WatchNotification

class MerchantSerializer(serializers.ModelSerializer):
    class Meta:
        model = Merchant
        fields = ['id', 'name', 'slug', 'description', 'logo_url', 'rating', 'is_active']

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'icon_name', 'description']

class ProductSerializer(serializers.ModelSerializer):
    merchant = MerchantSerializer(read_only=True)
    category = CategorySerializer(read_only=True)
    discount_percentage = serializers.ReadOnlyField()
    is_platform_product = serializers.SerializerMethodField()
    source = serializers.SerializerMethodField()

    def get_is_platform_product(self, obj):
        return True

    def get_source(self, obj):
        return "MERCHANT_API"

    class Meta:
        model = Product
        fields = [
            'id', 'merchant', 'category', 'name', 'brand', 'description',
            'price', 'original_price', 'discount_percentage', 'currency',
            'rating', 'review_count', 'stock_quantity', 'images', 'attributes',
            'is_featured', 'is_available', 'is_platform_product', 'source'
        ]

class CartItemSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(), source='product', write_only=True
    )
    total_price = serializers.ReadOnlyField()

    class Meta:
        model = CartItem
        fields = ['id', 'product', 'product_id', 'quantity', 'unit_price', 'total_price']

class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    subtotal = serializers.ReadOnlyField()
    total_items = serializers.ReadOnlyField()

    class Meta:
        model = Cart
        fields = ['id', 'user_id', 'status', 'items', 'subtotal', 'total_items', 'created_at', 'updated_at']

class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = ['id', 'product', 'product_name', 'quantity', 'unit_price', 'total_price']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    merchant = MerchantSerializer(read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'user_id', 'merchant', 'cart', 'status', 'subtotal',
            'discount_amount', 'tax_amount', 'shipping_charge', 'total_amount',
            'currency', 'shipping_address', 'delivery_estimate', 'tracking_number',
            'items', 'created_at', 'updated_at'
        ]

class CheckoutRequestSerializer(serializers.Serializer):
    cart_id = serializers.UUIDField()
    shipping_address = serializers.DictField()
    user_id = serializers.CharField(max_length=128, required=False)

class VerifyPaymentSerializer(serializers.Serializer):
    order_id = serializers.UUIDField()
    razorpay_order_id = serializers.CharField(max_length=128)
    razorpay_payment_id = serializers.CharField(max_length=128)
    razorpay_signature = serializers.CharField(max_length=256)


class WatchNotificationSerializer(serializers.ModelSerializer):
    matched_product = ProductSerializer(read_only=True)

    class Meta:
        model = WatchNotification
        fields = '__all__'


class ProductWatcherSerializer(serializers.ModelSerializer):
    product = ProductSerializer(read_only=True)
    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(), source='product', write_only=True, required=False
    )
    notifications = WatchNotificationSerializer(many=True, read_only=True)

    class Meta:
        model = ProductWatcher
        fields = [
            'id', 'user_id', 'product', 'product_id', 'search_query', 'category',
            'condition_type', 'target_price', 'dynamic_criteria', 'status',
            'is_triggered', 'triggered_at', 'last_checked_at', 'created_at', 'notifications'
        ]

