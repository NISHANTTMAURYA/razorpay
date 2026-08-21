class ApiConstants {
  // Backend URL works on physical Android, web & desktop
  static String _activeBaseUrl = 'http://192.168.29.231:8000';
  static const String lanFallbackUrl = 'http://192.168.29.231:8000';

  static String get baseUrl => _activeBaseUrl;

  static void useLanFallback() {
    _activeBaseUrl = lanFallbackUrl;
  }

  static void setBaseUrl(String url) {
    _activeBaseUrl = url.trim();
  }

  // Supabase Configuration
  static String _supabaseUrl = 'https://xyzcompany.supabase.co';
  static String _supabaseAnonKey = 'sb_anon_key_mitrai_placeholder';

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;

  static bool get isRealSupabaseConfigured =>
      !_supabaseUrl.contains('xyzcompany.supabase.co') &&
      !_supabaseAnonKey.contains('placeholder') &&
      _supabaseUrl.startsWith('https://');

  static void setSupabaseConfig(String url, String anonKey) {
    _supabaseUrl = url.trim();
    _supabaseAnonKey = anonKey.trim();
  }

  // Razorpay Test Key
  static const String razorpayKeyId = 'rzp_test_TS9z7ilhd69feu';
}
