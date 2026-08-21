import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class WatcherProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _watchers = [];
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get watchers => _watchers;
  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get activeCount => _watchers.where((w) => w['status'] == 'ACTIVE').length;
  int get unreadNotificationsCount => _notifications.length;

  WatcherProvider() {
    loadWatchers();
    loadNotifications();
  }

  Future<void> loadWatchers() async {
    _isLoading = true;
    notifyListeners();

    final result = await ApiService().getWatchers();
    _watchers = result;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNotifications() async {
    final notifs = await ApiService().getWatchNotifications();
    _notifications = notifs;
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
