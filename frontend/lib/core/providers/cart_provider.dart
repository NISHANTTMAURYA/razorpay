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

    final result = await ApiService().getCart();
    _cart = result;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addItem(int productId, {int quantity = 1}) async {
    final updatedCart = await ApiService().addToCart(productId: productId, quantity: quantity);
    _cart = updatedCart;
    notifyListeners();
  }

  Future<void> updateItemQuantity(int productId, int quantity) async {
    final updatedCart = await ApiService().addToCart(productId: productId, quantity: quantity);
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
