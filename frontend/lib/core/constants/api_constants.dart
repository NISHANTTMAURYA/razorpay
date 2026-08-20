class ApiConstants {
  // Backend URL works on physical Android (via adb reverse tcp:8000 tcp:8000), web & desktop
  static String get baseUrl {
    return 'http://127.0.0.1:8000';
  }

  // Supabase Configuration (Placeholder defaults or injected via env)
  static const String supabaseUrl = 'https://xyzcompany.supabase.co';
  static const String supabaseAnonKey = 'sb_anon_key_mitrai_placeholder';

  // Razorpay Test Key
  static const String razorpayKeyId = 'rzp_test_TS9z7ilhd69feu';
}
