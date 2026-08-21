import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class CatalogProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = _defaultCatalog;
  bool _isLoading = false;

  List<Map<String, dynamic>> get products => _products;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? get topRecommendation =>
      _products.isNotEmpty ? _products.first : null;

  Map<String, dynamic>? get secondRecommendation =>
      _products.length > 1 ? _products[1] : null;

  CatalogProvider() {
    loadProducts();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await ApiService().getProducts();
      if (result.isNotEmpty) {
        _products = result;
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  static final List<Map<String, dynamic>> _defaultCatalog = [
    {
      'id': 'boat_rockerz_550',
      'name': 'boAt Rockerz 550 Over-Ear Wireless Headphones',
      'brand': 'boAt',
      'category': {'name': 'Audio', 'slug': 'audio'},
      'description': 'Super extra bass 50mm dynamic drivers with 20 hours playback and physical noise isolation.',
      'price': '1999.00',
      'original_price': '4999.00',
      'rating': 4.6,
      'review_count': 2140,
      'stock_quantity': 45,
      'images': ['https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=600'],
      'attributes': {'battery_life': '20 Hours', 'driver': '50mm', 'noise_cancellation': 'Passive'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'boAt Lifestyle Official', 'rating': 4.7}
    },
    {
      'id': 'sony_wh_ch520',
      'name': 'Sony WH-CH520 Wireless Bluetooth Headphones',
      'brand': 'Sony',
      'category': {'name': 'Audio', 'slug': 'audio'},
      'description': 'Up to 50 hours battery life with quick charging and DSEE audio upscaling technology.',
      'price': '2999.00',
      'original_price': '4490.00',
      'rating': 4.8,
      'review_count': 1850,
      'stock_quantity': 30,
      'images': ['https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=600'],
      'attributes': {'battery_life': '50 Hours', 'driver': '30mm', 'connectivity': 'Bluetooth 5.2 Multipoint'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'Sony Center Direct', 'rating': 4.9}
    },
    {
      'id': 'samsung_galaxy_m34',
      'name': 'Samsung Galaxy M34 5G (6GB RAM, 128GB)',
      'brand': 'Samsung',
      'category': {'name': 'Smartphones', 'slug': 'smartphones'},
      'description': '6000 mAh mega battery, 50MP No Shake Cam (OIS), 120Hz Super AMOLED Display.',
      'price': '16999.00',
      'original_price': '24499.00',
      'rating': 4.5,
      'review_count': 4100,
      'stock_quantity': 30,
      'images': ['https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=600'],
      'attributes': {'ram': '6 GB', 'storage': '128 GB', 'battery': '6000 mAh', 'display': 'Super AMOLED 120Hz'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'Samsung Direct Store', 'rating': 4.8}
    },
    {
      'id': 'noise_colorfit_pulse_2',
      'name': 'Noise ColorFit Pulse 2 Max 1.85-inch Smartwatch',
      'brand': 'Noise',
      'category': {'name': 'Wearables', 'slug': 'wearables'},
      'description': '1.85" brightest display, Bluetooth calling with Tru Sync, 10 days battery, 100 sports modes.',
      'price': '1499.00',
      'original_price': '5999.00',
      'rating': 4.6,
      'review_count': 3200,
      'stock_quantity': 50,
      'images': ['https://images.unsplash.com/photo-1508685096489-7aacd43bd3b1?w=600'],
      'attributes': {'display': '1.85 inch TFT 550 nits', 'battery': '10 Days', 'calling': 'Tru Sync BT Calling'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'Noise Official Store', 'rating': 4.7}
    },
    {
      'id': 'red_tape_athleisure',
      'name': 'Red Tape Lightweight Breathable Athleisure Runners',
      'brand': 'Red Tape',
      'category': {'name': 'Footwear', 'slug': 'footwear'},
      'description': 'Engineered knit mesh upper for extreme breathability with shock-absorbing cloud sole.',
      'price': '1499.00',
      'original_price': '5399.00',
      'rating': 4.5,
      'review_count': 4500,
      'stock_quantity': 50,
      'images': ['https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=600'],
      'attributes': {'upper': 'Engineered Knit Mesh', 'weight': '220g Ultra Lightweight'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'Red Tape Official Store', 'rating': 4.6}
    },
    {
      'id': 'snitch_linen_shirt',
      'name': 'Snitch Cuban Collar Linen Blend Relaxed Shirt',
      'brand': 'Snitch',
      'category': {'name': 'Fashion', 'slug': 'fashion'},
      'description': 'Breathable pure premium linen blend, resort relaxed fit with modern Cuban camp collar.',
      'price': '1399.00',
      'original_price': '2299.00',
      'rating': 4.7,
      'review_count': 1600,
      'stock_quantity': 40,
      'images': ['https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=600'],
      'attributes': {'fabric': 'Linen Blend', 'fit': 'Relaxed Cuban Fit', 'wash': 'Machine Cold'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'Snitch Fast Fashion Direct', 'rating': 4.8}
    },
    {
      'id': 'derma_co_sunscreen',
      'name': 'The Derma Co 1% Hyaluronic Sunscreen Aqua Gel SPF 50',
      'brand': 'The Derma Co',
      'category': {'name': 'Personal Care', 'slug': 'personal-care'},
      'description': 'Broad spectrum SPF 50 PA++++, ultra-lightweight water gel with Vitamin E and zero white cast.',
      'price': '449.00',
      'original_price': '499.00',
      'rating': 4.8,
      'review_count': 4900,
      'stock_quantity': 120,
      'images': ['https://images.unsplash.com/photo-1556228720-195a672e8a03?w=600'],
      'attributes': {'spf': 'SPF 50 PA++++', 'key_actives': 'Hyaluronic Acid + Vitamin E', 'skin_type': 'All Skin Types'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'The Derma Co Direct', 'rating': 4.7}
    },
    {
      'id': 'muscleblaze_whey',
      'name': 'MuscleBlaze Biozyme Performance Whey (Rich Chocolate 1kg)',
      'brand': 'MuscleBlaze',
      'category': {'name': 'Food & Nutrition', 'slug': 'food-nutrition'},
      'description': 'Clinically tested 50% higher protein absorption, 25g protein per scoop, informed choice certified.',
      'price': '2499.00',
      'original_price': '3499.00',
      'rating': 4.8,
      'review_count': 7200,
      'stock_quantity': 60,
      'images': ['https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?w=600'],
      'attributes': {'protein_per_scoop': '25g Biozyme Whey', 'bcaa': '5.51g', 'flavor': 'Rich Chocolate'},
      'is_featured': true,
      'is_platform_product': true,
      'merchant': {'name': 'MuscleBlaze Official', 'rating': 4.8}
    },
  ];
}
