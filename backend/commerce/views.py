import uuid
from decimal import Decimal
from django.db import transaction
from django.conf import settings
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

from .models import Merchant, Category, Product, Cart, CartItem, Order, OrderItem, PaymentTransaction, ProductWatcher, WatchNotification
from .serializers import (
    MerchantSerializer, CategorySerializer, ProductSerializer,
    CartSerializer, CartItemSerializer, OrderSerializer,
    CheckoutRequestSerializer, VerifyPaymentSerializer, ProductWatcherSerializer, WatchNotificationSerializer
)
from .services import RazorpayService

from .merchant_clients import merchant_gateway

class ProductListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        category_slug = request.query_params.get('category')
        brand = request.query_params.get('brand')
        max_price_param = request.query_params.get('max_price')
        min_price_param = request.query_params.get('min_price')
        search_query = request.query_params.get('q') or ""

        max_price = float(max_price_param) if max_price_param else None
        min_price = float(min_price_param) if min_price_param else None

        # Fetch from 10 live Merchant APIs through Gateway
        merchant_products = merchant_gateway.search_all_merchants(
            query=search_query,
            max_price=max_price,
            min_price=min_price
        )

        if merchant_products:
            if category_slug:
                merchant_products = [p for p in merchant_products if p.get('category', {}).get('slug') == category_slug.lower()]
            if brand:
                merchant_products = [p for p in merchant_products if p.get('brand', '').lower() == brand.lower()]
            return Response(merchant_products)

        # Fallback to local database if needed
        queryset = Product.objects.filter(is_available=True)
        if search_query:
            queryset = queryset.filter(name__icontains=search_query)
        serializer = ProductSerializer(queryset, many=True)
        return Response(serializer.data)

class ProductDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        try:
            product = Product.objects.get(pk=pk)
            return Response(ProductSerializer(product).data)
        except Product.DoesNotExist:
            return Response({'error': 'Product not found'}, status=status.HTTP_404_NOT_FOUND)

class CartView(APIView):
    permission_classes = [AllowAny]

    def _get_user_id(self, request):
        if request.user and request.user.is_authenticated and hasattr(request.user, 'profile'):
            return request.user.profile.supabase_uid
        return request.query_params.get('user_id') or request.headers.get('X-User-ID') or 'guest_user'

    def get(self, request):
        user_id = self._get_user_id(request)
        cart, _ = Cart.objects.get_or_create(user_id=user_id, status='ACTIVE')
        return Response(CartSerializer(cart).data)

class CartItemManageView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        user_id = request.data.get('user_id') or (
            request.user.profile.supabase_uid if request.user.is_authenticated and hasattr(request.user, 'profile') else 'guest_user'
        )
        cart_id = request.data.get('cart_id')
        product_id = request.data.get('product_id')
        quantity = int(request.data.get('quantity', 1))

        print(f"🛒 [BACKEND] CartItem POST: product_id={product_id} (type={type(product_id).__name__}), quantity={quantity}, user_id={user_id}")

        if cart_id:
            cart = Cart.objects.filter(id=cart_id).first()
        else:
            cart, _ = Cart.objects.get_or_create(user_id=user_id, status='ACTIVE')

        if not cart:
            print(f"🛒 [BACKEND] Cart not found!")
            return Response({'error': 'Cart not found'}, status=status.HTTP_404_NOT_FOUND)

        product = None
        product_name = request.data.get('product_name', '')

        # 1. Try integer primary key in local DB
        if isinstance(product_id, int) or (isinstance(product_id, str) and str(product_id).isdigit()):
            product = Product.objects.filter(pk=int(product_id)).first()
            if product:
                print(f"🛒 [BACKEND] Found in DB by PK({int(product_id)}): {product.name}")

        # 2. Try looking up in Merchant Gateway by product_id
        if not product and product_id:
            m_prod = merchant_gateway.get_product_by_id(str(product_id))
            if m_prod:
                print(f"🛒 [BACKEND] Found in Merchant Gateway by ID '{product_id}': {m_prod['name']}")
                # Auto-sync merchant, category, and product into DB
                m_info = m_prod.get('merchant') or {}
                m_slug = m_info.get('slug') or 'general-merchant'
                m_name = m_info.get('name', 'Merchant Partner')
                merchant = Merchant.objects.filter(slug=m_slug).first() or Merchant.objects.filter(name=m_name).first()
                if not merchant:
                    merchant = Merchant.objects.create(
                        slug=m_slug,
                        name=m_name,
                        logo_url=m_info.get('logo_url', ''),
                        is_active=True,
                    )

                c_info = m_prod.get('category') or {}
                c_name = c_info.get('name') if isinstance(c_info, dict) else (c_info or 'General')
                from django.utils.text import slugify
                c_slug = c_info.get('slug') if isinstance(c_info, dict) else slugify(c_name)
                category = Category.objects.filter(name=c_name).first() or Category.objects.filter(slug=c_slug).first()
                if not category:
                    category = Category.objects.create(name=c_name, slug=c_slug)

                price_val = Decimal(str(m_prod.get('price', 0)))
                orig_price_val = Decimal(str(m_prod.get('original_price', 0))) if m_prod.get('original_price') else None

                product, _ = Product.objects.get_or_create(
                    name=m_prod['name'],
                    merchant=merchant,
                    defaults={
                        'category': category,
                        'brand': m_prod.get('brand', 'Brand'),
                        'description': m_prod.get('description', ''),
                        'price': price_val,
                        'original_price': orig_price_val,
                        'rating': float(m_prod.get('rating', 4.5)),
                        'review_count': int(m_prod.get('review_count', 50)),
                        'stock_quantity': int(m_prod.get('stock_quantity', 50)),
                        'images': m_prod.get('images', []),
                        'attributes': m_prod.get('attributes', {}),
                        'is_available': True,
                    }
                )
                print(f"🛒 [BACKEND] Synced to DB with ID {product.id}: {product.name}")

        # 3. Try merchant gateway search by ID keywords or product_name
        if not product and (product_id or product_name):
            search_term = product_name or str(product_id).replace('_', ' ').replace('-', ' ')
            matched = merchant_gateway.search_all_merchants(query=search_term)
            if matched:
                m_prod = matched[0]
                print(f"🛒 [BACKEND] Matched in Merchant Gateway via search '{search_term}': {m_prod['name']}")
                m_info = m_prod.get('merchant') or {}
                m_slug = m_info.get('slug') or 'general-merchant'
                m_name = m_info.get('name', 'Merchant Partner')
                merchant = Merchant.objects.filter(slug=m_slug).first() or Merchant.objects.filter(name=m_name).first()
                if not merchant:
                    merchant = Merchant.objects.create(
                        slug=m_slug,
                        name=m_name,
                        logo_url=m_info.get('logo_url', ''),
                        is_active=True,
                    )

                c_info = m_prod.get('category') or {}
                c_name = c_info.get('name') if isinstance(c_info, dict) else (c_info or 'General')
                from django.utils.text import slugify
                c_slug = c_info.get('slug') if isinstance(c_info, dict) else slugify(c_name)
                category = Category.objects.filter(name=c_name).first() or Category.objects.filter(slug=c_slug).first()
                if not category:
                    category = Category.objects.create(name=c_name, slug=c_slug)

                price_val = Decimal(str(m_prod.get('price', 0)))
                orig_price_val = Decimal(str(m_prod.get('original_price', 0))) if m_prod.get('original_price') else None

                product, _ = Product.objects.get_or_create(
                    name=m_prod['name'],
                    merchant=merchant,
                    defaults={
                        'category': category,
                        'brand': m_prod.get('brand', 'Brand'),
                        'description': m_prod.get('description', ''),
                        'price': price_val,
                        'original_price': orig_price_val,
                        'rating': float(m_prod.get('rating', 4.5)),
                        'review_count': int(m_prod.get('review_count', 50)),
                        'stock_quantity': int(m_prod.get('stock_quantity', 50)),
                        'images': m_prod.get('images', []),
                        'attributes': m_prod.get('attributes', {}),
                        'is_available': True,
                    }
                )
                print(f"🛒 [BACKEND] Synced search match to DB ID {product.id}: {product.name}")

        # 4. Search local DB by keyword or name
        if not product and (product_id or product_name):
            search_query = product_name or str(product_id).replace('_', ' ')
            keywords = [k for k in search_query.split() if len(k) > 2]
            for kw in keywords:
                product = Product.objects.filter(name__icontains=kw).first()
                if product:
                    print(f"🛒 [BACKEND] Local DB keyword '{kw}' matched: {product.name} (id={product.id})")
                    break

        # 5. If STILL not found, return clean 404 (no random fallback)
        if not product:
            print(f"🛒 [BACKEND] ❌ PRODUCT NOT FOUND for ID: {product_id}")
            return Response({'error': f'Product not found for ID: {product_id}'}, status=status.HTTP_404_NOT_FOUND)

        print(f"🛒 [BACKEND] ✅ Successfully adding to cart: {product.name} (db_id={product.id}), qty={quantity}")

        if quantity <= 0:
            CartItem.objects.filter(cart=cart, product=product).delete()
            print(f"🛒 [BACKEND] Deleted item from cart")
        else:
            cart_item, created = CartItem.objects.get_or_create(
                cart=cart,
                product=product,
                defaults={'quantity': quantity, 'unit_price': product.price}
            )
            if not created:
                cart_item.quantity = quantity
                cart_item.unit_price = product.price
                cart_item.save()
            print(f"🛒 [BACKEND] Cart item {'CREATED' if created else 'UPDATED'}: qty={quantity}")

        return Response(CartSerializer(cart).data)

    def delete(self, request, item_id):
        CartItem.objects.filter(id=item_id).delete()
        return Response({'status': 'deleted'})

class CheckoutView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = CheckoutRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        cart_id = serializer.validated_data['cart_id']
        shipping_address = serializer.validated_data['shipping_address']
        user_id = serializer.validated_data.get('user_id') or 'guest_user'

        try:
            cart = Cart.objects.get(id=cart_id, status='ACTIVE')
        except Cart.DoesNotExist:
            return Response({'error': 'Active cart not found'}, status=status.HTTP_404_NOT_FOUND)

        if not cart.items.exists():
            return Response({'error': 'Cart is empty'}, status=status.HTTP_400_BAD_REQUEST)

        # Single-merchant or primary merchant derivation for MVP
        first_item = cart.items.first()
        merchant = first_item.product.merchant if first_item else None

        with transaction.atomic():
            order = Order.objects.create(
                user_id=user_id,
                merchant=merchant,
                cart=cart,
                status='PAYMENT_PENDING',
                subtotal=cart.subtotal,
                discount_amount=Decimal('0.00'),
                tax_amount=Decimal('0.00'),
                shipping_charge=Decimal('0.00'),
                total_amount=cart.subtotal,
                currency='INR',
                shipping_address=shipping_address,
                delivery_estimate='2-4 business days'
            )

            for item in cart.items.all():
                OrderItem.objects.create(
                    order=order,
                    product=item.product,
                    product_name=item.product.name,
                    quantity=item.quantity,
                    unit_price=item.unit_price,
                    total_price=item.total_price
                )

            # Lock Cart
            cart.status = 'LOCKED'
            cart.save()

            # Create Razorpay Order
            rzp_service = RazorpayService()
            rzp_order = rzp_service.create_order(
                amount_in_inr=order.total_amount,
                receipt=str(order.id),
                notes={
                    'merchant_id': str(merchant.id) if merchant else '',
                    'user_id': user_id
                }
            )

            # Create Transaction record
            PaymentTransaction.objects.create(
                order=order,
                gateway='RAZORPAY',
                razorpay_order_id=rzp_order['id'],
                amount=order.total_amount,
                currency='INR',
                status='INITIATED',
                raw_payload=rzp_order
            )

        return Response({
            'order_id': str(order.id),
            'razorpay_order_id': rzp_order['id'],
            'amount': rzp_order['amount'],
            'currency': 'INR',
            'key_id': getattr(settings, 'RAZORPAY_KEY_ID', 'rzp_test_MitraiKey123'),
            'merchant_name': merchant.name if merchant else 'Mitrai Store',
            'order': OrderSerializer(order).data
        }, status=status.HTTP_201_CREATED)

class VerifyPaymentView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = VerifyPaymentSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        order_id = serializer.validated_data['order_id']
        rzp_order_id = serializer.validated_data['razorpay_order_id']
        rzp_payment_id = serializer.validated_data['razorpay_payment_id']
        rzp_signature = serializer.validated_data['razorpay_signature']

        try:
            order = Order.objects.get(id=order_id)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)

        rzp_service = RazorpayService()
        is_valid = rzp_service.verify_payment_signature(rzp_order_id, rzp_payment_id, rzp_signature)

        tx = PaymentTransaction.objects.filter(order=order, razorpay_order_id=rzp_order_id).first()

        if is_valid:
            order.status = 'CONFIRMED'
            order.tracking_number = f"MITRAI-{uuid.uuid4().hex[:8].upper()}"
            order.save()

            if order.cart:
                order.cart.status = 'CHECKED_OUT'
                order.cart.save()

            if tx:
                tx.status = 'SUCCESS'
                tx.razorpay_payment_id = rzp_payment_id
                tx.razorpay_signature = rzp_signature
                tx.save()

            return Response({
                'status': 'PAID',
                'message': 'Payment verified successfully. Your order is confirmed!',
                'order': OrderSerializer(order).data
            })
        else:
            order.status = 'PAYMENT_FAILED'
            order.save()
            if tx:
                tx.status = 'FAILED'
                tx.error_reason = 'Signature verification failed'
                tx.save()

            return Response({
                'status': 'FAILED',
                'message': 'Payment verification failed. Please try again.',
                'order': OrderSerializer(order).data
            }, status=status.HTTP_400_BAD_REQUEST)

class OrderListView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        user_id = request.query_params.get('user_id') or request.headers.get('X-User-ID')
        orders = Order.objects.all().order_by('-created_at')
        if user_id:
            orders = orders.filter(user_id=user_id)
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class OrderDetailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, pk):
        try:
            order = Order.objects.get(pk=pk)
            return Response(OrderSerializer(order).data)
        except Order.DoesNotExist:
            return Response({'error': 'Order not found'}, status=status.HTTP_404_NOT_FOUND)


class ProductWatcherListView(APIView):
    """List or create dynamic product watchers."""
    permission_classes = [AllowAny]

    def get(self, request):
        user_id = request.query_params.get('user_id', '')
        watchers = ProductWatcher.objects.all()
        if user_id:
            watchers = watchers.filter(user_id=user_id)
        serializer = ProductWatcherSerializer(watchers, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        serializer = ProductWatcherSerializer(data=request.data)
        if serializer.is_valid():
            watcher = serializer.save()
            return Response(ProductWatcherSerializer(watcher).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class ProductWatcherDetailView(APIView):
    """Retrieve or cancel a specific product watcher."""
    permission_classes = [AllowAny]

    def delete(self, request, pk):
        try:
            watcher = ProductWatcher.objects.get(pk=pk)
            watcher.status = 'CANCELLED'
            watcher.save(update_fields=['status'])
            return Response({"message": "Watcher cancelled successfully"}, status=status.HTTP_200_OK)
        except ProductWatcher.DoesNotExist:
            return Response({"error": "Watcher not found"}, status=status.HTTP_404_NOT_FOUND)


class WatchNotificationListView(APIView):
    """List triggered watch notifications."""
    permission_classes = [AllowAny]

    def get(self, request):
        notifications = WatchNotification.objects.order_by('-created_at')[:20]
        serializer = WatchNotificationSerializer(notifications, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

