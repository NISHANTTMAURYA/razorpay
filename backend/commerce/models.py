import uuid
from decimal import Decimal
from django.db import models
from django.utils.text import slugify

class Merchant(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=255, unique=True, blank=True)
    description = models.TextField(blank=True)
    logo_url = models.URLField(max_length=1024, blank=True)
    rating = models.FloatField(default=4.8)
    razorpay_account_id = models.CharField(max_length=128, blank=True)
    is_active = models.BooleanField(default=True)

    # Dynamic AI Routing & Merchant Capability Manifest Fields
    api_endpoint = models.URLField(max_length=1024, blank=True, help_text="Live inventory & search REST/GraphQL endpoint")
    auth_type = models.CharField(max_length=50, default="API_KEY", help_text="API_KEY, OAUTH2, HMAC")
    categories = models.JSONField(default=list, blank=True, help_text="Categories served e.g. ['Audio', 'Wearables']")
    brand_keywords = models.JSONField(default=list, blank=True, help_text="Recognized brand keywords and aliases")
    min_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    max_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    capability_description = models.TextField(blank=True, help_text="Rich capability text for AI semantic routing & embeddings")
    semantic_embedding = models.JSONField(default=list, blank=True, help_text="Pre-computed 768-dim/1536-dim text embedding vector")

    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, blank=True)
    icon_name = models.CharField(max_length=50, blank=True, default='category')
    description = models.TextField(blank=True)

    class Meta:
        verbose_name_plural = 'Categories'

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

class Product(models.Model):
    merchant = models.ForeignKey(Merchant, on_delete=models.CASCADE, related_name='products')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, related_name='products')
    name = models.CharField(max_length=255, db_index=True)
    brand = models.CharField(max_length=100, db_index=True)
    description = models.TextField()
    price = models.DecimalField(max_digits=10, decimal_places=2, db_index=True)
    original_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    currency = models.CharField(max_length=10, default='INR')
    rating = models.FloatField(default=4.5)
    review_count = models.IntegerField(default=120)
    stock_quantity = models.IntegerField(default=25)
    images = models.JSONField(default=list)
    attributes = models.JSONField(default=dict, help_text="e.g. {'battery_life': '20h', 'ram': '8GB', 'camera': '50MP'}")
    is_featured = models.BooleanField(default=False)
    is_available = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def discount_percentage(self):
        if self.original_price and self.original_price > self.price:
            return int(((self.original_price - self.price) / self.original_price) * 100)
        return 0

    def __str__(self):
        return f"{self.name} - ₹{self.price}"

class Cart(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('LOCKED', 'Locked'),
        ('CHECKED_OUT', 'Checked Out'),
        ('ABANDONED', 'Abandoned'),
    ]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=128, db_index=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def subtotal(self):
        return sum(item.total_price for item in self.items.all())

    @property
    def total_items(self):
        return sum(item.quantity for item in self.items.all())

    def __str__(self):
        return f"Cart {self.id} ({self.status}) - ₹{self.subtotal}"

class CartItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.CASCADE)
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    @property
    def total_price(self):
        return self.quantity * self.unit_price

    class Meta:
        unique_together = ('cart', 'product')

    def __str__(self):
        return f"{self.quantity}x {self.product.name}"

class Order(models.Model):
    STATUS_CHOICES = [
        ('CREATED', 'Created'),
        ('PAYMENT_PENDING', 'Payment Pending'),
        ('PAID', 'Paid'),
        ('PAYMENT_FAILED', 'Payment Failed'),
        ('CONFIRMED', 'Confirmed'),
        ('SHIPPED', 'Shipped'),
        ('DELIVERED', 'Delivered'),
        ('CANCELLED', 'Cancelled'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=128, db_index=True)
    merchant = models.ForeignKey(Merchant, on_delete=models.PROTECT, related_name='orders', null=True)
    cart = models.ForeignKey(Cart, on_delete=models.SET_NULL, null=True, blank=True)
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default='CREATED', db_index=True)
    
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    discount_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    tax_amount = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    shipping_charge = models.DecimalField(max_digits=10, decimal_places=2, default=Decimal('0.00'))
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='INR')
    
    shipping_address = models.JSONField(default=dict)
    delivery_estimate = models.CharField(max_length=100, default='2-4 business days')
    tracking_number = models.CharField(max_length=64, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Order {self.id} - {self.status} - ₹{self.total_amount}"

class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    product = models.ForeignKey(Product, on_delete=models.PROTECT)
    product_name = models.CharField(max_length=255)
    quantity = models.PositiveIntegerField(default=1)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    total_price = models.DecimalField(max_digits=10, decimal_places=2)

    def __str__(self):
        return f"{self.quantity}x {self.product_name}"

class PaymentTransaction(models.Model):
    GATEWAY_CHOICES = [
        ('RAZORPAY', 'Razorpay'),
    ]
    STATUS_CHOICES = [
        ('INITIATED', 'Initiated'),
        ('SUCCESS', 'Success'),
        ('FAILED', 'Failed'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='transactions')
    gateway = models.CharField(max_length=30, choices=GATEWAY_CHOICES, default='RAZORPAY')
    razorpay_order_id = models.CharField(max_length=128, db_index=True)
    razorpay_payment_id = models.CharField(max_length=128, blank=True, db_index=True)
    razorpay_signature = models.CharField(max_length=256, blank=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=10, default='INR')
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='INITIATED')
    error_reason = models.TextField(blank=True)
    raw_payload = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Transaction {self.razorpay_payment_id} - {self.status}"


class ProductWatcher(models.Model):
    """
    Dynamic product watch / radar rule evaluated periodically by Celery worker.
    Supports price drops, stock alerts, new launches, and dynamic attribute matching.
    """
    CONDITION_CHOICES = [
        ('PRICE_DROP', 'Price Drop Below Threshold'),
        ('STOCK_AVAILABLE', 'Back in Stock Alert'),
        ('NEW_LAUNCH', 'New Product Launch in Category'),
        ('REVIEW_RATING_THRESHOLD', 'Community Rating Threshold'),
        ('DYNAMIC_SPEC_MATCH', 'Dynamic Spec Criteria Match'),
    ]

    STATUS_CHOICES = [
        ('ACTIVE', 'Active & Monitoring'),
        ('TRIGGERED', 'Condition Met & Notified'),
        ('CANCELLED', 'Cancelled by User'),
        ('EXPIRED', 'Expired'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user_id = models.CharField(max_length=128, blank=True, help_text="Supabase user UUID or guest token")
    product = models.ForeignKey(Product, on_delete=models.CASCADE, null=True, blank=True, related_name='watchers')
    search_query = models.CharField(max_length=255, blank=True, help_text="e.g. 'OnePlus Nord' or '5G phone with 6000mAh'")
    category = models.ForeignKey(Category, on_delete=models.SET_NULL, null=True, blank=True)
    condition_type = models.CharField(max_length=32, choices=CONDITION_CHOICES, default='PRICE_DROP')
    target_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    dynamic_criteria = models.JSONField(default=dict, blank=True, help_text="e.g. {'battery_min': 5000, 'max_price': 20000}")
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    is_triggered = models.BooleanField(default=False)
    triggered_at = models.DateTimeField(null=True, blank=True)
    last_checked_at = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        prod_name = self.product.name if self.product else self.search_query
        return f"Watcher for '{prod_name}' [{self.condition_type}] - {self.status}"


class WatchNotification(models.Model):
    """Logs triggered alerts sent to user with grounded AI summary."""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    watcher = models.ForeignKey(ProductWatcher, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=255)
    message = models.TextField()
    matched_product = models.ForeignKey(Product, on_delete=models.SET_NULL, null=True, blank=True)
    action_url = models.CharField(max_length=512, blank=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Alert: {self.title} ({self.created_at.strftime('%Y-%m-%d %H:%M')})"
