import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class WatcherProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _watchers = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get watchers => _watchers;
  bool get isLoading => _isLoading;
  int get activeCount => _watchers.where((w) => w['status'] == 'ACTIVE').length;

  WatcherProvider() {
    loadWatchers();
  }

  Future<void> loadWatchers() async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService().getWatchers();
    _watchers = result;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addWatcher({
    required String productId,
    required String conditionType,
    double? targetPrice,
  }) async {
    final res = await ApiService().watchProduct(
      productId: productId,
      conditionType: conditionType,
      targetPrice: targetPrice,
    );
    if (res['status'] != 'error') {
      await loadWatchers();
      return true;
    }
    return false;
  }

  Future<bool> removeWatcher(String watcherId) async {
    final success = await ApiService().deleteWatcher(watcherId);
    if (success) {
      _watchers.removeWhere((w) => w['id']?.toString() == watcherId);
      notifyListeners();
    }
    return success;
  }
}
