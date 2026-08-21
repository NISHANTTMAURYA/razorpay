import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'supabase_auth_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  Map<String, String> get _headers {
    final auth = SupabaseAuthService();
    final userId = auth.userId;
    // Use mock_token_ prefix — backend's SupabaseAuthentication handles this
    // for dev/Google Sign-In flow where no real Supabase JWT is available.
    final token = 'mock_token_$userId';
    return {
      'Content-Type': 'application/json',
      'X-User-ID': userId,
      'Authorization': 'Bearer $token',
    };
  }

  // Helper for resilient GET requests with automatic LAN failover
  Future<http.Response> _resilientGet(Uri uri) async {
    try {
      return await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
    } catch (e) {
      if (ApiConstants.baseUrl.contains('127.0.0.1')) {
        ApiConstants.useLanFallback();
        final fallbackUri = Uri.parse(uri.toString().replaceAll('http://127.0.0.1:8000', ApiConstants.baseUrl));
        return await http.get(fallbackUri, headers: _headers).timeout(const Duration(seconds: 8));
      }
      rethrow;
    }
  }

  // Helper for resilient POST requests with automatic LAN failover
  Future<http.Response> _resilientPost(Uri uri, String body) async {
    try {
      return await http.post(uri, headers: _headers, body: body).timeout(const Duration(seconds: 30));
    } catch (e) {
      if (ApiConstants.baseUrl.contains('127.0.0.1')) {
        ApiConstants.useLanFallback();
        final fallbackUri = Uri.parse(uri.toString().replaceAll('http://127.0.0.1:8000', ApiConstants.baseUrl));
        return await http.post(fallbackUri, headers: _headers, body: body).timeout(const Duration(seconds: 30));
      }
      rethrow;
    }
  }

  // 1. Fetch Live Products from Django Catalog
  Future<List<Map<String, dynamic>>> getProducts({String? category, double? maxPrice, String? query}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/commerce/products/').replace(
        queryParameters: {
          if (category != null) 'category': category,
          if (maxPrice != null) 'max_price': maxPrice.toString(),
          if (query != null) 'q': query,
        },
      );
      final response = await _resilientGet(uri);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('Products API Error: $e');
    }
    return [];
  }

  // 2. Chat with Live LangGraph AI Agent
  Future<Map<String, dynamic>> sendAgentMessage({
    required String message,
    List<Map<String, String>>? history,
    String? conversationId,
    String? cartId,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/agent/chat/');
      final response = await _resilientPost(
        url,
        jsonEncode({
          'message': message,
          'history': history ?? [],
          'conversation_id': conversationId ?? 'conv_mitrai_active',
          'user_id': SupabaseAuthService().userId,
          'cart_id': cartId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Agent API Error: $e');
    }

    return {
      'intent': 'ERROR',
      'response': 'Unable to connect to AI Commerce server. Please ensure backend is running.',
      'products': [],
      'steps': [],
      'suggested_actions': []
    };
  }

  /// Dispatches Celery background agent task so research continues even if user exits
  Future<Map<String, dynamic>> sendBackgroundChatMessage({
    required String message,
    List<Map<String, dynamic>>? history,
    String? cartId,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/agent/background-chat/');
      final response = await _resilientPost(
        url,
        jsonEncode({
          'message': message,
          'history': history ?? [],
          'user_id': SupabaseAuthService().userId,
          'cart_id': cartId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 202) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Background Agent API Error: $e');
    }

    return {
      'status': 'FAILED',
      'message': 'Failed to launch background research task.'
    };
  }

  // 3. Cart Management on Live Backend
  Future<Map<String, dynamic>> getCart() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/cart/').replace(
        queryParameters: {'user_id': SupabaseAuthService().userId},
      );
      final response = await _resilientGet(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Cart API Error: $e');
    }

    return {
      'id': '',
      'status': 'ACTIVE',
      'total_items': 0,
      'subtotal': '0.00',
      'items': []
    };
  }

  Future<Map<String, dynamic>> addToCart({required dynamic productId, int quantity = 1, String? productName}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/cart/item/');
      final payload = <String, dynamic>{
        'user_id': SupabaseAuthService().userId,
        'product_id': productId,
        'quantity': quantity,
      };
      if (productName != null && productName.isNotEmpty) {
        payload['product_name'] = productName;
      }
      final body = jsonEncode(payload);
      debugPrint('🛒 [API] addToCart REQUEST: url=$url, body=$body');
      final response = await _resilientPost(url, body);

      debugPrint('🛒 [API] addToCart RESPONSE: status=${response.statusCode}, body=${response.body.substring(0, response.body.length.clamp(0, 500))}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('🛒 [API] addToCart FAILED: status=${response.statusCode}, body=${response.body}');
      }
    } catch (e) {
      debugPrint('🛒 [API] AddToCart EXCEPTION: $e');
    }

    return await getCart();
  }

  // 4. Real Razorpay Checkout & Cryptographic HMAC Verification
  Future<Map<String, dynamic>> checkout({required String cartId, required Map<String, dynamic> shippingAddress}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/checkout/initiate/');
      final response = await _resilientPost(
        url,
        jsonEncode({
          'cart_id': cartId,
          'user_id': SupabaseAuthService().userId,
          'shipping_address': shippingAddress,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Checkout API Error: $e');
    }

    return {
      'error': 'Checkout failed on server',
      'order_id': '',
      'razorpay_order_id': '',
      'amount': 0,
      'currency': 'INR',
    };
  }

  Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/payment/verify/');
      final response = await _resilientPost(
        url,
        jsonEncode({
          'order_id': orderId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('VerifyPayment API Error: $e');
    }

    return {
      'status': 'FAILED',
      'message': 'Payment verification failed on server.',
      'order': null
    };
  }

  // 5. Dynamic Product Watcher & Radar (Celery + Redis)
  Future<Map<String, dynamic>> watchProduct({
    required String productId,
    required String conditionType,
    double? targetPrice,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/watchers/');
      final response = await _resilientPost(
        url,
        jsonEncode({
          'product_id': productId,
          'user_id': SupabaseAuthService().userId,
          'condition_type': conditionType,
          if (targetPrice != null) 'target_value': targetPrice.toString(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('WatchProduct API Error: $e');
    }

    return {
      'status': 'error',
      'message': 'Failed to create watcher on backend',
    };
  }

  Future<List<Map<String, dynamic>>> getWatchers() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/watchers/').replace(
        queryParameters: {'user_id': SupabaseAuthService().userId},
      );
      final response = await _resilientGet(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('GetWatchers API Error: $e');
    }
    return [];
  }

  Future<bool> deleteWatcher(String watcherId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/watchers/$watcherId/');
      // Note: Kept standard delete as there is no _resilientDelete helper
      final response = await http.delete(url, headers: _headers).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeleteWatcher API Error: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getWatchNotifications() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/watchers/notifications/').replace(
        queryParameters: {'user_id': SupabaseAuthService().userId},
      );
      final response = await _resilientGet(url);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      debugPrint('GetWatchNotifications API Error: $e');
    }
    return [];
  }

  // 6. User Profile & Backend Sync

  /// Called once after login to write the authenticated user into the Django DB.
  /// Uses POST /api/auth/sync-supabase/ which does update_or_create on supabase_uid.
  Future<void> syncUserToBackend() async {
    try {
      final auth = SupabaseAuthService();
      final url = Uri.parse('${ApiConstants.baseUrl}/api/auth/sync-supabase/');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'supabase_uid': auth.userId,
          'email': auth.userEmail,
          'full_name': auth.userName,
          if (auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty)
            'avatar_url': auth.avatarUrl,
        }),
      ).timeout(const Duration(seconds: 8));
      debugPrint('SyncUser status: ${response.statusCode} body: ${response.body}');
    } catch (e) {
      debugPrint('SyncUser API Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final uid = SupabaseAuthService().userId;
      final url = Uri.parse('${ApiConstants.baseUrl}/api/auth/profile/').replace(
        queryParameters: {'uid': uid},
      );
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('GetUserProfile API Error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> updateUserProfile(Map<String, dynamic> data) async {
    try {
      final uid = SupabaseAuthService().userId;
      final payload = Map<String, dynamic>.from(data);
      payload['supabase_uid'] = uid;
      final url = Uri.parse('${ApiConstants.baseUrl}/api/auth/profile/');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('UpdateUserProfile API Error: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final uid = SupabaseAuthService().userId;
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/orders/').replace(
        queryParameters: {'user_id': uid},
      );
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('GetOrders API Error: $e');
    }
    return [];
  }
}
