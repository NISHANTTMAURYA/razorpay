import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Backend URL auto-detects localhost vs Android Emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  // Supabase Configuration (Placeholder defaults or injected via env)
  static const String supabaseUrl = 'https://xyzcompany.supabase.co';
  static const String supabaseAnonKey = 'sb_anon_key_mitrai_placeholder';

  // Razorpay Test Key
  static const String razorpayKeyId = 'rzp_test_TS9z7ilhd69feu';
}
