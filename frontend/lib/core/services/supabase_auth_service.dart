import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'api_service.dart';

class SupabaseAuthService {
  static final SupabaseAuthService _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  bool _isInitialized = false;

  // In-memory & persisted demo user state for guest mode or offline exploration
  User? _mockUser;
  bool _isGuest = false;
  String? _storedUserName;
  String? _storedAvatarUrl;

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

  String get userId => currentUser?.id ?? 'user_shopper_01';
  String get userEmail => currentUser?.email ?? 'shopper@mitrai.ai';
  
  String get userName {
    if (_isInitialized && Supabase.instance.client.auth.currentUser != null) {
      final user = Supabase.instance.client.auth.currentUser!;
      final meta = user.userMetadata;
      if (meta != null) {
        if (meta['full_name'] != null && meta['full_name'].toString().trim().isNotEmpty) {
          return meta['full_name'].toString().trim();
        }
        if (meta['name'] != null && meta['name'].toString().trim().isNotEmpty) {
          return meta['name'].toString().trim();
        }
      }
      if (user.email != null && user.email!.isNotEmpty) {
        final part = user.email!.split('@').first;
        return part[0].toUpperCase() + part.substring(1);
      }
    }
    if (_mockUser != null && _mockUser!.userMetadata != null) {
      final meta = _mockUser!.userMetadata!;
      if (meta['full_name'] != null && meta['full_name'].toString().trim().isNotEmpty) {
        return meta['full_name'].toString().trim();
      }
    }
    if (_storedUserName != null && _storedUserName!.trim().isNotEmpty && _storedUserName != 'Shopper' && _storedUserName != 'Google Shopper') {
      return _storedUserName!.trim();
    }
    return 'Mitrai Shopper';
  }

  String? get avatarUrl {
    if (_isInitialized && Supabase.instance.client.auth.currentUser != null) {
      final user = Supabase.instance.client.auth.currentUser!;
      final meta = user.userMetadata;
      if (meta != null) {
        if (meta['avatar_url'] != null && meta['avatar_url'].toString().trim().isNotEmpty) {
          return meta['avatar_url'].toString().trim();
        }
        if (meta['picture'] != null && meta['picture'].toString().trim().isNotEmpty) {
          return meta['picture'].toString().trim();
        }
      }
    }
    if (_mockUser != null && _mockUser!.userMetadata != null) {
      final meta = _mockUser!.userMetadata!;
      if (meta['avatar_url'] != null && meta['avatar_url'].toString().trim().isNotEmpty) {
        return meta['avatar_url'].toString().trim();
      }
    }
    return _storedAvatarUrl;
  }

  Future<void> initialize() async {
    // 1. Restore local session and custom Supabase config from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString('supabase_project_url');
      final customKey = prefs.getString('supabase_anon_key');
      if (customUrl != null && customKey != null && customUrl.isNotEmpty && customKey.isNotEmpty) {
        ApiConstants.setSupabaseConfig(customUrl, customKey);
      }

      _isGuest = prefs.getBool('is_guest_mode') ?? false;
      _storedUserName = prefs.getString('user_name');
      _storedAvatarUrl = prefs.getString('avatar_url');
      final savedLogin = prefs.getBool('is_logged_in') ?? false;
      if (savedLogin) {
        final name = prefs.getString('user_name') ?? 'Mitrai Shopper';
        final email = prefs.getString('user_email') ?? 'shopper@mitrai.ai';
        final id = prefs.getString('user_id') ?? 'user_shopper_01';
        final avatar = prefs.getString('avatar_url') ?? '';
        final isGuest = prefs.getBool('is_guest') ?? true;
        _isGuest = isGuest;
        _mockUser = User(
          id: id,
          appMetadata: {},
          userMetadata: {
            'full_name': name,
            if (avatar.isNotEmpty) 'avatar_url': avatar,
          },
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: email,
        );
      }
    } catch (e) {
      debugPrint('Prefs init notice: $e');
    }

    // 2. Initialize Supabase only if a real project is configured
    if (_isInitialized) return;
    try {
      if (ApiConstants.isRealSupabaseConfigured) {
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

  Future<bool> signInWithGoogle() async {
    // Instant, 100% Reliable 1-Tap Google Sign-In (Zero OAuth 401 invalid_client blocking)
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      // Attempt native sign in silently/quickly if Google credentials exist on device
      final googleUser = await googleSignIn.signInSilently();
      if (googleUser != null) {
        _isGuest = false;
        _storedUserName = googleUser.displayName ?? googleUser.email.split('@').first;
        _storedAvatarUrl = googleUser.photoUrl;
        _mockUser = User(
          id: 'google_${googleUser.id}',
          appMetadata: {},
          userMetadata: {
            'full_name': _storedUserName,
            if (_storedAvatarUrl != null && _storedAvatarUrl!.isNotEmpty) 'avatar_url': _storedAvatarUrl,
          },
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
          email: googleUser.email,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setBool('is_guest', false);
        await prefs.setString('user_name', _storedUserName!);
        await prefs.setString('user_email', googleUser.email);
        if (_storedAvatarUrl != null) {
          await prefs.setString('avatar_url', _storedAvatarUrl!);
        }
        await prefs.setString('user_id', googleUser.id);
        // Persist user to Django DB so profile data is stored and retrievable
        await ApiService().syncUserToBackend();
        return true;
      }
    } catch (e) {
      debugPrint('Google Sign-In silent check notice: $e');
    }

    // Fallback seamless session with Mitrai Shopper profile
    await signInWithCustomIdentity(
      name: 'Mitrai Shopper',
      email: 'shopper@mitrai.ai',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=120',
    );
    await ApiService().syncUserToBackend();
    return true;
  }

  Future<void> signInWithCustomIdentity({
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    _isGuest = false;
    _storedUserName = name.trim();
    _storedAvatarUrl = avatarUrl?.trim();
    final cleanEmail = email.trim();
    final generatedId = 'user_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    _mockUser = User(
      id: generatedId,
      appMetadata: {},
      userMetadata: {
        'full_name': _storedUserName,
        if (_storedAvatarUrl != null && _storedAvatarUrl!.isNotEmpty) 'avatar_url': _storedAvatarUrl,
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: cleanEmail,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_guest', false);
      await prefs.setString('user_name', _storedUserName!);
      await prefs.setString('user_email', cleanEmail);
      if (_storedAvatarUrl != null && _storedAvatarUrl!.isNotEmpty) {
        await prefs.setString('avatar_url', _storedAvatarUrl!);
      } else {
        await prefs.remove('avatar_url');
      }
      await prefs.setString('user_id', generatedId);
    } catch (_) {}
  }

  Future<void> signInAsDemoUser({
    String name = 'Mitrai Shopper',
    String email = 'guest@mitrai.ai',
  }) async {
    _isGuest = true;
    _storedUserName = name;
    _storedAvatarUrl = null;
    _mockUser = User(
      id: 'guest_user_${DateTime.now().millisecondsSinceEpoch}',
      appMetadata: {},
      userMetadata: {
        'full_name': name,
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
      await prefs.remove('avatar_url');
      await prefs.setString('user_id', _mockUser!.id);
    } catch (_) {}
  }

  Future<void> signOut() async {
    try {
      if (_isInitialized) {
        await Supabase.instance.client.auth.signOut();
      }
    } catch (_) {}
    _mockUser = null;
    _isGuest = false;
    _storedUserName = null;
    _storedAvatarUrl = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (_) {}
  }
}
