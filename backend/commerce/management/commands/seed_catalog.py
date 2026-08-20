from decimal import Decimal
from django.core.management.base import BaseCommand
from commerce.models import Merchant, Category, Product

class Command(BaseCommand):
    help = 'Seeds initial product catalogue for Mitrai AI Commerce'

    def handle(self, *args, **kwargs):
        self.stdout.write('Seeding merchant and product catalogue...')

        # 1. Merchants
        m_boat, _ = Merchant.objects.get_or_create(
            name='boAt Official Store',
            defaults={
                'description': 'Leading lifestyle consumer audio brand.',
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
        m_oneplus, _ = Merchant.objects.get_or_create(
            name='OnePlus Retail India',
            defaults={
                'description': 'Never Settle smartphones and audio gear.',
                'rating': 4.8,
                'logo_url': 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=120'
            }
        )
        m_nike, _ = Merchant.objects.get_or_create(
            name='Nike Sports India',
            defaults={
                'description': 'World leader in athletic footwear and sportswear.',
                'rating': 4.8,
                'logo_url': 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=120'
            }
        )

        # 2. Categories
        c_audio, _ = Category.objects.get_or_create(name='Audio', defaults={'slug': 'audio', 'icon_name': 'headphones'})
        c_phones, _ = Category.objects.get_or_create(name='Smartphones', defaults={'slug': 'smartphones', 'icon_name': 'phone_android'})
        c_shoes, _ = Category.objects.get_or_create(name='Footwear', defaults={'slug': 'footwear', 'icon_name': 'directions_run'})

        # 3. Products
        products_data = [
            # Audio under ₹3,000 & premium
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
                'attributes': {'battery_life': '20 Hours', 'driver': '50mm', 'noise_cancellation': 'Passive', 'connectivity': 'Bluetooth 5.0'},
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
                'attributes': {'battery_life': '50 Hours', 'driver': '30mm', 'noise_cancellation': 'Passive + DSEE', 'connectivity': 'Bluetooth 5.2 Multipoint'},
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
                'attributes': {'battery_life': '42 Hours', 'latency': '80ms', 'noise_cancellation': 'ENx Mic', 'connectivity': 'Bluetooth 5.1'},
                'is_featured': False
            },
            # Smartphones under ₹25,000
            {
                'merchant': m_oneplus,
                'category': c_phones,
                'name': 'OnePlus Nord CE 3 Lite 5G (8GB RAM, 128GB)',
                'brand': 'OnePlus',
                'description': '108 MP primary camera, 67W SUPERVOOC fast charge, 5000 mAh battery with 120Hz smooth display.',
                'price': Decimal('19999.00'),
                'original_price': Decimal('21999.00'),
                'rating': 4.6,
                'review_count': 3200,
                'stock_quantity': 20,
                'images': ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600'],
                'attributes': {'ram': '8 GB', 'storage': '128 GB', 'camera': '108 MP Triple', 'battery': '5000 mAh', 'charging': '67W SUPERVOOC'},
                'is_featured': True
            },
            {
                'merchant': m_oneplus,
                'category': c_phones,
                'name': 'Redmi Note 13 Pro 5G (8GB RAM, 256GB)',
                'brand': 'Xiaomi',
                'description': '200 MP Ultra-Clear OIS Camera, 1.5K 120Hz Curved AMOLED, Snapdragon 7s Gen 2.',
                'price': Decimal('24999.00'),
                'original_price': Decimal('28999.00'),
                'rating': 4.7,
                'review_count': 1950,
                'stock_quantity': 15,
                'images': ['https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600'],
                'attributes': {'ram': '8 GB', 'storage': '256 GB', 'camera': '200 MP OIS', 'battery': '5100 mAh', 'charging': '67W Turbo'},
                'is_featured': True
            },
            # Footwear under ₹5,000
            {
                'merchant': m_nike,
                'category': c_shoes,
                'name': 'Nike Revolution 6 Next Nature Running Shoes',
                'brand': 'Nike',
                'description': 'Plush foam midsole for soft ride, breathable mesh upper, sustainable crafted materials.',
                'price': Decimal('3695.00'),
                'original_price': Decimal('4995.00'),
                'rating': 4.7,
                'review_count': 840,
                'stock_quantity': 35,
                'images': ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'],
                'attributes': {'material': 'Breathable Mesh', 'cushioning': 'Plush Foam', 'weight': '280g', 'use_case': 'Daily Running & Training'},
                'is_featured': True
            },
            {
                'merchant': m_nike,
                'category': c_shoes,
                'name': 'Puma Flyer Runner Engineered Knit',
                'brand': 'Puma',
                'description': 'Softfoam+ optimal comfort sockliner, lightweight EVA midsole, stylish everyday runner.',
                'price': Decimal('2499.00'),
                'original_price': Decimal('3999.00'),
                'rating': 4.5,
                'review_count': 610,
                'stock_quantity': 50,
                'images': ['https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=600'],
                'attributes': {'material': 'Engineered Knit', 'cushioning': 'Softfoam+ EVA', 'weight': '250g', 'use_case': 'Workout & Casual'},
                'is_featured': False
            }
        ]

        for p_data in products_data:
            Product.objects.update_or_create(
                name=p_data['name'],
                defaults=p_data
            )

        self.stdout.write(self.style.SUCCESS(f'Successfully seeded catalogue with {len(products_data)} products across {Category.objects.count()} categories!'))
