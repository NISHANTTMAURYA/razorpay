import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class CatalogProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _products = [];
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

    final result = await ApiService().getProducts();
    _products = result;
    _isLoading = false;
    notifyListeners();
  }
}
