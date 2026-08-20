from decimal import Decimal
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient
from commerce.models import Merchant, Category, Product, Cart, CartItem, Order, ProductWatcher, WatchNotification
from commerce.tasks import check_product_watchers_task

class CommerceAPITestCase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.merchant = Merchant.objects.create(name='Test Merchant', rating=4.8)
        self.category = Category.objects.create(name='Audio', slug='audio')
        self.product = Product.objects.create(
            merchant=self.merchant,
            category=self.category,
            name='Test Headphones 500',
            brand='TestBrand',
            description='Active noise cancellation with 30h battery',
            price=Decimal('2499.00'),
            stock_quantity=10,
            images=['https://example.com/img.jpg'],
            attributes={'battery_life': '30h'}
        )

    def test_get_products(self):
        url = reverse('product_list')
        response = self.client.get(url)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'Test Headphones 500')

    def test_cart_management(self):
        url = reverse('cart_item_manage')
        response = self.client.post(url, {
            'user_id': 'test_user_1',
            'product_id': self.product.id,
            'quantity': 2
        }, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['total_items'], 2)
        self.assertEqual(float(response.data['subtotal']), 4998.00)

    def test_checkout_and_razorpay_verification(self):
        # 1. Create cart
        cart = Cart.objects.create(user_id='test_user_checkout', status='ACTIVE')
        CartItem.objects.create(cart=cart, product=self.product, quantity=1, unit_price=self.product.price)

        # 2. Checkout
        checkout_url = reverse('checkout_initiate')
        checkout_resp = self.client.post(checkout_url, {
            'cart_id': str(cart.id),
            'user_id': 'test_user_checkout',
            'shipping_address': {'city': 'Bengaluru', 'phone': '9876543210'}
        }, format='json')
        self.assertEqual(checkout_resp.status_code, 201)
        order_id = checkout_resp.data['order_id']
        rzp_order_id = checkout_resp.data['razorpay_order_id']

        # 3. Verify Payment with dummy signature
        verify_url = reverse('payment_verify')
        verify_resp = self.client.post(verify_url, {
            'order_id': order_id,
            'razorpay_order_id': rzp_order_id,
            'razorpay_payment_id': 'pay_test123',
            'razorpay_signature': 'invalid_sig'
        }, format='json')
        self.assertEqual(verify_resp.status_code, 400)

    def test_product_watcher_creation_and_task_execution(self):
        # 1. Create price drop watcher (target: ₹2,600, current: ₹2,499)
        watcher = ProductWatcher.objects.create(
            user_id='test_watcher_user',
            product=self.product,
            condition_type='PRICE_DROP',
            target_price=Decimal('2600.00'),
            status='ACTIVE'
        )

        # 2. Execute Celery worker task
        result = check_product_watchers_task()
        self.assertIn("triggered 1 alerts", result)

        # 3. Verify watcher triggered and notification created
        watcher.refresh_from_db()
        self.assertEqual(watcher.status, 'TRIGGERED')
        self.assertTrue(watcher.is_triggered)

        notifications = WatchNotification.objects.filter(watcher=watcher)
        self.assertEqual(notifications.count(), 1)
        self.assertIn("Price Drop Alert", notifications.first().title)

    def test_product_watcher_api_endpoints(self):
        # List watchers
        url = reverse('product_watcher_list')
        resp = self.client.get(url)
        self.assertEqual(resp.status_code, 200)

        # Create watcher via API
        create_resp = self.client.post(url, {
            'user_id': 'api_user',
            'product_id': self.product.id,
            'condition_type': 'PRICE_DROP',
            'target_price': '2000.00'
        }, format='json')
        self.assertEqual(create_resp.status_code, 201)
        watcher_id = create_resp.data['id']

        # Cancel watcher
        detail_url = reverse('product_watcher_detail', kwargs={'pk': watcher_id})
        del_resp = self.client.delete(detail_url)
        self.assertEqual(del_resp.status_code, 200)
