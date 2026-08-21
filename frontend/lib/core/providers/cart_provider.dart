import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class CartProvider extends ChangeNotifier {
  Map<String, dynamic> _cart = {
    'id': '',
    'status': 'ACTIVE',
    'total_items': 0,
    'subtotal': '0.00',
    'items': <Map<String, dynamic>>[]
  };
  bool _isLoading = false;

  Map<String, dynamic> get cart => _cart;
  bool get isLoading => _isLoading;
  List<dynamic> get items => (_cart['items'] as List?) ?? [];
  int get itemCount => items.length;
  double get subtotal => double.tryParse(_cart['subtotal']?.toString() ?? '0') ?? 0.0;
  String get cartId => _cart['id']?.toString() ?? '';

  CartProvider() {
    loadCart();
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    debugPrint('🛒 [CART] Loading cart...');
    final result = await ApiService().getCart();
    debugPrint('🛒 [CART] Loaded: ${result['total_items']} items, subtotal=₹${result['subtotal']}');
    final items = (result['items'] as List?) ?? [];
    for (final item in items) {
      final prod = item['product'] as Map<String, dynamic>? ?? {};
      debugPrint('🛒 [CART]   - ${prod['name']} (id=${prod['id']}, qty=${item['quantity']}, price=₹${item['unit_price']})');
    }
    _cart = result;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(dynamic productId, {int quantity = 1, String? productName}) async {
    debugPrint('🛒 [CART] addItem called: productId=$productId (type=${productId.runtimeType}), quantity=$quantity, name=$productName');
    final updatedCart = await ApiService().addToCart(productId: productId, quantity: quantity, productName: productName);
    debugPrint('🛒 [CART] addItem result: ${updatedCart['total_items']} items, subtotal=₹${updatedCart['subtotal']}');
    _cart = updatedCart;
    notifyListeners();
  }

  Future<void> updateItemQuantity(dynamic productId, int quantity, {String? productName}) async {
    debugPrint('🛒 [CART] updateItemQuantity: productId=$productId, newQty=$quantity');
    if (quantity <= 0) {
      return removeItem(productId, productName: productName);
    }
    final updatedCart = await ApiService().addToCart(productId: productId, quantity: quantity, productName: productName);
    _cart = updatedCart;
    notifyListeners();
  }

  Future<void> removeItem(dynamic productId, {String? productName}) async {
    debugPrint('🛒 [CART] removeItem: productId=$productId');
    final updatedCart = await ApiService().addToCart(productId: productId, quantity: 0, productName: productName);
    _cart = updatedCart;
    notifyListeners();
  }

  void clearCart() {
    _cart = {
      'id': '',
      'status': 'ACTIVE',
      'total_items': 0,
      'subtotal': '0.00',
      'items': <Map<String, dynamic>>[]
    };
    notifyListeners();
  }
}
