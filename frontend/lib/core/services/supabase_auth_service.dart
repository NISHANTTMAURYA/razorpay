import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  bool _isInitialized = false;

  // In-memory & persisted demo user state for guest mode or offline exploration
  User? _mockUser;
  bool _isGuest = false;

  bool get isAuthenticated => currentUser != null;
  bool get isGuest => _isGuest;

  User? get currentUser {
    if (_isGuest || _mockUser != null) {
      return _mockUser;
    }
    if (_isInitialized) {
      return Supabase.instance.client.auth.currentUser;
    }
    return null;
  }

  String get userId => currentUser?.id ?? 'demo_bohdan_123';
  String get userEmail => currentUser?.email ?? 'bohdan@mitrai.ai';
  String get userName {
    if (currentUser?.userMetadata != null &&
        currentUser!.userMetadata!['full_name'] != null) {
      return currentUser!.userMetadata!['full_name'].toString();
    }
    return userEmail.split('@').first;
  }

  Future<void> initialize() async {
    // 1. Restore local session from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLogin = prefs.getBool('is_logged_in') ?? false;
      if (savedLogin) {
        final name = prefs.getString('user_name') ?? 'Bohdan';
        final email = prefs.getString('user_email') ?? 'bohdan@mitrai.ai';
        final id = prefs.getString('user_id') ?? 'demo_bohdan_123';
        final isGuest = prefs.getBool('is_guest') ?? true;
        _isGuest = isGuest;
        _mockUser = User(
          id: id,
          appMetadata: {},
          userMetadata: {
            'full_name': name,
            'avatar_url':
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
          },
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: email,
        );
      }
    } catch (e) {
      debugPrint('Prefs init notice: $e');
    }

    // 2. Initialize Supabase if available
    if (_isInitialized) return;
    try {
      if (ApiConstants.supabaseUrl.startsWith('http')) {
        await Supabase.initialize(
          url: ApiConstants.supabaseUrl,
          // ignore: deprecated_member_use
          anonKey: ApiConstants.supabaseAnonKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );
        _isInitialized = true;
      }
    } catch (e) {
      debugPrint('Supabase init notice: $e');
      _isInitialized = false;
    }
  }

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      GoogleSignIn googleSignIn;
      try {
        googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: kIsWeb
              ? '100000000000-dummyclientidforwebmockmode.apps.googleusercontent.com'
              : null,
        );
      } catch (e) {
        debugPrint('GoogleSignIn config notice: $e');
        await signInAsDemoUser(name: 'Mitrai Explorer', email: 'explorer@mitrai.ai');
        return null;
      }

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (_isInitialized && idToken != null) {
        final response = await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );
        _isGuest = false;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('is_guest', false);
          await prefs.setString('user_name', googleUser.displayName ?? 'Google User');
          await prefs.setString('user_email', googleUser.email);
          await prefs.setString('user_id', googleUser.id);
        } catch (_) {}
        return response;
      } else {
        _isGuest = false;
        _mockUser = User(
          id: 'google_${googleUser.id}',
          appMetadata: {},
          userMetadata: {
            'full_name': googleUser.displayName ?? 'Google User',
            'avatar_url': googleUser.photoUrl ?? '',
          },
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: googleUser.email,
        );
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('is_guest', false);
          await prefs.setString('user_name', googleUser.displayName ?? 'Google User');
          await prefs.setString('user_email', googleUser.email);
          await prefs.setString('user_id', 'google_${googleUser.id}');
        } catch (_) {}
        return null;
      }
    } catch (e) {
      debugPrint('Google Sign-In fallback: $e');
      await signInAsDemoUser(name: 'Mitrai Explorer', email: 'explorer@mitrai.ai');
      return null;
    }
  }

  Future<void> signInAsDemoUser({
    String name = 'Bohdan',
    String email = 'bohdan@mitrai.ai',
  }) async {
    _isGuest = true;
    _mockUser = User(
      id: 'demo_bohdan_123',
      appMetadata: {},
      userMetadata: {
        'full_name': name,
        'avatar_url':
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', true);
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      await prefs.setString('user_id', 'demo_bohdan_123');
    } catch (_) {}
  }

  Future<void> signOut() async {
    _isGuest = false;
    _mockUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (_isInitialized) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (e) {
      debugPrint('Sign-out notice: $e');
    }
  }
}
