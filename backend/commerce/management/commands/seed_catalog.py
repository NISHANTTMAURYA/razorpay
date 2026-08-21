from decimal import Decimal
from django.core.management.base import BaseCommand
from commerce.models import Merchant, Category, Product

class Command(BaseCommand):
    help = 'Seeds initial product catalogue for Mitrai AI Commerce'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding merchant and product catalogue...')

        # 1. Merchants
        # 1. Merchants
        m_boat, _ = Merchant.objects.get_or_create(
            name='boAt Lifestyle Official',
            defaults={
                'description': 'Leading Indian consumer audio & wearable brand.',
                'rating': 4.7,
                'logo_url': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=120'
            }
        )
        m_sony, _ = Merchant.objects.get_or_create(
            name='Sony Center Direct',
            defaults={
                'description': 'Premium Japanese audio and electronic engineering.',
                'rating': 4.9,
                'logo_url': 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=120'
            }
        )
        m_samsung, _ = Merchant.objects.get_or_create(
            name='Samsung Direct Store',
            defaults={
                'description': 'Official Samsung Electronics direct retail store.',
                'rating': 4.8,
                'logo_url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=120'
            }
        )
        m_noise, _ = Merchant.objects.get_or_create(
            name='Noise Official Store',
            defaults={
                'description': 'India leading smart wearable & smartwatch brand.',
                'rating': 4.7,
                'logo_url': 'https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=120'
            }
        )
        m_redtape, _ = Merchant.objects.get_or_create(
            name='Red Tape Official Store',
            defaults={
                'description': 'Premium lifestyle footwear and apparel direct store.',
                'rating': 4.6,
                'logo_url': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=120'
            }
        )
        m_snitch, _ = Merchant.objects.get_or_create(
            name='Snitch Fast Fashion Direct',
            defaults={
                'description': 'Modern on-trend menswear & streetwear.',
                'rating': 4.8,
                'logo_url': 'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=120'
            }
        )
        m_derma, _ = Merchant.objects.get_or_create(
            name='The Derma Co Direct',
            defaults={
                'description': 'Science-backed skincare and derma formulations.',
                'rating': 4.7,
                'logo_url': 'https://images.unsplash.com/photo-1556228720-195a672e8a03?w=120'
            }
        )
        m_muscleblaze, _ = Merchant.objects.get_or_create(
            name='MuscleBlaze Official',
            defaults={
                'description': 'Authentic sports nutrition and certified protein supplements.',
                'rating': 4.8,
                'logo_url': 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=120'
            }
        )

        # 2. Categories
        c_audio, _ = Category.objects.get_or_create(name='Audio', defaults={'slug': 'audio', 'icon_name': 'headphones'})
        c_phones, _ = Category.objects.get_or_create(name='Smartphones', defaults={'slug': 'smartphones', 'icon_name': 'phone_android'})
        c_wearables, _ = Category.objects.get_or_create(name='Wearables', defaults={'slug': 'wearables', 'icon_name': 'watch'})
        c_shoes, _ = Category.objects.get_or_create(name='Footwear', defaults={'slug': 'footwear', 'icon_name': 'directions_run'})
        c_fashion, _ = Category.objects.get_or_create(name='Fashion', defaults={'slug': 'fashion', 'icon_name': 'checkroom'})
        c_care, _ = Category.objects.get_or_create(name='Personal Care', defaults={'slug': 'personal-care', 'icon_name': 'spa'})
        c_nutrition, _ = Category.objects.get_or_create(name='Food & Nutrition', defaults={'slug': 'food-nutrition', 'icon_name': 'restaurant'})

        # 3. Products
        products_data = [
            # ── Audio ──
            {
                'merchant': m_boat,
                'category': c_audio,
                'name': 'boAt Rockerz 550 Over-Ear Wireless Headphones',
                'brand': 'boAt',
                'description': 'Super extra bass 50mm dynamic drivers with 20 hours playback and physical noise isolation.',
                'price': Decimal('1999.00'),
                'original_price': Decimal('4999.00'),
                'rating': 4.6,
                'review_count': 2140,
                'stock_quantity': 45,
                'images': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600'],
                'attributes': {'battery_life': '20 Hours', 'driver': '50mm', 'noise_cancellation': 'Passive'},
                'is_featured': True
            },
            {
                'merchant': m_sony,
                'category': c_audio,
                'name': 'Sony WH-CH520 Wireless Bluetooth Headphones',
                'brand': 'Sony',
                'description': 'Up to 50 hours battery life with quick charging and DSEE audio upscaling technology.',
                'price': Decimal('2999.00'),
                'original_price': Decimal('4490.00'),
                'rating': 4.8,
                'review_count': 1850,
                'stock_quantity': 30,
                'images': ['https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=600'],
                'attributes': {'battery_life': '50 Hours', 'driver': '30mm', 'connectivity': 'Bluetooth 5.2 Multipoint'},
                'is_featured': True
            },
            {
                'merchant': m_boat,
                'category': c_audio,
                'name': 'boAt Airdopes 141 True Wireless Earbuds',
                'brand': 'boAt',
                'description': '42 hours total playtime, BEAST mode 80ms low latency for gaming, and ENx noise cancelling mic.',
                'price': Decimal('1299.00'),
                'original_price': Decimal('4490.00'),
                'rating': 4.4,
                'review_count': 5400,
                'stock_quantity': 100,
                'images': ['https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600'],
                'attributes': {'battery_life': '42 Hours', 'latency': '80ms', 'noise_cancellation': 'ENx Mic'},
                'is_featured': False
            },
            # ── Smartphones ──
            {
                'merchant': m_samsung,
                'category': c_phones,
                'name': 'Samsung Galaxy M34 5G (6GB RAM, 128GB)',
                'brand': 'Samsung',
                'description': '6000 mAh mega battery, 50MP No Shake Cam (OIS), 120Hz Super AMOLED Display.',
                'price': Decimal('16999.00'),
                'original_price': Decimal('24499.00'),
                'rating': 4.5,
                'review_count': 4100,
                'stock_quantity': 30,
                'images': ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600'],
                'attributes': {'ram': '6 GB', 'storage': '128 GB', 'battery': '6000 mAh', 'display': 'Super AMOLED 120Hz'},
                'is_featured': True
            },
            {
                'merchant': m_samsung,
                'category': c_phones,
                'name': 'OnePlus Nord CE 3 Lite 5G (8GB RAM, 128GB)',
                'brand': 'OnePlus',
                'description': '108 MP primary camera, 67W SUPERVOOC fast charge, 5000 mAh battery with 120Hz smooth display.',
                'price': Decimal('19999.00'),
                'original_price': Decimal('21999.00'),
                'rating': 4.6,
                'review_count': 3200,
                'stock_quantity': 20,
                'images': ['https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600'],
                'attributes': {'ram': '8 GB', 'storage': '128 GB', 'camera': '108 MP Triple', 'battery': '5000 mAh'},
                'is_featured': True
            },
            # ── Wearables ──
            {
                'merchant': m_noise,
                'category': c_wearables,
                'name': 'Noise ColorFit Pulse 2 Max 1.85-inch Smartwatch',
                'brand': 'Noise',
                'description': '1.85" brightest display, Bluetooth calling with Tru Sync, 10 days battery, 100 sports modes.',
                'price': Decimal('1499.00'),
                'original_price': Decimal('5999.00'),
                'rating': 4.6,
                'review_count': 3200,
                'stock_quantity': 50,
                'images': ['https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=600'],
                'attributes': {'display': '1.85 inch TFT 550 nits', 'battery': '10 Days', 'calling': 'Tru Sync BT Calling'},
                'is_featured': True
            },
            {
                'merchant': m_boat,
                'category': c_wearables,
                'name': 'boAt Wave Call 2 Bluetooth Calling Smartwatch',
                'brand': 'boAt',
                'description': '1.83-inch HD Display, Advanced Bluetooth Calling, 700+ Active Modes, Live Cricket Scores.',
                'price': Decimal('1699.00'),
                'original_price': Decimal('6990.00'),
                'rating': 4.4,
                'review_count': 1890,
                'stock_quantity': 35,
                'images': ['https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600'],
                'attributes': {'display': '1.83 inch HD', 'battery': '7 Days', 'calling': 'BT Calling'},
                'is_featured': False
            },
            # ── Footwear ──
            {
                'merchant': m_redtape,
                'category': c_shoes,
                'name': 'Red Tape Lightweight Breathable Athleisure Runners',
                'brand': 'Red Tape',
                'description': 'Engineered knit mesh upper for extreme breathability with shock-absorbing cloud sole.',
                'price': Decimal('1499.00'),
                'original_price': Decimal('5399.00'),
                'rating': 4.5,
                'review_count': 4500,
                'stock_quantity': 50,
                'images': ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'],
                'attributes': {'upper': 'Engineered Knit Mesh', 'weight': '220g Ultra Lightweight'},
                'is_featured': True
            },
            {
                'merchant': m_redtape,
                'category': c_shoes,
                'name': 'Sparx SM-678 High Performance Running Shoes',
                'brand': 'Sparx',
                'description': 'Durable mesh upper, high durability TPR sole for rough Indian terrains and daily gym workout.',
                'price': Decimal('1199.00'),
                'original_price': Decimal('1699.00'),
                'rating': 4.5,
                'review_count': 5800,
                'stock_quantity': 80,
                'images': ['https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=600'],
                'attributes': {'sole': 'Heavy Duty TPR', 'terrain': 'All-Terrain'},
                'is_featured': False
            },
            # ── Fashion ──
            {
                'merchant': m_snitch,
                'category': c_fashion,
                'name': 'Snitch Cuban Collar Linen Blend Relaxed Shirt',
                'brand': 'Snitch',
                'description': 'Breathable pure premium linen blend, resort relaxed fit with modern Cuban camp collar.',
                'price': Decimal('1399.00'),
                'original_price': Decimal('2299.00'),
                'rating': 4.7,
                'review_count': 1600,
                'stock_quantity': 40,
                'images': ['https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600'],
                'attributes': {'fabric': 'Linen Blend', 'fit': 'Relaxed Cuban Fit', 'wash': 'Machine Cold'},
                'is_featured': True
            },
            {
                'merchant': m_snitch,
                'category': c_fashion,
                'name': 'Bewakoof Heavy Duty 6-Pocket Utility Cargo Joggers',
                'brand': 'Bewakoof',
                'description': '100% durable twill cotton, 6 deep utility pockets, elasticated drawstring waistband.',
                'price': Decimal('1299.00'),
                'original_price': Decimal('2499.00'),
                'rating': 4.5,
                'review_count': 3600,
                'stock_quantity': 60,
                'images': ['https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600'],
                'attributes': {'pockets': '6 Tactical Pockets', 'fabric': '100% Cotton Twill'},
                'is_featured': False
            },
            # ── Personal Care ──
            {
                'merchant': m_derma,
                'category': c_care,
                'name': 'The Derma Co 1% Hyaluronic Sunscreen Aqua Gel SPF 50',
                'brand': 'The Derma Co',
                'description': 'Broad spectrum SPF 50 PA++++, ultra-lightweight water gel with Vitamin E and zero white cast.',
                'price': Decimal('449.00'),
                'original_price': Decimal('499.00'),
                'rating': 4.8,
                'review_count': 4900,
                'stock_quantity': 120,
                'images': ['https://images.unsplash.com/photo-1556228720-195a672e8a03?w=600'],
                'attributes': {'spf': 'SPF 50 PA++++', 'key_actives': 'Hyaluronic Acid + Vitamin E', 'skin_type': 'All Skin Types'},
                'is_featured': True
            },
            # ── Food & Nutrition ──
            {
                'merchant': m_muscleblaze,
                'category': c_nutrition,
                'name': 'MuscleBlaze Biozyme Performance Whey (Rich Chocolate 1kg)',
                'brand': 'MuscleBlaze',
                'description': 'Clinically tested 50% higher protein absorption, 25g protein per scoop, informed choice certified.',
                'price': Decimal('2499.00'),
                'original_price': Decimal('3499.00'),
                'rating': 4.8,
                'review_count': 7200,
                'stock_quantity': 60,
                'images': ['https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=600'],
                'attributes': {'protein_per_scoop': '25g Biozyme Whey', 'bcaa': '5.51g', 'flavor': 'Rich Chocolate'},
                'is_featured': True
            }
        ]

        for p_data in products_data:
            Product.objects.update_or_create(
                name=p_data['name'],
                defaults=p_data
            )

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded catalogue with {len(products_data)} products across {Category.objects.count()} categories!'))
