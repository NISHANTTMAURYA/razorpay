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
    final userId = SupabaseAuthService().userId;
    return {
      'Content-Type': 'application/json',
      'X-User-ID': userId,
    };
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
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
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
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'message': message,
          'history': history ?? [],
          'conversation_id': conversationId ?? 'conv_mitrai_active',
          'user_id': SupabaseAuthService().userId,
          'cart_id': cartId,
        }),
      ).timeout(const Duration(seconds: 30));

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

  // 3. Cart Management on Live Backend
  Future<Map<String, dynamic>> getCart() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/cart/').replace(
        queryParameters: {'user_id': SupabaseAuthService().userId},
      );
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
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

  Future<Map<String, dynamic>> addToCart({required int productId, int quantity = 1}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/cart/item/');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'user_id': SupabaseAuthService().userId,
          'product_id': productId,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('AddToCart API Error: $e');
    }

    return await getCart();
  }

  // 4. Real Razorpay Checkout & Cryptographic HMAC Verification
  Future<Map<String, dynamic>> checkout({required String cartId, required Map<String, dynamic> shippingAddress}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/commerce/checkout/initiate/');
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'cart_id': cartId,
          'user_id': SupabaseAuthService().userId,
          'shipping_address': shippingAddress,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
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
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'order_id': orderId,
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        }),
      ).timeout(const Duration(seconds: 10));

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
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'product_id': productId,
          'user_id': SupabaseAuthService().userId,
          'condition_type': conditionType,
          if (targetPrice != null) 'target_value': targetPrice.toString(),
        }),
      ).timeout(const Duration(seconds: 8));

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
      final response = await http.get(url, headers: _headers).timeout(const Duration(seconds: 8));
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
      final response = await http.delete(url, headers: _headers).timeout(const Duration(seconds: 8));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeleteWatcher API Error: $e');
      return false;
    }
  }
}
