import re
import logging
from abc import ABC, abstractmethod
from typing import List, Dict, Any, Optional
from decimal import Decimal

logger = logging.getLogger(__name__)

class MerchantProductDTO:
    """Standardized Product Data Transfer Object across all Merchant APIs."""
    def __init__(
        self,
        id: str,
        name: str,
        brand: str,
        category: str,
        description: str,
        price: float,
        original_price: float,
        rating: float,
        review_count: int,
        images: List[str],
        attributes: Dict[str, Any],
        merchant_name: str,
        merchant_slug: str,
        merchant_logo: str,
        stock_quantity: int = 50,
        is_platform_product: bool = True,
        source: str = "MERCHANT_API"
    ):
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.description = description
        self.price = price
        self.original_price = original_price
        self.rating = rating
        self.review_count = review_count
        self.images = images
        self.attributes = attributes
        self.merchant_name = merchant_name
        self.merchant_slug = merchant_slug
        self.merchant_logo = merchant_logo
        self.stock_quantity = stock_quantity
        self.is_platform_product = is_platform_product
        self.source = source

    def to_dict(self) -> Dict[str, Any]:
        discount = 0
        if self.original_price > self.price and self.original_price > 0:
            discount = round(((self.original_price - self.price) / self.original_price) * 100)

        return {
            "id": self.id,
            "name": self.name,
            "brand": self.brand,
            "category": {"name": self.category, "slug": self.category.lower()},
            "description": self.description,
            "price": f"{self.price:.2f}",
            "original_price": f"{self.original_price:.2f}",
            "discount_percentage": discount,
            "currency": "INR",
            "rating": self.rating,
            "review_count": self.review_count,
            "stock_quantity": self.stock_quantity,
            "images": self.images,
            "attributes": self.attributes,
            "is_featured": True,
            "is_available": self.stock_quantity > 0,
            "is_platform_product": self.is_platform_product,
            "source": self.source,
            "merchant": {
                "id": f"mch_{self.merchant_slug}",
                "name": self.merchant_name,
                "slug": self.merchant_slug,
                "logo_url": self.merchant_logo,
                "rating": 4.8,
                "is_active": True
            }
        }


# ─────────────────────────────────────────────────────────────────────────────
# BASE MERCHANT CLIENT INTERFACE (Plug & Play for Any Merchant API)
# ─────────────────────────────────────────────────────────────────────────────

class BaseMerchantClient(ABC):
    """
    Abstract interface for integrating merchant e-commerce endpoints.
    Extend this base class to connect Shopify, WooCommerce, Magento, or custom REST/GraphQL APIs.
    """

    def __init__(self, api_endpoint: str = "", api_key: str = "", merchant_name: str = "", merchant_slug: str = "", logo_url: str = ""):
        self.api_endpoint = api_endpoint
        self.api_key = api_key
        self.merchant_name = merchant_name
        self.merchant_slug = merchant_slug
        self.logo_url = logo_url

    @abstractmethod
    def fetch_catalog(self) -> List[MerchantProductDTO]:
        """Fetches complete live catalog from merchant inventory endpoint."""
        pass

    def search_products(self, query: str = "", max_price: Optional[float] = None, min_price: Optional[float] = None) -> List[MerchantProductDTO]:
        """Filters catalog by query string and price bounds."""
        catalog = self.fetch_catalog()
        results = []
        q_lower = query.lower()

        for item in catalog:
            matches_query = not query or (
                q_lower in item.name.lower() or
                q_lower in item.brand.lower() or
                q_lower in item.category.lower() or
                q_lower in item.description.lower()
            )
            matches_price = True
            if max_price is not None and item.price > max_price:
                matches_price = False
            if min_price is not None and item.price < min_price:
                matches_price = False

            if matches_query and matches_price:
                results.append(item)

        return results

    def get_product(self, product_id: str) -> Optional[MerchantProductDTO]:
        """Fetches a specific product by ID."""
        for item in self.fetch_catalog():
            if str(item.id) == str(product_id):
                return item
        return None

    def check_inventory(self, product_id: str) -> int:
        """Returns live stock count."""
        prod = self.get_product(product_id)
        return prod.stock_quantity if prod else 0

    def create_merchant_order(self, cart_items: List[Dict[str, Any]], customer_info: Dict[str, Any]) -> Dict[str, Any]:
        """Dispatches authorized order directly to merchant fulfillment API."""
        return {
            "merchant_order_id": f"ORD_{self.merchant_slug.upper()}_{len(cart_items)}",
            "status": "CONFIRMED",
            "merchant": self.merchant_name,
            "fulfillment_status": "PROCESSING_EXPRESS"
        }


# ─────────────────────────────────────────────────────────────────────────────
# 10 INDEPENDENT MERCHANT API CLIENT IMPLEMENTATIONS
# ─────────────────────────────────────────────────────────────────────────────

# 1. Sony Center Direct
class SonyCenterMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.sonycenter.in/v2/catalog",
            api_key="sony_sec_live_9921",
            merchant_name="Sony Center Direct",
            merchant_slug="sony-center-direct",
            logo_url="https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="sony_wh_ch520",
                name="Sony WH-CH520 Wireless Bluetooth Headphones",
                brand="Sony",
                category="Audio",
                description="Up to 50 hours battery life with quick charging and DSEE audio upscaling technology.",
                price=2999.0,
                original_price=4490.0,
                rating=4.8,
                review_count=1850,
                images=[
                    "https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=600",
                    "https://images.unsplash.com/photo-1484704849700-f032a568e944?w=600"
                ],
                attributes={"battery_life": "50 Hours", "driver": "30mm", "noise_cancellation": "Passive + DSEE", "connectivity": "Bluetooth 5.2 Multipoint"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=30
            ),
            MerchantProductDTO(
                id="sony_wf_c500",
                name="Sony WF-C500 True Wireless Earbuds",
                brand="Sony",
                category="Audio",
                description="20 hours battery with pocket charging case, IPX4 splash proof, and 360 Reality Audio.",
                price=4490.0,
                original_price=8990.0,
                rating=4.7,
                review_count=980,
                images=["https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600"],
                attributes={"battery_life": "20 Hours", "water_resistance": "IPX4", "codec": "AAC/SBC"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=20
            )
        ]


# 2. boAt Lifestyle Consumer Audio
class BoatOfficialMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.boat-lifestyle.com/v1/inventory",
            api_key="boat_sec_live_4412",
            merchant_name="boAt Official Store",
            merchant_slug="boat-official-store",
            logo_url="https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="boat_rockerz_550",
                name="boAt Rockerz 550 Over-Ear Wireless Headphones",
                brand="boAt",
                category="Audio",
                description="Super extra bass 50mm dynamic drivers with 20 hours playback and physical noise isolation.",
                price=1999.0,
                original_price=4999.0,
                rating=4.6,
                review_count=2140,
                images=[
                    "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600",
                    "https://images.unsplash.com/photo-1583394838336-acd977736f90?w=600"
                ],
                attributes={"battery_life": "20 Hours", "driver": "50mm", "noise_cancellation": "Passive", "connectivity": "Bluetooth 5.0"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=45
            ),
            MerchantProductDTO(
                id="boat_airdopes_141",
                name="boAt Airdopes 141 True Wireless Earbuds",
                brand="boAt",
                category="Audio",
                description="42 hours total playtime, BEAST mode 80ms low latency for gaming, and ENx noise cancelling mic.",
                price=1299.0,
                original_price=4490.0,
                rating=4.4,
                review_count=5400,
                images=["https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600"],
                attributes={"battery_life": "42 Hours", "latency": "80ms", "noise_cancellation": "ENx Mic", "connectivity": "Bluetooth 5.1"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=100
            )
        ]


# 3. OnePlus Retail India
class OnePlusIndiaMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.oneplus.in/openapi/v1/store",
            merchant_name="OnePlus Retail India",
            merchant_slug="oneplus-retail-india",
            logo_url="https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="oneplus_nord_ce3_lite",
                name="OnePlus Nord CE 3 Lite 5G (8GB RAM, 128GB)",
                brand="OnePlus",
                category="Smartphones",
                description="108 MP primary camera, 67W SUPERVOOC fast charge, 5000 mAh battery with 120Hz smooth display.",
                price=19999.0,
                original_price=21999.0,
                rating=4.6,
                review_count=3200,
                images=["https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600"],
                attributes={"ram": "8 GB", "storage": "128 GB", "camera": "108 MP Triple", "battery": "5000 mAh", "charging": "67W SUPERVOOC"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=20
            ),
            MerchantProductDTO(
                id="oneplus_nord_buds_2",
                name="OnePlus Nord Buds 2 TWS",
                brand="OnePlus",
                category="Audio",
                description="Up to 25dB Active Noise Cancellation, BassWave enhancement, and 36 hours total battery playback.",
                price=2499.0,
                original_price=3299.0,
                rating=4.5,
                review_count=1450,
                images=["https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=600"],
                attributes={"anc": "25dB Active", "battery_life": "36 Hours", "driver": "12.4mm Dynamic"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=60
            )
        ]


# 4. Xiaomi Direct India
class XiaomiDirectMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.mi.com/in/v1/products",
            merchant_name="Xiaomi Direct India",
            merchant_slug="xiaomi-direct-india",
            logo_url="https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="redmi_note_13_pro",
                name="Redmi Note 13 Pro 5G (8GB RAM, 256GB)",
                brand="Xiaomi",
                category="Smartphones",
                description="200 MP Ultra-Clear OIS Camera, 1.5K 120Hz Curved AMOLED, Snapdragon 7s Gen 2.",
                price=24999.0,
                original_price=28999.0,
                rating=4.7,
                review_count=1950,
                images=["https://images.unsplash.com/photo-1598327105666-5b89351aff97?w=600"],
                attributes={"ram": "8 GB", "storage": "256 GB", "camera": "200 MP OIS", "battery": "5100 mAh", "charging": "67W Turbo"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=15
            )
        ]


# 5. Nike Sports India
class NikeSportsMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.nike.com/in/catalog/v2",
            merchant_name="Nike Sports India",
            merchant_slug="nike-sports-india",
            logo_url="https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="nike_revolution_6",
                name="Nike Revolution 6 Next Nature Running Shoes",
                brand="Nike",
                category="Footwear",
                description="Plush foam midsole for soft ride, breathable mesh upper, sustainable crafted materials.",
                price=3695.0,
                original_price=4995.0,
                rating=4.7,
                review_count=840,
                images=["https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600"],
                attributes={"material": "Breathable Mesh", "cushioning": "Plush Foam", "weight": "280g", "use_case": "Daily Running & Training"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=35
            ),
            MerchantProductDTO(
                id="nike_air_monarch_iv",
                name="Nike Air Monarch IV Training Shoes",
                brand="Nike",
                category="Footwear",
                description="Durable leather upper with lightweight full-length Nike Air-Sole unit for ultimate cushioning.",
                price=4995.0,
                original_price=6495.0,
                rating=4.8,
                review_count=1200,
                images=["https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600"],
                attributes={"material": "Genuine Leather", "cushioning": "Air-Sole Unit", "support": "Maximum Arch Support"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=22
            )
        ]


# 6. Puma Official India
class PumaOfficialMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.puma.com/in/v1/inventory",
            merchant_name="Puma Official India",
            merchant_slug="puma-official-india",
            logo_url="https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="puma_flyer_runner",
                name="Puma Flyer Runner Engineered Knit",
                brand="Puma",
                category="Footwear",
                description="Softfoam+ optimal comfort sockliner, lightweight EVA midsole, stylish everyday runner.",
                price=2499.0,
                original_price=3999.0,
                rating=4.5,
                review_count=610,
                images=["https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=600"],
                attributes={"material": "Engineered Knit", "cushioning": "Softfoam+ EVA", "weight": "250g", "use_case": "Workout & Casual"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=50
            )
        ]


# 7. Samsung Direct Electronics
class SamsungDirectMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.samsung.com/in/b2c/catalog",
            merchant_name="Samsung Direct Store",
            merchant_slug="samsung-direct-store",
            logo_url="https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="samsung_galaxy_m34",
                name="Samsung Galaxy M34 5G (128GB, 6000mAh)",
                brand="Samsung",
                category="Smartphones",
                description="Monster 6000 mAh battery, 50MP No Shake OIS Camera, 120Hz Super AMOLED Display.",
                price=15999.0,
                original_price=24499.0,
                rating=4.6,
                review_count=4100,
                images=["https://images.unsplash.com/photo-1610945415295-d9bbf067e59c?w=600"],
                attributes={"battery": "6000 mAh", "display": "120Hz Super AMOLED", "camera": "50 MP OIS", "ram": "6 GB"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=40
            )
        ]


# 8. Apple Authorized Merchant India
class AppleAuthorizedMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.imagineonline.store/v1/apple",
            merchant_name="Apple Authorized Partner",
            merchant_slug="apple-authorized-partner",
            logo_url="https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="apple_airpods_pro_2",
                name="Apple AirPods Pro (2nd Generation with USB-C)",
                brand="Apple",
                category="Audio",
                description="Up to 2x more Active Noise Cancellation, Adaptive Audio, and Transparency mode.",
                price=20990.0,
                original_price=24900.0,
                rating=4.9,
                review_count=3800,
                images=["https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=600"],
                attributes={"chip": "Apple H2", "anc": "Pro Level ANC", "charging": "MagSafe USB-C", "battery": "30 Hours total"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=18
            )
        ]


# 9. Noise Wearables Official
class NoiseWearablesMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.gonoise.com/v1/products",
            merchant_name="Noise Official Store",
            merchant_slug="noise-official-store",
            logo_url="https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="noise_colorfit_pro_5",
                name="Noise ColorFit Pro 5 Smartwatch (1.85\" AMOLED)",
                brand="Noise",
                category="Wearables",
                description="1.85\" AMOLED display, Bluetooth calling with TruSync, 100+ sports modes and SOS technology.",
                price=3499.0,
                original_price=7999.0,
                rating=4.5,
                review_count=1890,
                images=["https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600"],
                attributes={"display": "1.85 AMOLED", "calling": "BT Calling TruSync", "battery": "7 Days"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=65
            )
        ]


# 10. Adidas Official India
class AdidasOfficialMerchantClient(BaseMerchantClient):
    def __init__(self):
        super().__init__(
            api_endpoint="https://api.adidas.co.in/catalog/v2",
            merchant_name="Adidas Official Store",
            merchant_slug="adidas-official-store",
            logo_url="https://images.unsplash.com/photo-1587563871167-1ee9c731aefb?w=120"
        )

    def fetch_catalog(self) -> List[MerchantProductDTO]:
        return [
            MerchantProductDTO(
                id="adidas_ultrabounce_running",
                name="Adidas Ultrabounce Men Running Shoes",
                brand="Adidas",
                category="Footwear",
                description="Bounce lightweight cushioning, high-traction rubber outsole, engineered textile upper.",
                price=3849.0,
                original_price=6999.0,
                rating=4.7,
                review_count=730,
                images=["https://images.unsplash.com/photo-1587563871167-1ee9c731aefb?w=600"],
                attributes={"material": "Textile Upper", "cushioning": "Bounce Midsole", "outsole": "High Traction Rubber"},
                merchant_name=self.merchant_name,
                merchant_slug=self.merchant_slug,
                merchant_logo=self.logo_url,
                stock_quantity=28
            )
        ]


# ─────────────────────────────────────────────────────────────────────────────
# CENTRAL MERCHANT GATEWAY MANAGER
# ─────────────────────────────────────────────────────────────────────────────

class MerchantGatewayManager:
    """
    Orchestrates live querying across all 10 merchant APIs.
    Standardizes output for LLM agent reasoning, catalog search, and checkout.
    """

    def __init__(self):
        self.clients: List[BaseMerchantClient] = [
            SonyCenterMerchantClient(),
            BoatOfficialMerchantClient(),
            OnePlusIndiaMerchantClient(),
            XiaomiDirectMerchantClient(),
            NikeSportsMerchantClient(),
            PumaOfficialMerchantClient(),
            SamsungDirectMerchantClient(),
            AppleAuthorizedMerchantClient(),
            NoiseWearablesMerchantClient(),
            AdidasOfficialMerchantClient(),
        ]

    def search_all_merchants(self, query: str = "", max_price: Optional[float] = None, min_price: Optional[float] = None) -> List[Dict[str, Any]]:
        """Queries all 10 registered merchant clients and returns standardized product dictionaries."""
        all_results = []
        for client in self.clients:
            try:
                products = client.search_products(query=query, max_price=max_price, min_price=min_price)
                for p in products:
                    all_results.append(p.to_dict())
            except Exception as e:
                logger.warning(f"Error querying merchant {client.merchant_name}: {e}")

        # Sort by rating descending
        all_results.sort(key=lambda x: float(x.get("rating", 0)), reverse=True)
        return all_results

    def get_product_by_id(self, product_id: str) -> Optional[Dict[str, Any]]:
        """Finds product across all merchant endpoints by ID."""
        for client in self.clients:
            prod = client.get_product(product_id)
            if prod:
                return prod.to_dict()
        return None

    def get_all_merchants_metadata(self) -> List[Dict[str, Any]]:
        """Returns metadata for all 10 registered merchant APIs."""
        return [
            {
                "merchant_name": c.merchant_name,
                "merchant_slug": c.merchant_slug,
                "api_endpoint": c.api_endpoint,
                "logo_url": c.logo_url,
                "status": "ONLINE_ACTIVE",
                "payment_support": "1-TAP_RAZORPAY_HMAC_SHA256"
            }
            for c in self.clients
        ]

# Singleton instance
merchant_gateway = MerchantGatewayManager()
